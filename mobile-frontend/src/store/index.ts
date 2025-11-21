import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./slices/authSlice";
import paymentsReducer from "./slices/paymentsSlice";
import analyticsReducer from "./slices/analyticsSlice";
import accountingReducer from "./slices/accountingSlice";
import creditReducer from "./slices/creditSlice";

export const store = configureStore({
  reducer: {
    auth: authReducer,
    payments: paymentsReducer,
    analytics: analyticsReducer,
    accounting: accountingReducer,
    credit: creditReducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: false,
    }),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
