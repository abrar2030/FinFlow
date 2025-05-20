import { PaymentStatus } from '@prisma/client';

export interface Payment {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  processorId?: string;
  processorData?: any;
  metadata?: any;
  createdAt: Date;
  updatedAt: Date;
}

export interface PaymentCreateInput {
  userId: string;
  amount: number;
  currency?: string;
  status: PaymentStatus;
  processorId?: string;
  processorData?: any;
  metadata?: any;
}

export interface PaymentUpdateInput {
  amount?: number;
  currency?: string;
  status?: PaymentStatus;
  processorId?: string;
  processorData?: any;
  metadata?: any;
}

export interface ChargeInput {
  userId: string;
  amount: number;
  currency?: string;
  source: string;
  metadata?: any;
}

export interface RefundInput {
  paymentId: string;
  amount?: number;
  reason?: string;
}

export interface PaymentResponse {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  processorId?: string;
  metadata?: any;
  createdAt: Date;
  updatedAt: Date;
}
