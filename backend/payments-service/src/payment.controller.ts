import { Request, Response, NextFunction } from "express";
import { validationResult } from "express-validator";
import { v4 as uuidv4 } from "uuid";
import paymentService from "./payment.service";
import { ChargeInput, RefundInput } from "./payment.types";
import stripeService from "./stripe.service";
import { withRetry } from "./utils/retry.util";
import { logger } from "./utils/logger";

// Store processed request IDs to ensure idempotency
const processedRequestIds = new Set<string>();
// TTL for processed request IDs (in milliseconds) - 24 hours
const REQUEST_ID_TTL = 24 * 60 * 60 * 1000;

class PaymentController {
  /**
   * Validate request data and handle validation errors
   * @param req Express request
   * @param res Express response
   * @returns boolean indicating if validation passed
   */
  private validateRequest(req: Request, res: Response): boolean {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      logger.warn(`Validation error in ${req.path}:`, {
        errors: errors.array(),
      });
      res.status(400).json({
        message: "Validation error",
        errors: errors.array(),
      });
      return false;
    }
    return true;
  }

  /**
   * Ensure idempotency by checking request ID
   * @param requestId Request ID to check
   * @returns boolean indicating if request is new
   */
  private ensureIdempotency(requestId: string): boolean {
    if (processedRequestIds.has(requestId)) {
      return false;
    }

    // Add request ID to processed set with TTL
    processedRequestIds.add(requestId);
    setTimeout(() => {
      processedRequestIds.delete(requestId);
    }, REQUEST_ID_TTL);

    return true;
  }

  /**
   * Create a payment charge
   */
  async createCharge(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    const requestId = (req.headers["x-request-id"] as string) || uuidv4();

    try {
      logger.info(`Processing payment charge request`, { requestId });

      // Validate request data
      if (!this.validateRequest(req, res)) {
        return;
      }

      // Check idempotency
      if (!this.ensureIdempotency(requestId)) {
        logger.info(`Duplicate request detected`, { requestId });
        const existingPayment = await paymentService.findByRequestId(requestId);
        if (existingPayment) {
          res.status(200).json(existingPayment);
        } else {
          res.status(409).json({
            message: "Duplicate request detected, but payment not found",
            requestId,
          });
        }
        return;
      }

      const { amount, currency, source, metadata } = req.body;
      const userId = req.user.sub; // Get user ID from JWT token

      // Validate amount and currency
      if (!amount || amount <= 0) {
        logger.warn(`Invalid payment amount`, { amount, requestId });
        res.status(400).json({ message: "Invalid payment amount" });
        return;
      }

      if (currency && !/^[A-Z]{3}$/.test(currency.toUpperCase())) {
        logger.warn(`Invalid currency code`, { currency, requestId });
        res.status(400).json({ message: "Invalid currency code" });
        return;
      }

      // Create charge input
      const chargeInput: ChargeInput = {
        userId,
        amount,
        currency: currency?.toLowerCase() || "usd",
        source,
        metadata: {
          ...metadata,
          requestId, // Store requestId in metadata for idempotency
        },
      };

      // Create payment charge with retry logic for transient failures
      const payment = await withRetry(
        () => paymentService.createCharge(chargeInput),
        {
          maxRetries: 3,
          initialDelayMs: 300,
          maxDelayMs: 3000,
          backoffFactor: 2,
          retryableErrors: [
            "NETWORK_ERROR",
            "GATEWAY_ERROR",
            "RATE_LIMIT_ERROR",
            "TIMEOUT_ERROR",
            "CONNECTION_ERROR",
            "SERVER_ERROR",
          ],
        },
      );

      logger.info(`Payment charge created successfully`, {
        paymentId: payment.id,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        requestId,
      });

      res.status(201).json(payment);
    } catch (error) {
      logger.error(`Error creating payment charge`, {
        error: error.message,
        stack: error.stack,
        requestId,
      });
      next(error);
    }
  }

  /**
   * Get payment by ID
   */
  async getPaymentById(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    const requestId = (req.headers["x-request-id"] as string) || uuidv4();

    try {
      // Validate request data
      if (!this.validateRequest(req, res)) {
        return;
      }

      const { id } = req.params;
      const userId = req.user.sub; // Get user ID from JWT token

      logger.info(`Retrieving payment by ID`, { paymentId: id, requestId });

      // Get payment by ID
      const payment = await paymentService.findById(id);

      if (!payment) {
        logger.warn(`Payment not found`, { paymentId: id, requestId });
        res.status(404).json({ message: "Payment not found" });
        return;
      }

      // Check if user owns the payment
      if (payment.userId !== userId) {
        logger.warn(`Unauthorized payment access attempt`, {
          paymentId: id,
          requestedBy: userId,
          paymentOwner: payment.userId,
          requestId,
        });
        res
          .status(403)
          .json({
            message: "Forbidden: You do not have access to this payment",
          });
        return;
      }

      logger.info(`Payment retrieved successfully`, {
        paymentId: id,
        requestId,
      });
      res.status(200).json(payment);
    } catch (error) {
      logger.error(`Error retrieving payment by ID`, {
        error: error.message,
        stack: error.stack,
        paymentId: req.params.id,
        requestId,
      });
      next(error);
    }
  }

  /**
   * Get payments by user ID
   */
  async getPaymentsByUserId(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    const requestId = (req.headers["x-request-id"] as string) || uuidv4();

    try {
      const userId = req.user.sub; // Get user ID from JWT token

      logger.info(`Retrieving payments for user`, { userId, requestId });

      // Get payments by user ID
      const payments = await paymentService.findByUserId(userId);

      logger.info(`Retrieved ${payments.length} payments for user`, {
        userId,
        count: payments.length,
        requestId,
      });

      res.status(200).json(payments);
    } catch (error) {
      logger.error(`Error retrieving payments for user`, {
        error: error.message,
        stack: error.stack,
        userId: req.user.sub,
        requestId,
      });
      next(error);
    }
  }

  /**
   * Create a refund
   */
  async createRefund(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    const requestId = (req.headers["x-request-id"] as string) || uuidv4();

    try {
      logger.info(`Processing refund request`, { requestId });

      // Validate request data
      if (!this.validateRequest(req, res)) {
        return;
      }

      // Check idempotency
      if (!this.ensureIdempotency(requestId)) {
        logger.info(`Duplicate refund request detected`, { requestId });
        const existingRefund =
          await paymentService.findRefundByRequestId(requestId);
        if (existingRefund) {
          res.status(200).json(existingRefund);
        } else {
          res.status(409).json({
            message: "Duplicate refund request detected, but refund not found",
            requestId,
          });
        }
        return;
      }

      const { paymentId, amount, reason } = req.body;
      const userId = req.user.sub; // Get user ID from JWT token

      // Validate amount if provided
      if (amount !== undefined && amount <= 0) {
        logger.warn(`Invalid refund amount`, { amount, requestId });
        res.status(400).json({ message: "Invalid refund amount" });
        return;
      }

      // Get payment by ID
      const payment = await paymentService.findById(paymentId);

      if (!payment) {
        logger.warn(`Payment not found for refund`, { paymentId, requestId });
        res.status(404).json({ message: "Payment not found" });
        return;
      }

      // Check if user owns the payment
      if (payment.userId !== userId) {
        logger.warn(`Unauthorized refund attempt`, {
          paymentId,
          requestedBy: userId,
          paymentOwner: payment.userId,
          requestId,
        });
        res
          .status(403)
          .json({
            message: "Forbidden: You do not have access to this payment",
          });
        return;
      }

      // Create refund input
      const refundInput: RefundInput = {
        paymentId,
        amount,
        reason,
        metadata: {
          requestId, // Store requestId in metadata for idempotency
        },
      };

      // Create refund with retry logic for transient failures
      const refundedPayment = await withRetry(
        () => paymentService.createRefund(refundInput),
        {
          maxRetries: 3,
          initialDelayMs: 300,
          maxDelayMs: 3000,
          backoffFactor: 2,
        },
      );

      logger.info(`Refund processed successfully`, {
        paymentId,
        refundAmount: amount || payment.amount,
        reason,
        requestId,
      });

      res.status(200).json(refundedPayment);
    } catch (error) {
      logger.error(`Error processing refund`, {
        error: error.message,
        stack: error.stack,
        paymentId: req.body.paymentId,
        requestId,
      });
      next(error);
    }
  }

  /**
   * Handle webhook from payment processor
   */
  async handleWebhook(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    const requestId = (req.headers["x-request-id"] as string) || uuidv4();
    const signature = req.headers["stripe-signature"] as string;

    try {
      logger.info(`Processing webhook event`, {
        processor: "stripe",
        signature: signature ? "present" : "missing",
        requestId,
      });

      if (!signature) {
        logger.warn(`Missing stripe-signature header`, { requestId });
        res.status(400).json({ message: "Missing stripe-signature header" });
        return;
      }

      // Generate idempotency key from signature
      const idempotencyKey = `webhook_${signature}`;

      // Check idempotency
      if (!this.ensureIdempotency(idempotencyKey)) {
        logger.info(`Duplicate webhook event detected`, { idempotencyKey });
        res.status(200).json({ received: true, duplicate: true });
        return;
      }

      // Verify webhook signature with retry for transient failures
      const event = await withRetry(
        () => stripeService.verifyWebhookSignature(req.body, signature),
        {
          maxRetries: 2,
          initialDelayMs: 100,
          maxDelayMs: 1000,
        },
      );

      logger.info(`Webhook signature verified`, {
        eventType: event.type,
        eventId: event.id,
        requestId,
      });

      // Handle webhook event with retry for transient failures
      await withRetry(
        () =>
          paymentService.handleWebhookEvent(
            "stripe",
            event,
            signature,
            req.body,
          ),
        {
          maxRetries: 3,
          initialDelayMs: 300,
          maxDelayMs: 3000,
        },
      );

      logger.info(`Webhook event processed successfully`, {
        eventType: event.type,
        eventId: event.id,
        requestId,
      });

      res.status(200).json({ received: true });
    } catch (error) {
      logger.error(`Webhook error`, {
        error: error.message,
        stack: error.stack,
        requestId,
      });

      // Don't pass to error middleware, just return 400
      res.status(400).json({ message: "Webhook error: " + error.message });
    }
  }
}

export default new PaymentController();
