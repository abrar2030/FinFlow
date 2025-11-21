// Common types used across the application

// Auth types
export interface User {
  id: string;
  email: string;
  role: "USER" | "ADMIN";
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

// Invoice types
export interface Invoice {
  id: string;
  userId: string;
  client: string;
  amount: number;
  dueDate: string;
  status: "PENDING" | "PAID" | "OVERDUE" | "CANCELLED";
  createdAt: string;
  updatedAt: string;
}

export interface InvoiceState {
  invoices: Invoice[];
  currentInvoice: Invoice | null;
  isLoading: boolean;
  error: string | null;
}

// Payment types
export interface Payment {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  status: "PENDING" | "PROCESSING" | "COMPLETED" | "FAILED" | "REFUNDED";
  processorId?: string;
  processorData?: any;
  metadata?: any;
  createdAt: string;
  updatedAt: string;
}

export interface PaymentState {
  payments: Payment[];
  currentPayment: Payment | null;
  isLoading: boolean;
  error: string | null;
}

// Transaction types
export interface Transaction {
  id: string;
  userId: string;
  description: string;
  amount: number;
  category: string;
  transactionDate: string;
  createdAt: string;
  updatedAt: string;
}

export interface TransactionState {
  transactions: Transaction[];
  currentTransaction: Transaction | null;
  isLoading: boolean;
  error: string | null;
}

// UI types
export interface UIState {
  sidebarOpen: boolean;
  darkMode: boolean;
  notifications: Notification[];
}

export interface Notification {
  id: string;
  message: string;
  type: "success" | "error" | "info" | "warning";
  read: boolean;
  createdAt: string;
}

// Analytics types
export interface ForecastData {
  date: string;
  value: number;
}

export interface CashFlowForecast {
  userId: string;
  forecastType: "revenue" | "expense" | "cashflow";
  startDate: string;
  endDate: string;
  data: ForecastData[];
}

export interface AnalyticsState {
  cashFlowForecast: CashFlowForecast | null;
  categorizedTransactions: Transaction[];
  isLoading: boolean;
  error: string | null;
}
