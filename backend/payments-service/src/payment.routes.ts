import express from 'express';
import paymentController from '../controllers/payment.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validation.middleware';
import { 
  chargeValidation, 
  paymentIdValidation, 
  refundValidation 
} from '../validators/payment.validator';

const router = express.Router();

// Create a payment charge
router.post(
  '/charge',
  authenticate,
  validate(chargeValidation),
  paymentController.createCharge.bind(paymentController)
);

// Get payment by ID
router.get(
  '/:id',
  authenticate,
  validate(paymentIdValidation),
  paymentController.getPaymentById.bind(paymentController)
);

// Get payments by user ID
router.get(
  '/',
  authenticate,
  paymentController.getPaymentsByUserId.bind(paymentController)
);

// Create a refund
router.post(
  '/refund',
  authenticate,
  validate(refundValidation),
  paymentController.createRefund.bind(paymentController)
);

// Handle webhook from Stripe
router.post(
  '/webhook',
  express.raw({ type: 'application/json' }),
  paymentController.handleWebhook.bind(paymentController)
);

export default router;
