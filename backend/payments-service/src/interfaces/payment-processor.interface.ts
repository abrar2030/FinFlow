/**
 * Payment Processor Interface
 *
 * This interface defines the contract that all payment processors must implement.
 * It provides a consistent API for interacting with different payment gateways.
 */

export interface PaymentProcessorInterface {
  /**
   * Get the name of the payment processor
   */
  getName(): string;

  /**
   * Create a payment intent/authorization
   *
   * @param amount - The amount to charge in the smallest currency unit (e.g., cents for USD)
   * @param currency - The currency code (e.g., 'usd', 'eur')
   * @param metadata - Additional metadata to associate with the payment
   */
  createPaymentIntent(
    amount: number,
    currency: string,
    metadata?: Record<string, any>,
  ): Promise<any>;

  /**
   * Create a charge/capture payment
   *
   * @param amount - The amount to charge in the smallest currency unit
   * @param currency - The currency code
   * @param source - The payment source identifier (e.g., token, payment method ID)
   * @param metadata - Additional metadata to associate with the payment
   */
  createCharge(
    amount: number,
    currency: string,
    source: string,
    metadata?: Record<string, any>,
  ): Promise<any>;

  /**
   * Retrieve information about a charge
   *
   * @param chargeId - The ID of the charge to retrieve
   */
  retrieveCharge(chargeId: string): Promise<any>;

  /**
   * Create a refund for a charge
   *
   * @param chargeId - The ID of the charge to refund
   * @param amount - The amount to refund (optional, defaults to full amount)
   * @param reason - The reason for the refund (optional)
   */
  createRefund(
    chargeId: string,
    amount?: number,
    reason?: string,
  ): Promise<any>;

  /**
   * Verify a webhook signature
   *
   * @param payload - The webhook payload
   * @param signature - The signature header
   */
  verifyWebhookSignature(payload: string | Buffer, signature: string): any;

  /**
   * Process a webhook event
   *
   * @param event - The webhook event object
   */
  processWebhookEvent(event: any): Promise<void>;

  /**
   * Get client-side configuration for the payment processor
   * Returns configuration needed for the frontend to initialize the payment processor
   */
  getClientConfig(): Record<string, any>;
}
