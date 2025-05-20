import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { AppDispatch, RootState } from '../store';
import Layout from '../components/common/Layout';
import { getTransactionsStart, getTransactionsSuccess, getTransactionsFailure } from '../store/transactionSlice';
import { getTransactions, getForecast, getCategorizedTransactions } from '../services/analyticsService';

const Analytics: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { transactions, isLoading, error } = useSelector((state: RootState) => state.transaction);
  const [forecastData, setForecastData] = useState<any>(null);
  const [forecastLoading, setForecastLoading] = useState(false);
  const [forecastError, setForecastError] = useState<string | null>(null);
  const [forecastType, setForecastType] = useState<'revenue' | 'expense' | 'cashflow'>('cashflow');

  useEffect(() => {
    const fetchData = async () => {
      try {
        dispatch(getTransactionsStart());
        const data = await getTransactions();
        dispatch(getTransactionsSuccess(data));
        
        // Fetch initial forecast
        fetchForecast('cashflow');
      } catch (error) {
        dispatch(getTransactionsFailure(error instanceof Error ? error.message : 'Failed to fetch transactions'));
      }
    };

    fetchData();
  }, [dispatch]);

  const fetchForecast = async (type: 'revenue' | 'expense' | 'cashflow') => {
    try {
      setForecastLoading(true);
      setForecastError(null);
      
      // Calculate date range for forecast (next 3 months)
      const startDate = new Date().toISOString().split('T')[0];
      const endDate = new Date(new Date().setMonth(new Date().getMonth() + 3)).toISOString().split('T')[0];
      
      const data = await getForecast(startDate, endDate, type);
      setForecastData(data);
      setForecastType(type);
    } catch (error) {
      setForecastError(error instanceof Error ? error.message : 'Failed to fetch forecast');
    } finally {
      setForecastLoading(false);
    }
  };

  const handleForecastTypeChange = (type: 'revenue' | 'expense' | 'cashflow') => {
    if (type !== forecastType) {
      fetchForecast(type);
    }
  };

  // Group transactions by category for the pie chart
  const categoryData = React.useMemo(() => {
    const categories: Record<string, number> = {};
    transactions.forEach(transaction => {
      if (categories[transaction.category]) {
        categories[transaction.category] += transaction.amount;
      } else {
        categories[transaction.category] = transaction.amount;
      }
    });
    return categories;
  }, [transactions]);

  return (
    <Layout>
      <div className="mb-6">
        <h1 className="text-2xl font-semibold">Analytics</h1>
        <p className="text-gray-600">Financial insights and forecasting</p>
      </div>

      {/* Cash Flow Forecast */}
      <div className="card mb-8">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-medium">Cash Flow Forecast</h2>
          <div className="flex space-x-2">
            <button 
              className={`px-3 py-1 rounded text-sm ${forecastType === 'cashflow' ? 'bg-primary-600 text-white' : 'bg-gray-200 text-gray-700'}`}
              onClick={() => handleForecastTypeChange('cashflow')}
            >
              Cash Flow
            </button>
            <button 
              className={`px-3 py-1 rounded text-sm ${forecastType === 'revenue' ? 'bg-primary-600 text-white' : 'bg-gray-200 text-gray-700'}`}
              onClick={() => handleForecastTypeChange('revenue')}
            >
              Revenue
            </button>
            <button 
              className={`px-3 py-1 rounded text-sm ${forecastType === 'expense' ? 'bg-primary-600 text-white' : 'bg-gray-200 text-gray-700'}`}
              onClick={() => handleForecastTypeChange('expense')}
            >
              Expenses
            </button>
          </div>
        </div>
        
        {forecastLoading ? (
          <div className="h-64 flex items-center justify-center">
            <p>Loading forecast data...</p>
          </div>
        ) : forecastError ? (
          <div className="h-64 flex items-center justify-center">
            <p className="text-red-500">{forecastError}</p>
          </div>
        ) : forecastData ? (
          <div className="h-64 bg-gray-100 rounded flex items-center justify-center">
            <p className="text-gray-500">Forecast Chart Placeholder</p>
            {/* In a real implementation, this would be a Chart.js component */}
          </div>
        ) : (
          <div className="h-64 flex items-center justify-center">
            <p className="text-gray-500">No forecast data available</p>
          </div>
        )}
      </div>

      {/* Expense Categories */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <div className="card">
          <h2 className="text-xl font-medium mb-4">Expense Categories</h2>
          {isLoading ? (
            <div className="h-64 flex items-center justify-center">
              <p>Loading category data...</p>
            </div>
          ) : error ? (
            <div className="h-64 flex items-center justify-center">
              <p className="text-red-500">{error}</p>
            </div>
          ) : Object.keys(categoryData).length > 0 ? (
            <div className="h-64 bg-gray-100 rounded flex items-center justify-center">
              <p className="text-gray-500">Category Pie Chart Placeholder</p>
              {/* In a real implementation, this would be a Chart.js pie chart */}
            </div>
          ) : (
            <div className="h-64 flex items-center justify-center">
              <p className="text-gray-500">No category data available</p>
            </div>
          )}
        </div>

        <div className="card">
          <h2 className="text-xl font-medium mb-4">Monthly Trends</h2>
          <div className="h-64 bg-gray-100 rounded flex items-center justify-center">
            <p className="text-gray-500">Monthly Trends Chart Placeholder</p>
            {/* In a real implementation, this would be a Chart.js line chart */}
          </div>
        </div>
      </div>

      {/* Transaction List */}
      <div className="card">
        <h2 className="text-xl font-medium mb-4">Recent Transactions</h2>
        {isLoading ? (
          <div className="text-center py-10">
            <p>Loading transactions...</p>
          </div>
        ) : error ? (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        ) : transactions.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {transactions.map((transaction) => (
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
          <div className="text-center py-10">
            <p className="text-gray-500">No transactions found</p>
          </div>
        )}
      </div>
    </Layout>
  );
};

export default Analytics;
