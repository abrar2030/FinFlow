import { Router } from "express";
import accountingController from "../accounting.controller";
import { validateRequest } from "../middleware/validation.middleware";
import {
  createJournalEntrySchema,
  dateRangeSchema,
} from "../validators/accounting.validator";

const router = Router();

// Journal entries
router.post(
  "/journal-entries",
  validateRequest(createJournalEntrySchema),
  accountingController.createJournalEntry,
);
router.get("/journal-entries", accountingController.getAllJournalEntries);
router.get("/journal-entries/:id", accountingController.getJournalEntryById);

// Financial reports
router.get("/reports/trial-balance", accountingController.getTrialBalance);
router.get(
  "/reports/income-statement",
  validateRequest(dateRangeSchema),
  accountingController.getIncomeStatement,
);
router.get("/reports/balance-sheet", accountingController.getBalanceSheet);
router.get(
  "/reports/cash-flow",
  validateRequest(dateRangeSchema),
  accountingController.getCashFlowStatement,
);

// Accounts
router.get("/accounts", accountingController.getAllAccounts);
router.get("/accounts/:id", accountingController.getAccountById);
router.get("/accounts/:id/balance", accountingController.getAccountBalance);

// Analytics integration
router.get(
  "/analytics/financial-metrics",
  validateRequest(dateRangeSchema),
  accountingController.getFinancialMetrics,
);
router.get(
  "/analytics/transaction-summary",
  validateRequest(dateRangeSchema),
  accountingController.getTransactionSummary,
);

export default router;
