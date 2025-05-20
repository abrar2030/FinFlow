import { Request, Response, NextFunction } from 'express';
import paymentService from '../services/payment.service';
import { ChargeInput, RefundInput } from '../types/payment.types';
import stripeService from '../services/stripe.service';

class PaymentController {
  // Create a payment charge
  async createCharge(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { amount, currency, source, metadata } = req.body;
      const userId = req.user.sub; // Get user ID from JWT token
      
      // Create charge input
      const chargeInput: ChargeInput = {
        userId,
        amount,
        currency,
        source,
        metadata
      };
      
      // Create payment charge
      const payment = await paymentService.createCharge(chargeInput);
      
      res.status(201).json(payment);
    } catch (error) {
      next(error);
    }
  }

  // Get payment by ID
  async getPaymentById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user.sub; // Get user ID from JWT token
      
      // Get payment by ID
      const payment = await paymentService.findById(id);
      
      if (!payment) {
        res.status(404).json({ message: 'Payment not found' });
        return;
      }
      
      // Check if user owns the payment
      if (payment.userId !== userId) {
        res.status(403).json({ message: 'Forbidden: You do not have access to this payment' });
        return;
      }
      
      res.status(200).json(payment);
    } catch (error) {
      next(error);
    }
  }

  // Get payments by user ID
  async getPaymentsByUserId(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user.sub; // Get user ID from JWT token
      
      // Get payments by user ID
      const payments = await paymentService.findByUserId(userId);
      
      res.status(200).json(payments);
    } catch (error) {
      next(error);
    }
  }

  // Create a refund
  async createRefund(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { paymentId, amount, reason } = req.body;
      const userId = req.user.sub; // Get user ID from JWT token
      
      // Get payment by ID
      const payment = await paymentService.findById(paymentId);
      
      if (!payment) {
        res.status(404).json({ message: 'Payment not found' });
        return;
      }
      
      // Check if user owns the payment
      if (payment.userId !== userId) {
        res.status(403).json({ message: 'Forbidden: You do not have access to this payment' });
        return;
      }
      
      // Create refund input
      const refundInput: RefundInput = {
        paymentId,
        amount,
        reason
      };
      
      // Create refund
      const refundedPayment = await paymentService.createRefund(refundInput);
      
      res.status(200).json(refundedPayment);
    } catch (error) {
      next(error);
    }
  }

  // Handle webhook from Stripe
  async handleWebhook(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const signature = req.headers['stripe-signature'] as string;
      
      if (!signature) {
        res.status(400).json({ message: 'Missing stripe-signature header' });
        return;
      }
      
      // Verify webhook signature
      const event = stripeService.verifyWebhookSignature(req.body, signature);
      
      // Handle webhook event
      await paymentService.handleWebhookEvent(event);
      
      res.status(200).json({ received: true });
    } catch (error) {
      // Don't pass to error middleware, just return 400
      res.status(400).json({ message: 'Webhook error: ' + error.message });
    }
  }
}

export default new PaymentController();
