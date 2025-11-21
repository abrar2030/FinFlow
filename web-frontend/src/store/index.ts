import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./authSlice";
import invoiceReducer from "./invoiceSlice";
import paymentReducer from "./paymentSlice";
import transactionReducer from "./transactionSlice";
import uiReducer from "./uiSlice";

export const store = configureStore({
  reducer: {
    auth: authReducer,
    invoice: invoiceReducer,
    payment: paymentReducer,
    transaction: transactionReducer,
    ui: uiReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export default store;
