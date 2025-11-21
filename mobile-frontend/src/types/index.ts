// Common types used throughout the application

export interface User {
  id: string;
  email: string;
  firstName?: string;
  lastName?: string;
  role: "admin" | "user" | "manager";
  createdAt: string;
  updatedAt: string;
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  error: string | null;
}

export interface Transaction {
  id: string;
  amount: number;
  currency: string;
  status: "pending" | "completed" | "failed" | "refunded";
  processorId: string;
  processorType: "stripe" | "paypal" | "square";
  metadata?: Record<string, any>;
  createdAt: string;
  updatedAt: string;
}

export interface PaymentRequest {
  amount: number;
  currency: string;
  processorType: "stripe" | "paypal" | "square";
  source: string;
  metadata?: Record<string, any>;
}

export interface AccountingEntry {
  id: string;
  transactionId: string;
  accountId: string;
  amount: number;
  type: "debit" | "credit";
  description: string;
  createdAt: string;
}

export interface FinancialReport {
  id: string;
  type: "balance_sheet" | "income_statement" | "cash_flow";
  startDate: string;
  endDate: string;
  data: Record<string, any>;
  createdAt: string;
}

export interface AnalyticsMetric {
  id: string;
  name: string;
  value: number;
  previousValue?: number;
  changePercentage?: number;
  period: "daily" | "weekly" | "monthly" | "yearly";
  date: string;
}

export interface CreditScore {
  id: string;
  userId: string;
  score: number;
  factors: Array<{
    factor: string;
    impact: "positive" | "negative" | "neutral";
    description: string;
  }>;
  createdAt: string;
}

export interface Loan {
  id: string;
  userId: string;
  amount: number;
  interestRate: number;
  term: number; // in months
  status: "pending" | "approved" | "rejected" | "active" | "paid";
  startDate?: string;
  endDate?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ApiResponse<T> {
  data: T;
  message?: string;
  status: number;
}

export interface ApiError {
  message: string;
  status: number;
  errors?: Record<string, string[]>;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface NavigationParams {
  [key: string]: any;
}
