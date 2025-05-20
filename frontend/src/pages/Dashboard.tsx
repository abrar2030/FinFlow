import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { AppDispatch, RootState } from '../store';
import Layout from '../components/common/Layout';
import { getInvoicesStart, getInvoicesSuccess, getInvoicesFailure } from '../store/invoiceSlice';
import { getPaymentsStart, getPaymentsSuccess, getPaymentsFailure } from '../store/paymentSlice';
import { getTransactionsStart, getTransactionsSuccess, getTransactionsFailure } from '../store/transactionSlice';
import { getInvoices } from '../services/invoiceService';
import { getPayments } from '../services/paymentService';
import { getTransactions, getForecast } from '../services/analyticsService';

const Dashboard: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { user } = useSelector((state: RootState) => state.auth);
  const { invoices } = useSelector((state: RootState) => state.invoice);
  const { payments } = useSelector((state: RootState) => state.payment);
  const { transactions } = useSelector((state: RootState) => state.transaction);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch invoices
        dispatch(getInvoicesStart());
        const invoicesData = await getInvoices();
        dispatch(getInvoicesSuccess(invoicesData));
        
        // Fetch payments
        dispatch(getPaymentsStart());
        const paymentsData = await getPayments();
        dispatch(getPaymentsSuccess(paymentsData));
        
        // Fetch transactions
        dispatch(getTransactionsStart());
        const transactionsData = await getTransactions();
        dispatch(getTransactionsSuccess(transactionsData));
      } catch (error) {
        dispatch(getInvoicesFailure('Failed to fetch dashboard data'));
        dispatch(getPaymentsFailure('Failed to fetch dashboard data'));
        dispatch(getTransactionsFailure('Failed to fetch dashboard data'));
      }
    };
    
    fetchData();
  }, [dispatch]);

  // Calculate KPIs
  const totalInvoices = invoices.length;
  const pendingInvoices = invoices.filter(invoice => invoice.status === 'PENDING').length;
  const totalRevenue = invoices.reduce((sum, invoice) => sum + invoice.amount, 0);
  const totalPayments = payments.length;
  const completedPayments = payments.filter(payment => payment.status === 'COMPLETED').length;
  const totalTransactions = transactions.length;

  return (
    <Layout>
      <div className="mb-6">
        <h1 className="text-2xl font-semibold">Dashboard</h1>
        <p className="text-gray-600">Welcome back, {user?.email}</p>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {/* KPI Cards */}
        <div className="card">
          <h3 className="text-lg font-medium mb-2">Invoices</h3>
          <div className="flex justify-between items-center">
            <div>
              <p className="text-3xl font-bold">{totalInvoices}</p>
              <p className="text-sm text-gray-500">Total Invoices</p>
            </div>
            <div>
              <p className="text-xl font-semibold">{pendingInvoices}</p>
              <p className="text-sm text-gray-500">Pending</p>
            </div>
          </div>
        </div>
        
        <div className="card">
          <h3 className="text-lg font-medium mb-2">Revenue</h3>
          <div>
            <p className="text-3xl font-bold">${totalRevenue.toFixed(2)}</p>
            <p className="text-sm text-gray-500">Total Revenue</p>
          </div>
        </div>
        
        <div className="card">
          <h3 className="text-lg font-medium mb-2">Payments</h3>
          <div className="flex justify-between items-center">
            <div>
              <p className="text-3xl font-bold">{totalPayments}</p>
              <p className="text-sm text-gray-500">Total Payments</p>
            </div>
            <div>
              <p className="text-xl font-semibold">{completedPayments}</p>
              <p className="text-sm text-gray-500">Completed</p>
            </div>
          </div>
        </div>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Charts would go here - using placeholders */}
        <div className="card">
          <h3 className="text-lg font-medium mb-4">Revenue Trend</h3>
          <div className="h-64 bg-gray-100 rounded flex items-center justify-center">
            <p className="text-gray-500">Revenue Chart Placeholder</p>
          </div>
        </div>
        
        <div className="card">
          <h3 className="text-lg font-medium mb-4">Cash Flow Forecast</h3>
          <div className="h-64 bg-gray-100 rounded flex items-center justify-center">
            <p className="text-gray-500">Cash Flow Forecast Chart Placeholder</p>
          </div>
        </div>
      </div>
      
      <div className="card">
        <h3 className="text-lg font-medium mb-4">Recent Transactions</h3>
        {transactions.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead>
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {transactions.slice(0, 5).map((transaction) => (
                  <tr key={transaction.id}>
                    <td className="px-6 py-4 whitespace-nowrap">{transaction.description}</td>
                    <td className="px-6 py-4 whitespace-nowrap">${transaction.amount.toFixed(2)}</td>
                    <td className="px-6 py-4 whitespace-nowrap">{transaction.category}</td>
                    <td className="px-6 py-4 whitespace-nowrap">{new Date(transaction.transactionDate).toLocaleDateString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="text-gray-500">No recent transactions</p>
        )}
      </div>
    </Layout>
  );
};

export default Dashboard;
