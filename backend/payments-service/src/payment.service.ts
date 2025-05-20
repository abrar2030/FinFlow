import { PaymentStatus } from '@prisma/client';
import paymentModel from '../models/payment.model';
import stripeService from './stripe.service';
import { sendMessage } from '../config/kafka';
import { 
  Payment, 
  PaymentCreateInput, 
  PaymentUpdateInput, 
  ChargeInput, 
  RefundInput 
} from '../types/payment.types';
import { logger } from '../utils/logger';

class PaymentService {
  // Find payment by ID
  async findById(id: string): Promise<Payment | null> {
    try {
      return await paymentModel.findById(id);
    } catch (error) {
      logger.error(`Error finding payment by ID: ${error}`);
      throw error;
    }
  }

  // Find payments by user ID
  async findByUserId(userId: string): Promise<Payment[]> {
    try {
      return await paymentModel.findByUserId(userId);
    } catch (error) {
      logger.error(`Error finding payments by user ID: ${error}`);
      throw error;
    }
  }

  // Create a payment charge
  async createCharge(chargeInput: ChargeInput): Promise<Payment> {
    try {
      const { userId, amount, currency = 'usd', source, metadata } = chargeInput;
      
      // Create a charge in Stripe
      const stripeCharge = await stripeService.createCharge(
        Math.round(amount * 100), // Convert to cents for Stripe
        currency,
        source,
        metadata
      );
      
      // Create payment record in database
      const paymentData: PaymentCreateInput = {
        userId,
        amount,
        currency,
        status: PaymentStatus.COMPLETED,
        processorId: stripeCharge.id,
        processorData: stripeCharge,
        metadata
      };
      
      const payment = await paymentModel.create(paymentData);
      
      // Publish payment_completed event to Kafka
      await this.publishPaymentCompletedEvent(payment);
      
      return payment;
    } catch (error) {
      logger.error(`Error creating payment charge: ${error}`);
      
      // If Stripe charge failed, create a failed payment record
      if (error.type === 'StripeCardError') {
        const { userId, amount, currency = 'usd', metadata } = chargeInput;
        
        const paymentData: PaymentCreateInput = {
          userId,
          amount,
          currency,
          status: PaymentStatus.FAILED,
          processorData: { error: error.message },
          metadata
        };
        
        const payment = await paymentModel.create(paymentData);
        
        // Publish payment_failed event to Kafka
        await this.publishPaymentFailedEvent(payment, error.message);
        
        return payment;
      }
      
      throw error;
    }
  }

  // Process a refund
  async createRefund(refundInput: RefundInput): Promise<Payment> {
    try {
      const { paymentId, amount, reason } = refundInput;
      
      // Find the payment
      const payment = await this.findById(paymentId);
      if (!payment) {
        const error = new Error('Payment not found');
        error.name = 'NotFoundError';
        throw error;
      }
      
      // Check if payment can be refunded
      if (payment.status !== PaymentStatus.COMPLETED) {
        const error = new Error('Payment cannot be refunded');
        error.name = 'ValidationError';
        throw error;
      }
      
      // Create refund in Stripe
      const stripeRefund = await stripeService.createRefund(
        payment.processorId!,
        amount ? Math.round(amount * 100) : undefined, // Convert to cents for Stripe
        reason
      );
      
      // Update payment record in database
      const paymentData: PaymentUpdateInput = {
        status: PaymentStatus.REFUNDED,
        processorData: {
          ...payment.processorData,
          refund: stripeRefund
        }
      };
      
      const updatedPayment = await paymentModel.update(paymentId, paymentData);
      
      // Publish payment_refunded event to Kafka
      await sendMessage('payment_refunded', {
        id: updatedPayment.id,
        userId: updatedPayment.userId,
        amount: updatedPayment.amount,
        currency: updatedPayment.currency,
        status: updatedPayment.status,
        processorId: updatedPayment.processorId,
        createdAt: updatedPayment.createdAt,
        refundAmount: amount || updatedPayment.amount,
        reason
      });
      
      return updatedPayment;
    } catch (error) {
      logger.error(`Error creating refund: ${error}`);
      throw error;
    }
  }

  // Handle webhook event from Stripe
  async handleWebhookEvent(event: any): Promise<void> {
    try {
      switch (event.type) {
        case 'charge.succeeded':
          await this.handleChargeSucceeded(event.data.object);
          break;
        case 'charge.failed':
          await this.handleChargeFailed(event.data.object);
          break;
        case 'charge.refunded':
          await this.handleChargeRefunded(event.data.object);
          break;
        default:
          logger.info(`Unhandled webhook event type: ${event.type}`);
      }
    } catch (error) {
      logger.error(`Error handling webhook event: ${error}`);
      throw error;
    }
  }

  // Handle charge.succeeded event
  private async handleChargeSucceeded(charge: any): Promise<void> {
    try {
      // Check if payment already exists
      const existingPayment = await paymentModel.findByProcessorId(charge.id);
      if (existingPayment) {
        // Payment already processed
        return;
      }
      
      // Extract user ID from metadata
      const userId = charge.metadata?.userId;
      if (!userId) {
        logger.error('User ID not found in charge metadata');
        return;
      }
      
      // Create payment record
      const paymentData: PaymentCreateInput = {
        userId,
        amount: charge.amount / 100, // Convert from cents
        currency: charge.currency,
        status: PaymentStatus.COMPLETED,
        processorId: charge.id,
        processorData: charge,
        metadata: charge.metadata
      };
      
      const payment = await paymentModel.create(paymentData);
      
      // Publish payment_completed event to Kafka
      await this.publishPaymentCompletedEvent(payment);
    } catch (error) {
      logger.error(`Error handling charge.succeeded event: ${error}`);
      throw error;
    }
  }

  // Handle charge.failed event
  private async handleChargeFailed(charge: any): Promise<void> {
    try {
      // Check if payment already exists
      const existingPayment = await paymentModel.findByProcessorId(charge.id);
      if (existingPayment) {
        // Payment already processed
        return;
      }
      
      // Extract user ID from metadata
      const userId = charge.metadata?.userId;
      if (!userId) {
        logger.error('User ID not found in charge metadata');
        return;
      }
      
      // Create payment record
      const paymentData: PaymentCreateInput = {
        userId,
        amount: charge.amount / 100, // Convert from cents
        currency: charge.currency,
        status: PaymentStatus.FAILED,
        processorId: charge.id,
        processorData: charge,
        metadata: charge.metadata
      };
      
      const payment = await paymentModel.create(paymentData);
      
      // Publish payment_failed event to Kafka
      await this.publishPaymentFailedEvent(payment, charge.failure_message);
    } catch (error) {
      logger.error(`Error handling charge.failed event: ${error}`);
      throw error;
    }
  }

  // Handle charge.refunded event
  private async handleChargeRefunded(charge: any): Promise<void> {
    try {
      // Find the payment by processor ID
      const payment = await paymentModel.findByProcessorId(charge.id);
      if (!payment) {
        logger.error(`Payment not found for charge ID: ${charge.id}`);
        return;
      }
      
      // Update payment record
      const paymentData: PaymentUpdateInput = {
        status: PaymentStatus.REFUNDED,
        processorData: charge
      };
      
      const updatedPayment = await paymentModel.update(payment.id, paymentData);
      
      // Publish payment_refunded event to Kafka
      await sendMessage('payment_refunded', {
        id: updatedPayment.id,
        userId: updatedPayment.userId,
        amount: updatedPayment.amount,
        currency: updatedPayment.currency,
        status: updatedPayment.status,
        processorId: updatedPayment.processorId,
        createdAt: updatedPayment.createdAt,
        refundAmount: charge.amount_refunded / 100 // Convert from cents
      });
    } catch (error) {
      logger.error(`Error handling charge.refunded event: ${error}`);
      throw error;
    }
  }

  // Publish payment_completed event to Kafka
  private async publishPaymentCompletedEvent(payment: Payment): Promise<void> {
    try {
      await sendMessage('payment_completed', {
        id: payment.id,
        userId: payment.userId,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        processorId: payment.processorId,
        createdAt: payment.createdAt
      });
    } catch (error) {
      logger.error(`Error publishing payment_completed event: ${error}`);
      // Don't throw error, just log it
    }
  }

  // Publish payment_failed event to Kafka
  private async publishPaymentFailedEvent(payment: Payment, reason: string): Promise<void> {
    try {
      await sendMessage('payment_failed', {
        id: payment.id,
        userId: payment.userId,
        amount: payment.amount,
        currency: payment.currency,
        reason,
        createdAt: payment.createdAt
      });
    } catch (error) {
      logger.error(`Error publishing payment_failed event: ${error}`);
      // Don't throw error, just log it
    }
  }
}

export default new PaymentService();
