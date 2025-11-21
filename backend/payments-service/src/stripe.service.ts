import dotenv from "dotenv";
import Stripe from "stripe";

// Load environment variables
dotenv.config();

// Initialize Stripe client
const stripeClient = new Stripe(process.env.STRIPE_SECRET || "", {
  apiVersion:
    (process.env.STRIPE_API_VERSION as Stripe.LatestApiVersion) || "2023-10-16",
});

// Create a payment intent
export const createPaymentIntent = async (
  amount: number,
  currency: string = "usd",
  metadata: any = {},
): Promise<Stripe.PaymentIntent> => {
  return stripeClient.paymentIntents.create({
    amount,
    currency,
    metadata,
  });
};

// Create a charge
export const createCharge = async (
  amount: number,
  currency: string = "usd",
  source: string,
  metadata: any = {},
): Promise<Stripe.Charge> => {
  return stripeClient.charges.create({
    amount,
    currency,
    source,
    metadata,
  });
};

// Retrieve a charge
export const retrieveCharge = async (
  chargeId: string,
): Promise<Stripe.Charge> => {
  return stripeClient.charges.retrieve(chargeId);
};

// Create a refund
export const createRefund = async (
  chargeId: string,
  amount?: number,
  reason?: string,
): Promise<Stripe.Refund> => {
  const refundParams: Stripe.RefundCreateParams = {
    charge: chargeId,
  };

  if (amount) {
    refundParams.amount = amount;
  }

  if (reason) {
    refundParams.reason = reason as Stripe.RefundCreateParams.Reason;
  }

  return stripeClient.refunds.create(refundParams);
};

// Verify webhook signature
export const verifyWebhookSignature = (
  payload: string | Buffer,
  signature: string,
): Stripe.Event => {
  return stripeClient.webhooks.constructEvent(
    payload,
    signature,
    process.env.STRIPE_WEBHOOK_SECRET || "",
  );
};

export default {
  stripeClient,
  createPaymentIntent,
  createCharge,
  retrieveCharge,
  createRefund,
  verifyWebhookSignature,
};
