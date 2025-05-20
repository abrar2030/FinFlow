import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { AppDispatch, RootState } from '../store';
import Layout from '../components/common/Layout';
import { getPaymentsStart, getPaymentsSuccess, getPaymentsFailure, createPaymentStart, createPaymentSuccess, createPaymentFailure } from '../store/paymentSlice';
import { getPayments, createPayment } from '../services/paymentService';

const Payments: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { payments, isLoading, error } = useSelector((state: RootState) => state.payment);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    amount: '',
    currency: 'USD',
    source: ''
  });

  useEffect(() => {
    const fetchPayments = async () => {
      try {
        dispatch(getPaymentsStart());
        const data = await getPayments();
        dispatch(getPaymentsSuccess(data));
      } catch (error) {
        dispatch(getPaymentsFailure(error instanceof Error ? error.message : 'Failed to fetch payments'));
      }
    };

    fetchPayments();
  }, [dispatch]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      dispatch(createPaymentStart());
      const { amount, currency } = formData;
      const newPayment = await createPayment({
        userId: 'current-user', // This would normally come from the auth state
        amount: parseFloat(amount),
        currency
      });
      dispatch(createPaymentSuccess(newPayment));
      setShowModal(false);
      setFormData({ amount: '', currency: 'USD', source: '' });
    } catch (error) {
      dispatch(createPaymentFailure(error instanceof Error ? error.message : 'Failed to create payment'));
    }
  };

  const getStatusClass = (status: string) => {
    switch (status) {
      case 'COMPLETED':
        return 'bg-green-100 text-green-800';
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      case 'PROCESSING':
        return 'bg-blue-100 text-blue-800';
      case 'FAILED':
        return 'bg-red-100 text-red-800';
      case 'REFUNDED':
        return 'bg-purple-100 text-purple-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <Layout>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-semibold">Payments</h1>
        <button
          onClick={() => setShowModal(true)}
          className="btn btn-primary"
        >
          Make Payment
        </button>
      </div>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      {isLoading ? (
        <div className="text-center py-10">
          <p>Loading payments...</p>
        </div>
      ) : payments.length > 0 ? (
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Currency</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {payments.map((payment) => (
                <tr key={payment.id}>
                  <td className="px-6 py-4 whitespace-nowrap">{payment.id.substring(0, 8)}...</td>
                  <td className="px-6 py-4 whitespace-nowrap">{payment.amount.toFixed(2)}</td>
                  <td className="px-6 py-4 whitespace-nowrap">{payment.currency}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusClass(payment.status)}`}>
                      {payment.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">{new Date(payment.createdAt).toLocaleDateString()}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm">
                    <button className="text-primary-600 hover:text-primary-900">View Details</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="text-center py-10">
          <p className="text-gray-500">No payments found. Make your first payment!</p>
        </div>
      )}

      {/* Make Payment Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-8 max-w-md w-full">
            <h2 className="text-xl font-semibold mb-4">Make Payment</h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="amount">
                  Amount
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="amount"
                  name="amount"
                  type="number"
                  step="0.01"
                  placeholder="Amount"
                  value={formData.amount}
                  onChange={handleInputChange}
                  required
                />
              </div>
              <div className="mb-4">
                <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="currency">
                  Currency
                </label>
                <select
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="currency"
                  name="currency"
                  value={formData.currency}
                  onChange={handleInputChange}
                  required
                >
                  <option value="USD">USD</option>
                  <option value="EUR">EUR</option>
                  <option value="GBP">GBP</option>
                  <option value="JPY">JPY</option>
                </select>
              </div>
              <div className="mb-6">
                <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="source">
                  Card Information
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="source"
                  name="source"
                  type="text"
                  placeholder="Card Number"
                  value={formData.source}
                  onChange={handleInputChange}
                  required
                />
                <p className="text-xs text-gray-500 mt-1">For demo purposes only. No real payment will be processed.</p>
              </div>
              <div className="flex items-center justify-end">
                <button
                  className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded mr-2"
                  type="button"
                  onClick={() => setShowModal(false)}
                >
                  Cancel
                </button>
                <button
                  className="bg-primary-600 hover:bg-primary-700 text-white font-bold py-2 px-4 rounded"
                  type="submit"
                  disabled={isLoading}
                >
                  {isLoading ? 'Processing...' : 'Make Payment'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </Layout>
  );
};

export default Payments;
