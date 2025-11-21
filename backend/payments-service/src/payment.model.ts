import { PrismaClient } from "@prisma/client";
import {
  Payment,
  PaymentCreateInput,
  PaymentUpdateInput,
} from "../types/payment.types";

class PaymentModel {
  private prisma: PrismaClient;

  constructor() {
    this.prisma = new PrismaClient();
  }

  async findById(id: string): Promise<Payment | null> {
    return this.prisma.payment.findUnique({
      where: { id },
    });
  }

  async findByUserId(userId: string): Promise<Payment[]> {
    return this.prisma.payment.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
    });
  }

  async findByProcessorId(processorId: string): Promise<Payment | null> {
    return this.prisma.payment.findFirst({
      where: { processorId },
    });
  }

  async create(data: PaymentCreateInput): Promise<Payment> {
    return this.prisma.payment.create({
      data,
    });
  }

  async update(id: string, data: PaymentUpdateInput): Promise<Payment> {
    return this.prisma.payment.update({
      where: { id },
      data,
    });
  }

  async delete(id: string): Promise<Payment> {
    return this.prisma.payment.delete({
      where: { id },
    });
  }

  async findAll(): Promise<Payment[]> {
    return this.prisma.payment.findMany({
      orderBy: { createdAt: "desc" },
    });
  }
}

export default new PaymentModel();
