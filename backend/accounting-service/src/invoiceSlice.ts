import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { invoiceApi } from "../services/invoiceService";
import { Invoice, InvoiceFormData } from "../types/invoice";

interface InvoiceState {
  invoices: Invoice[];
  invoice: Invoice | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: InvoiceState = {
  invoices: [],
  invoice: null,
  isLoading: false,
  error: null,
};

export const fetchInvoices = createAsyncThunk(
  "invoices/fetchAll",
  async (_, { rejectWithValue }) => {
    try {
      const response = await invoiceApi.getInvoices();
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to fetch invoices",
      );
    }
  },
);

export const fetchInvoiceById = createAsyncThunk(
  "invoices/fetchById",
  async (id: string, { rejectWithValue }) => {
    try {
      const response = await invoiceApi.getInvoiceById(id);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to fetch invoice",
      );
    }
  },
);

export const createInvoice = createAsyncThunk(
  "invoices/create",
  async (invoiceData: InvoiceFormData, { rejectWithValue }) => {
    try {
      const response = await invoiceApi.createInvoice(invoiceData);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to create invoice",
      );
    }
  },
);

export const updateInvoice = createAsyncThunk(
  "invoices/update",
  async (
    { id, data }: { id: string; data: Partial<InvoiceFormData> },
    { rejectWithValue },
  ) => {
    try {
      const response = await invoiceApi.updateInvoice(id, data);
      return response;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to update invoice",
      );
    }
  },
);

export const deleteInvoice = createAsyncThunk(
  "invoices/delete",
  async (id: string, { rejectWithValue }) => {
    try {
      await invoiceApi.deleteInvoice(id);
      return id;
    } catch (error: any) {
      return rejectWithValue(
        error.response?.data?.message || "Failed to delete invoice",
      );
    }
  },
);

const invoiceSlice = createSlice({
  name: "invoices",
  initialState,
  reducers: {
    clearInvoiceError: (state) => {
      state.error = null;
    },
    clearCurrentInvoice: (state) => {
      state.invoice = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchInvoices.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        fetchInvoices.fulfilled,
        (state, action: PayloadAction<Invoice[]>) => {
          state.isLoading = false;
          state.invoices = action.payload;
        },
      )
      .addCase(fetchInvoices.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      .addCase(fetchInvoiceById.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        fetchInvoiceById.fulfilled,
        (state, action: PayloadAction<Invoice>) => {
          state.isLoading = false;
          state.invoice = action.payload;
        },
      )
      .addCase(fetchInvoiceById.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      .addCase(createInvoice.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        createInvoice.fulfilled,
        (state, action: PayloadAction<Invoice>) => {
          state.isLoading = false;
          state.invoices.unshift(action.payload);
        },
      )
      .addCase(createInvoice.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      .addCase(updateInvoice.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        updateInvoice.fulfilled,
        (state, action: PayloadAction<Invoice>) => {
          state.isLoading = false;
          state.invoice = action.payload;
          state.invoices = state.invoices.map((invoice) =>
            invoice.id === action.payload.id ? action.payload : invoice,
          );
        },
      )
      .addCase(updateInvoice.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      .addCase(deleteInvoice.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(
        deleteInvoice.fulfilled,
        (state, action: PayloadAction<string>) => {
          state.isLoading = false;
          state.invoices = state.invoices.filter(
            (invoice) => invoice.id !== action.payload,
          );
        },
      )
      .addCase(deleteInvoice.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearInvoiceError, clearCurrentInvoice } = invoiceSlice.actions;

export default invoiceSlice.reducer;
