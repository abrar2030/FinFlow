import { PaymentStatus } from "@prisma/client";
import paymentModel from "./models/payment.model";
import { sendMessage } from "../config/kafka";
import {
  Payment,
  PaymentCreateInput,
  PaymentUpdateInput,
  ChargeInput,
  RefundInput,
  ProcessorType,
} from "./payment.types";
import { logger } from "../utils/logger";
import paymentProcessorFactory from "../factories/payment-processor.factory";

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

  // Get available payment processors
  getAvailableProcessors(): string[] {
    return paymentProcessorFactory
      .getAllProcessors()
      .map((processor) => processor.getName());
  }

  // Get client configurations for all processors
  getProcessorConfigs(): Record<string, Record<string, any>> {
    return paymentProcessorFactory.getAllClientConfigs();
  }

  // Create a payment charge
  async createCharge(chargeInput: ChargeInput): Promise<Payment> {
    try {
      const {
        userId,
        amount,
        currency = "usd",
        source,
        metadata,
        processorType = ProcessorType.STRIPE, // Default to Stripe if not specified
      } = chargeInput;

      // Get the appropriate payment processor
      const processor = paymentProcessorFactory.getProcessor(processorType);

      // Create a charge using the selected processor
      const processorCharge = await processor.createCharge(
        Math.round(amount * 100), // Convert to cents for processors
        currency,
        source,
        metadata,
      );

      // Create payment record in database
      const paymentData: PaymentCreateInput = {
        userId,
        amount,
        currency,
        status: PaymentStatus.COMPLETED,
        processorId:
          processorCharge.id ||
          processorCharge.payment?.id ||
          processorCharge.order_id,
        processorType,
        processorData: processorCharge,
        metadata,
      };

      const payment = await paymentModel.create(paymentData);

      // Publish payment_completed event to Kafka
      await this.publishPaymentCompletedEvent(payment);

      return payment;
    } catch (error) {
      logger.error(`Error creating payment charge: ${error}`);

      // If charge failed, create a failed payment record
      const {
        userId,
        amount,
        currency = "usd",
        metadata,
        processorType = ProcessorType.STRIPE,
      } = chargeInput;

      const paymentData: PaymentCreateInput = {
        userId,
        amount,
        currency,
        status: PaymentStatus.FAILED,
        processorType,
        processorData: { error: error.message },
        metadata,
      };

      const payment = await paymentModel.create(paymentData);

      // Publish payment_failed event to Kafka
      await this.publishPaymentFailedEvent(payment, error.message);

      return payment;
    }
  }

  // Create a payment intent (for client-side processing)
  async createPaymentIntent(chargeInput: ChargeInput): Promise<any> {
    try {
      const {
        userId,
        amount,
        currency = "usd",
        metadata,
        processorType = ProcessorType.STRIPE, // Default to Stripe if not specified
      } = chargeInput;

      // Get the appropriate payment processor
      const processor = paymentProcessorFactory.getProcessor(processorType);

      // Create a payment intent using the selected processor
      const paymentIntent = await processor.createPaymentIntent(
        Math.round(amount * 100), // Convert to cents for processors
        currency,
        { ...metadata, userId }, // Include userId in metadata
      );

      return {
        processorType,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount,
        currency,
      };
    } catch (error) {
      logger.error(`Error creating payment intent: ${error}`);
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
        const error = new Error("Payment not found");
        error.name = "NotFoundError";
        throw error;
      }

      // Check if payment can be refunded
      if (payment.status !== PaymentStatus.COMPLETED) {
        const error = new Error("Payment cannot be refunded");
        error.name = "ValidationError";
        throw error;
      }

      // Get the processor used for this payment
      const processor = paymentProcessorFactory.getProcessor(
        payment.processorType,
      );

      // Create refund using the appropriate processor
      const processorRefund = await processor.createRefund(
        payment.processorId!,
        amount ? Math.round(amount * 100) : undefined, // Convert to cents for processors
        reason,
      );

      // Update payment record in database
      const paymentData: PaymentUpdateInput = {
        status: PaymentStatus.REFUNDED,
        processorData: {
          ...payment.processorData,
          refund: processorRefund,
        },
      };

      const updatedPayment = await paymentModel.update(paymentId, paymentData);

      // Publish payment_refunded event to Kafka
      await sendMessage("payment_refunded", {
        id: updatedPayment.id,
        userId: updatedPayment.userId,
        amount: updatedPayment.amount,
        currency: updatedPayment.currency,
        status: updatedPayment.status,
        processorId: updatedPayment.processorId,
        processorType: updatedPayment.processorType,
        createdAt: updatedPayment.createdAt,
        refundAmount: amount || updatedPayment.amount,
        reason,
      });

      return updatedPayment;
    } catch (error) {
      logger.error(`Error creating refund: ${error}`);
      throw error;
    }
  }

  // Handle webhook event from payment processor
  async handleWebhookEvent(
    processorType: string,
    event: any,
    signature: string,
    payload: string | Buffer,
  ): Promise<void> {
    try {
      // Get the appropriate processor
      const processor = paymentProcessorFactory.getProcessor(processorType);

      // Verify webhook signature
      const verifiedEvent = processor.verifyWebhookSignature(
        payload,
        signature,
      );

      // Process the event based on processor type
      switch (processorType) {
        case ProcessorType.STRIPE:
          await this.handleStripeWebhookEvent(verifiedEvent);
          break;
        case ProcessorType.PAYPAL:
          await this.handlePayPalWebhookEvent(verifiedEvent);
          break;
        case ProcessorType.SQUARE:
          await this.handleSquareWebhookEvent(verifiedEvent);
          break;
        default:
          logger.info(`Unhandled processor type for webhook: ${processorType}`);
      }
    } catch (error) {
      logger.error(`Error handling webhook event: ${error}`);
      throw error;
    }
  }

  // Handle Stripe webhook events
  private async handleStripeWebhookEvent(event: any): Promise<void> {
    try {
      switch (event.type) {
        case "charge.succeeded":
          await this.handleStripeChargeSucceeded(event.data.object);
          break;
        case "charge.failed":
          await this.handleStripeChargeFailed(event.data.object);
          break;
        case "charge.refunded":
          await this.handleStripeChargeRefunded(event.data.object);
          break;
        default:
          logger.info(`Unhandled Stripe webhook event type: ${event.type}`);
      }
    } catch (error) {
      logger.error(`Error handling Stripe webhook event: ${error}`);
      throw error;
    }
  }

  // Handle PayPal webhook events
  private async handlePayPalWebhookEvent(event: any): Promise<void> {
    try {
      switch (event.event_type) {
        case "PAYMENT.CAPTURE.COMPLETED":
          await this.handlePayPalPaymentCompleted(event.resource);
          break;
        case "PAYMENT.CAPTURE.DENIED":
          await this.handlePayPalPaymentDenied(event.resource);
          break;
        case "PAYMENT.CAPTURE.REFUNDED":
          await this.handlePayPalPaymentRefunded(event.resource);
          break;
        default:
          logger.info(
            `Unhandled PayPal webhook event type: ${event.event_type}`,
          );
      }
    } catch (error) {
      logger.error(`Error handling PayPal webhook event: ${error}`);
      throw error;
    }
  }

  // Handle Square webhook events
  private async handleSquareWebhookEvent(event: any): Promise<void> {
    try {
      switch (event.type) {
        case "payment.created":
          await this.handleSquarePaymentCreated(event.data.object.payment);
          break;
        case "payment.updated":
          await this.handleSquarePaymentUpdated(event.data.object.payment);
          break;
        case "refund.created":
          await this.handleSquareRefundCreated(event.data.object.refund);
          break;
        default:
          logger.info(`Unhandled Square webhook event type: ${event.type}`);
      }
    } catch (error) {
      logger.error(`Error handling Square webhook event: ${error}`);
      throw error;
    }
  }

  // Handle Stripe charge.succeeded event
  private async handleStripeChargeSucceeded(charge: any): Promise<void> {
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
        logger.error("User ID not found in charge metadata");
        return;
      }

      // Create payment record
      const paymentData: PaymentCreateInput = {
        userId,
        amount: charge.amount / 100, // Convert from cents
        currency: charge.currency,
        status: PaymentStatus.COMPLETED,
        processorId: charge.id,
        processorType: ProcessorType.STRIPE,
        processorData: charge,
        metadata: charge.metadata,
      };

      const payment = await paymentModel.create(paymentData);

      // Publish payment_completed event to Kafka
      await this.publishPaymentCompletedEvent(payment);
    } catch (error) {
      logger.error(`Error handling Stripe charge.succeeded event: ${error}`);
      throw error;
    }
  }

  // Handle Stripe charge.failed event
  private async handleStripeChargeFailed(charge: any): Promise<void> {
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
        logger.error("User ID not found in charge metadata");
        return;
      }

      // Create payment record
      const paymentData: PaymentCreateInput = {
        userId,
        amount: charge.amount / 100, // Convert from cents
        currency: charge.currency,
        status: PaymentStatus.FAILED,
        processorId: charge.id,
        processorType: ProcessorType.STRIPE,
        processorData: charge,
        metadata: charge.metadata,
      };

      const payment = await paymentModel.create(paymentData);

      // Publish payment_failed event to Kafka
      await this.publishPaymentFailedEvent(payment, charge.failure_message);
    } catch (error) {
      logger.error(`Error handling Stripe charge.failed event: ${error}`);
      throw error;
    }
  }

  // Handle Stripe charge.refunded event
  private async handleStripeChargeRefunded(charge: any): Promise<void> {
    try {
      // Find the payment by processor ID
      const payment = await paymentModel.findByProcessorId(charge.id);
      if (!payment) {
        logger.error(`Payment not found for Stripe charge ID: ${charge.id}`);
        return;
      }

      // Update payment record
      const paymentData: PaymentUpdateInput = {
        status: PaymentStatus.REFUNDED,
        processorData: charge,
      };

      const updatedPayment = await paymentModel.update(payment.id, paymentData);

      // Publish payment_refunded event to Kafka
      await sendMessage("payment_refunded", {
        id: updatedPayment.id,
        userId: updatedPayment.userId,
        amount: updatedPayment.amount,
        currency: updatedPayment.currency,
        status: updatedPayment.status,
        processorId: updatedPayment.processorId,
        processorType: updatedPayment.processorType,
        createdAt: updatedPayment.createdAt,
        refundAmount: charge.amount_refunded / 100, // Convert from cents
      });
    } catch (error) {
      logger.error(`Error handling Stripe charge.refunded event: ${error}`);
      throw error;
    }
  }

  // Handle PayPal payment completed event
  private async handlePayPalPaymentCompleted(resource: any): Promise<void> {
    try {
      // Check if payment already exists
      const existingPayment = await paymentModel.findByProcessorId(resource.id);
      if (existingPayment) {
        // Payment already processed
        return;
      }

      // Extract user ID from custom ID (stored during payment creation)
      const customId = resource.custom_id || "";
      const userId = customId.split("_")[0]; // Assuming format: "userId_otherInfo"

      if (!userId) {
        logger.error("User ID not found in PayPal payment custom ID");
        return;
      }

      // Create payment record
      const paymentData: PaymentCreateInput = {
        userId,
        amount: parseFloat(resource.amount.value), // PayPal uses decimal amounts
        currency: resource.amount.currency_code.toLowerCase(),
        status: PaymentStatus.COMPLETED,
        processorId: resource.id,
        processorType: ProcessorType.PAYPAL,
        processorData: resource,
        metadata: { customId },
      };

      const payment = await paymentModel.create(paymentData);

      // Publish payment_completed event to Kafka
      await this.publishPaymentCompletedEvent(payment);
    } catch (error) {
      logger.error(`Error handling PayPal payment completed event: ${error}`);
      throw error;
    }
  }

  // Handle PayPal payment denied event
  private async handlePayPalPaymentDenied(resource: any): Promise<void> {
    try {
      // Check if payment already exists
      const existingPayment = await paymentModel.findByProcessorId(resource.id);
      if (existingPayment) {
        // Payment already processed
        return;
      }

      // Extract user ID from custom ID (stored during payment creation)
      const customId = resource.custom_id || "";
      const userId = customId.split("_")[0]; // Assuming format: "userId_otherInfo"

      if (!userId) {
        logger.error("User ID not found in PayPal payment custom ID");
        return;
      }

      // Create payment record
      const paymentData: PaymentCreateInput = {
        userId,
        amount: parseFloat(resource.amount.value), // PayPal uses decimal amounts
        currency: resource.amount.currency_code.toLowerCase(),
        status: PaymentStatus.FAILED,
        processorId: resource.id,
        processorType: ProcessorType.PAYPAL,
        processorData: resource,
        metadata: { customId },
      };

      const payment = await paymentModel.create(paymentData);

      // Publish payment_failed event to Kafka
      await this.publishPaymentFailedEvent(
        payment,
        resource.status_details?.reason || "Payment denied",
      );
    } catch (error) {
      logger.error(`Error handling PayPal payment denied event: ${error}`);
      throw error;
    }
  }

  // Handle PayPal payment refunded event
  private async handlePayPalPaymentRefunded(resource: any): Promise<void> {
    try {
      // Find the payment by processor ID
      const payment = await paymentModel.findByProcessorId(resource.id);
      if (!payment) {
        logger.error(`Payment not found for PayPal payment ID: ${resource.id}`);
        return;
      }

      // Update payment record
      const paymentData: PaymentUpdateInput = {
        status: PaymentStatus.REFUNDED,
        processorData: resource,
      };

      const updatedPayment = await paymentModel.update(payment.id, paymentData);

      // Publish payment_refunded event to Kafka
      await sendMessage("payment_refunded", {
        id: updatedPayment.id,
        userId: updatedPayment.userId,
        amount: updatedPayment.amount,
        currency: updatedPayment.currency,
        status: updatedPayment.status,
        processorId: updatedPayment.processorId,
        processorType: updatedPayment.processorType,
        createdAt: updatedPayment.createdAt,
        refundAmount: parseFloat(resource.amount.value), // PayPal uses decimal amounts
      });
    } catch (error) {
      logger.error(`Error handling PayPal payment refunded event: ${error}`);
      throw error;
    }
  }

  // Handle Square payment created event
  private async handleSquarePaymentCreated(payment: any): Promise<void> {
    try {
      // Check if payment already exists
      const existingPayment = await paymentModel.findByProcessorId(payment.id);
      if (existingPayment) {
        // Payment already processed
        return;
      }

      // Extract user ID from reference ID (stored during payment creation)
      const referenceId = payment.reference_id || "";
      const userId = referenceId.split("_")[0]; // Assuming format: "userId_otherInfo"

      if (!userId) {
        logger.error("User ID not found in Square payment reference ID");
        return;
      }

      // Create payment record
      const paymentData: PaymentCreateInput = {
        userId,
        amount: payment.amount_money.amount / 100, // Convert from cents
        currency: payment.amount_money.currency.toLowerCase(),
        status:
          payment.status === "COMPLETED"
            ? PaymentStatus.COMPLETED
            : PaymentStatus.PENDING,
        processorId: payment.id,
        processorType: ProcessorType.SQUARE,
        processorData: payment,
        metadata: { referenceId },
      };

      const paymentRecord = await paymentModel.create(paymentData);

      // Publish payment_completed event to Kafka if payment is completed
      if (payment.status === "COMPLETED") {
        await this.publishPaymentCompletedEvent(paymentRecord);
      }
    } catch (error) {
      logger.error(`Error handling Square payment created event: ${error}`);
      throw error;
    }
  }

  // Handle Square payment updated event
  private async handleSquarePaymentUpdated(payment: any): Promise<void> {
    try {
      // Find the payment by processor ID
      const existingPayment = await paymentModel.findByProcessorId(payment.id);
      if (!existingPayment) {
        logger.error(`Payment not found for Square payment ID: ${payment.id}`);
        return;
      }

      // Determine the new status
      let status = existingPayment.status;
      if (payment.status === "COMPLETED") {
        status = PaymentStatus.COMPLETED;
      } else if (payment.status === "FAILED") {
        status = PaymentStatus.FAILED;
      }

      // Update payment record
      const paymentData: PaymentUpdateInput = {
        status,
        processorData: payment,
      };

      const updatedPayment = await paymentModel.update(
        existingPayment.id,
        paymentData,
      );

      // Publish appropriate event to Kafka based on status
      if (
        status === PaymentStatus.COMPLETED &&
        existingPayment.status !== PaymentStatus.COMPLETED
      ) {
        await this.publishPaymentCompletedEvent(updatedPayment);
      } else if (
        status === PaymentStatus.FAILED &&
        existingPayment.status !== PaymentStatus.FAILED
      ) {
        await this.publishPaymentFailedEvent(updatedPayment, "Payment failed");
      }
    } catch (error) {
      logger.error(`Error handling Square payment updated event: ${error}`);
      throw error;
    }
  }

  // Handle Square refund created event
  private async handleSquareRefundCreated(refund: any): Promise<void> {
    try {
      // Find the payment by processor ID
      const payment = await paymentModel.findByProcessorId(refund.payment_id);
      if (!payment) {
        logger.error(
          `Payment not found for Square payment ID: ${refund.payment_id}`,
        );
        return;
      }

      // Update payment record
      const paymentData: PaymentUpdateInput = {
        status: PaymentStatus.REFUNDED,
        processorData: {
          ...payment.processorData,
          refund,
        },
      };

      const updatedPayment = await paymentModel.update(payment.id, paymentData);

      // Publish payment_refunded event to Kafka
      await sendMessage("payment_refunded", {
        id: updatedPayment.id,
        userId: updatedPayment.userId,
        amount: updatedPayment.amount,
        currency: updatedPayment.currency,
        status: updatedPayment.status,
        processorId: updatedPayment.processorId,
        processorType: updatedPayment.processorType,
        createdAt: updatedPayment.createdAt,
        refundAmount: refund.amount_money.amount / 100, // Convert from cents
      });
    } catch (error) {
      logger.error(`Error handling Square refund created event: ${error}`);
      throw error;
    }
  }

  // Publish payment_completed event to Kafka
  private async publishPaymentCompletedEvent(payment: Payment): Promise<void> {
    try {
      await sendMessage("payment_completed", {
        id: payment.id,
        userId: payment.userId,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        processorId: payment.processorId,
        processorType: payment.processorType,
        createdAt: payment.createdAt,
      });
    } catch (error) {
      logger.error(`Error publishing payment_completed event: ${error}`);
      // Don't throw error, just log it
    }
  }

  // Publish payment_failed event to Kafka
  private async publishPaymentFailedEvent(
    payment: Payment,
    reason: string,
  ): Promise<void> {
    try {
      await sendMessage("payment_failed", {
        id: payment.id,
        userId: payment.userId,
        amount: payment.amount,
        currency: payment.currency,
        processorType: payment.processorType,
        reason,
        createdAt: payment.createdAt,
      });
    } catch (error) {
      logger.error(`Error publishing payment_failed event: ${error}`);
      // Don't throw error, just log it
    }
  }
}

export default new PaymentService();
