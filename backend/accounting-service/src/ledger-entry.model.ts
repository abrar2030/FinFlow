import { PrismaClient } from "@prisma/client";
import {
  LedgerEntry,
  LedgerEntryCreateInput,
  LedgerEntryUpdateInput,
} from "../types/ledger-entry.types";

class LedgerEntryModel {
  private prisma: PrismaClient;

  constructor() {
    this.prisma = new PrismaClient();
  }

  async findById(id: string): Promise<LedgerEntry | null> {
    return this.prisma.ledgerEntry.findUnique({
      where: { id },
    });
  }

  async findByJournalEntryId(journalEntryId: string): Promise<LedgerEntry[]> {
    return this.prisma.ledgerEntry.findMany({
      where: { journalEntryId },
      include: {
        account: true,
      },
    });
  }

  async findByAccountId(accountId: string): Promise<LedgerEntry[]> {
    return this.prisma.ledgerEntry.findMany({
      where: { accountId },
      include: {
        journalEntry: true,
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async create(data: LedgerEntryCreateInput): Promise<LedgerEntry> {
    return this.prisma.ledgerEntry.create({
      data,
      include: {
        account: true,
        journalEntry: true,
      },
    });
  }

  async createMany(data: LedgerEntryCreateInput[]): Promise<number> {
    const result = await this.prisma.ledgerEntry.createMany({
      data,
    });
    return result.count;
  }

  async update(id: string, data: LedgerEntryUpdateInput): Promise<LedgerEntry> {
    return this.prisma.ledgerEntry.update({
      where: { id },
      data,
      include: {
        account: true,
        journalEntry: true,
      },
    });
  }

  async delete(id: string): Promise<LedgerEntry> {
    return this.prisma.ledgerEntry.delete({
      where: { id },
    });
  }

  async findAll(): Promise<LedgerEntry[]> {
    return this.prisma.ledgerEntry.findMany({
      include: {
        account: true,
        journalEntry: true,
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async findByDateRange(
    startDate: Date,
    endDate: Date,
  ): Promise<LedgerEntry[]> {
    return this.prisma.ledgerEntry.findMany({
      where: {
        journalEntry: {
          date: {
            gte: startDate,
            lte: endDate,
          },
        },
      },
      include: {
        account: true,
        journalEntry: true,
      },
      orderBy: { createdAt: "desc" },
    });
  }
}

export default new LedgerEntryModel();
