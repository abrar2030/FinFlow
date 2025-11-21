import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { paymentApi } from "../services/paymentService";
import { Payment, PaymentFormData } from "../types/payment";

interface PaymentState {
  payments: Payment[];
  payment: Payment | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: PaymentState = {
  payments: [],
  payment: null,
  isLoading: false,
  error: null,
};

export const fetchPayments = createAsyncThunk(
  "payments/fetchAll",
  async (_, { rejectWithValue }) => {
    try {
      const response = await paymentApi.getPayments();
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to fetch payments",
      );
    }
  },
);

export const fetchPaymentById = createAsyncThunk(
  "payments/fetchById",
  async (id: string, { rejectWithValue }) => {
    try {
      const response = await paymentApi.getPaymentById(id);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to fetch payment",
      );
    }
  },
);

export const createPayment = createAsyncThunk(
  "payments/create",
  async (paymentData: PaymentFormData, { rejectWithValue }) => {
    try {
      const response = await paymentApi.createPayment(paymentData);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to create payment",
      );
    }
  },
);

export const processRefund = createAsyncThunk(
  "payments/refund",
  async (id: string, { rejectWithValue }) => {
    try {
      const response = await paymentApi.refundPayment(id);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to process refund",
      );
    }
  },
);

const paymentSlice = createSlice({
  name: "payments",
  initialState,
  reducers: {
    clearPaymentError: (state) => {
      state.error = null;
    },
    clearCurrentPayment: (state) => {
      state.payment = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchPayments.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        fetchPayments.fulfilled,
        (state, action: PayloadAction<Payment[]>) => {
          state.isLoading = false;
          state.payments = action.payload;
        },
      )
      .addCase(fetchPayments.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      .addCase(fetchPaymentById.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        fetchPaymentById.fulfilled,
        (state, action: PayloadAction<Payment>) => {
          state.isLoading = false;
          state.payment = action.payload;
        },
      )
      .addCase(fetchPaymentById.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      .addCase(createPayment.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        createPayment.fulfilled,
        (state, action: PayloadAction<Payment>) => {
          state.isLoading = false;
          state.payments.unshift(action.payload);
        },
      )
      .addCase(createPayment.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      .addCase(processRefund.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        processRefund.fulfilled,
        (state, action: PayloadAction<Payment>) => {
          state.isLoading = false;
          state.payment = action.payload;
          state.payments = state.payments.map((payment) =>
            payment.id === action.payload.id ? action.payload : payment,
          );
        },
      )
      .addCase(processRefund.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearPaymentError, clearCurrentPayment } = paymentSlice.actions;

export default paymentSlice.reducer;
