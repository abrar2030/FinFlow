import express from 'express';
import invoiceController from '../controllers/invoice.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validation.middleware';
import { 
  createInvoiceValidation, 
  invoiceIdValidation, 
  updateInvoiceValidation 
} from '../validators/invoice.validator';

const router = express.Router();

// Create a new invoice
router.post(
  '/',
  authenticate,
  validate(createInvoiceValidation),
  invoiceController.createInvoice.bind(invoiceController)
);

// Get invoice by ID
router.get(
  '/:id',
  authenticate,
  validate(invoiceIdValidation),
  invoiceController.getInvoiceById.bind(invoiceController)
);

// Get invoices by user ID
router.get(
  '/',
  authenticate,
  invoiceController.getInvoicesByUserId.bind(invoiceController)
);

// Update invoice
router.put(
  '/:id',
  authenticate,
  validate(updateInvoiceValidation),
  invoiceController.updateInvoice.bind(invoiceController)
);

// Delete invoice
router.delete(
  '/:id',
  authenticate,
  validate(invoiceIdValidation),
  invoiceController.deleteInvoice.bind(invoiceController)
);

export default router;
