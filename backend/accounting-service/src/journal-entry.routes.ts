import express from "express";
import journalEntryController from "../controllers/journal-entry.controller";
import { authenticate } from "../middlewares/auth.middleware";
import { validate } from "../middlewares/validation.middleware";
import {
  createJournalEntryValidation,
  journalEntryIdValidation,
  updateJournalEntryValidation,
} from "../validators/journal-entry.validator";

const router = express.Router();

// Create a new journal entry
router.post(
  "/",
  authenticate,
  validate(createJournalEntryValidation),
  journalEntryController.createJournalEntry.bind(journalEntryController),
);

// Get journal entry by ID
router.get(
  "/:id",
  authenticate,
  validate(journalEntryIdValidation),
  journalEntryController.getJournalEntryById.bind(journalEntryController),
);

// Get journal entries by invoice ID
router.get(
  "/invoice/:invoiceId",
  authenticate,
  journalEntryController.getJournalEntriesByInvoiceId.bind(
    journalEntryController,
  ),
);

// Update journal entry
router.put(
  "/:id",
  authenticate,
  validate(updateJournalEntryValidation),
  journalEntryController.updateJournalEntry.bind(journalEntryController),
);

// Delete journal entry
router.delete(
  "/:id",
  authenticate,
  validate(journalEntryIdValidation),
  journalEntryController.deleteJournalEntry.bind(journalEntryController),
);

// Get all journal entries
router.get(
  "/",
  authenticate,
  journalEntryController.getAllJournalEntries.bind(journalEntryController),
);

export default router;
