import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { AppDispatch, RootState } from '../store';
import { fetchBalanceSheet, fetchIncomeStatement, fetchCashFlowStatement } from '../store/slices/accountingSlice';

export const useAccounting = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { balanceSheet, incomeStatement, cashFlowStatement, isLoading, error } = useSelector(
    (state: RootState) => state.accounting
  );
  
  useEffect(() => {
    loadAccountingData();
  }, []);
  
  const loadAccountingData = () => {
    dispatch(fetchBalanceSheet());
    dispatch(fetchIncomeStatement());
    dispatch(fetchCashFlowStatement());
  };
  
  const loadBalanceSheet = (date?: string) => {
    dispatch(fetchBalanceSheet(date));
  };
  
  const loadIncomeStatement = (startDate?: string, endDate?: string) => {
    dispatch(fetchIncomeStatement({ startDate, endDate }));
  };
  
  const loadCashFlowStatement = (startDate?: string, endDate?: string) => {
    dispatch(fetchCashFlowStatement({ startDate, endDate }));
  };
  
  return {
    balanceSheet,
    incomeStatement,
    cashFlowStatement,
    isLoading,
    error,
    loadBalanceSheet,
    loadIncomeStatement,
    loadCashFlowStatement,
    refresh: loadAccountingData
  };
};

export default useAccounting;
