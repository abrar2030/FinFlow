import express from "express";
import transactionController from "../controllers/transaction.controller";
import { authenticate } from "../middlewares/auth.middleware";
import { validate } from "../middlewares/validation.middleware";
import {
  createTransactionValidation,
  transactionIdValidation,
  updateTransactionValidation,
} from "../validators/transaction.validator";

const router = express.Router();

// Create a new transaction
router.post(
  "/",
  authenticate,
  validate(createTransactionValidation),
  transactionController.createTransaction.bind(transactionController),
);

// Get transaction by ID
router.get(
  "/:id",
  authenticate,
  validate(transactionIdValidation),
  transactionController.getTransactionById.bind(transactionController),
);

// Get transactions by user ID
router.get(
  "/",
  authenticate,
  transactionController.getTransactionsByUserId.bind(transactionController),
);

// Update transaction
router.put(
  "/:id",
  authenticate,
  validate(updateTransactionValidation),
  transactionController.updateTransaction.bind(transactionController),
);

// Delete transaction
router.delete(
  "/:id",
  authenticate,
  validate(transactionIdValidation),
  transactionController.deleteTransaction.bind(transactionController),
);

// Get transactions by date range
router.get(
  "/date-range",
  authenticate,
  transactionController.getTransactionsByDateRange.bind(transactionController),
);

export default router;
