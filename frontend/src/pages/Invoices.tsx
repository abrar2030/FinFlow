import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { AppDispatch, RootState } from '../store';
import Layout from '../components/common/Layout';
import { getInvoicesStart, getInvoicesSuccess, getInvoicesFailure, createInvoiceStart, createInvoiceSuccess, createInvoiceFailure } from '../store/invoiceSlice';
import { getInvoices, createInvoice } from '../services/invoiceService';
import { Invoice } from '../types';

const Invoices: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { invoices, isLoading, error } = useSelector((state: RootState) => state.invoice);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    client: '',
    amount: '',
    dueDate: ''
  });

  useEffect(() => {
    const fetchInvoices = async () => {
      try {
        dispatch(getInvoicesStart());
        const data = await getInvoices();
        dispatch(getInvoicesSuccess(data));
      } catch (error) {
        dispatch(getInvoicesFailure(error instanceof Error ? error.message : 'Failed to fetch invoices'));
      }
    };

    fetchInvoices();
  }, [dispatch]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      dispatch(createInvoiceStart());
      const { client, amount, dueDate } = formData;
      const newInvoice = await createInvoice({
        userId: 'current-user', // This would normally come from the auth state
        client,
        amount: parseFloat(amount),
        dueDate,
        status: 'PENDING'
      });
      dispatch(createInvoiceSuccess(newInvoice));
      setShowModal(false);
      setFormData({ client: '', amount: '', dueDate: '' });
    } catch (error) {
      dispatch(createInvoiceFailure(error instanceof Error ? error.message : 'Failed to create invoice'));
    }
  };

  const getStatusClass = (status: string) => {
    switch (status) {
      case 'PAID':
        return 'bg-green-100 text-green-800';
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      case 'OVERDUE':
        return 'bg-red-100 text-red-800';
      case 'CANCELLED':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <Layout>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-semibold">Invoices</h1>
        <button
          onClick={() => setShowModal(true)}
          className="btn btn-primary"
        >
          Create Invoice
        </button>
      </div>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      {isLoading ? (
        <div className="text-center py-10">
          <p>Loading invoices...</p>
        </div>
      ) : invoices.length > 0 ? (
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Client</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Due Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {invoices.map((invoice) => (
                <tr key={invoice.id}>
                  <td className="px-6 py-4 whitespace-nowrap">{invoice.client}</td>
                  <td className="px-6 py-4 whitespace-nowrap">${invoice.amount.toFixed(2)}</td>
                  <td className="px-6 py-4 whitespace-nowrap">{new Date(invoice.dueDate).toLocaleDateString()}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusClass(invoice.status)}`}>
                      {invoice.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm">
                    <button className="text-primary-600 hover:text-primary-900 mr-3">View</button>
                    <button className="text-primary-600 hover:text-primary-900">Edit</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="text-center py-10">
          <p className="text-gray-500">No invoices found. Create your first invoice!</p>
        </div>
      )}

      {/* Create Invoice Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-8 max-w-md w-full">
            <h2 className="text-xl font-semibold mb-4">Create New Invoice</h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="client">
                  Client Name
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="client"
                  name="client"
                  type="text"
                  placeholder="Client Name"
                  value={formData.client}
                  onChange={handleInputChange}
                  required
                />
              </div>
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
              <div className="mb-6">
                <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="dueDate">
                  Due Date
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="dueDate"
                  name="dueDate"
                  type="date"
                  value={formData.dueDate}
                  onChange={handleInputChange}
                  required
                />
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
                  {isLoading ? 'Creating...' : 'Create Invoice'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </Layout>
  );
};

export default Invoices;
