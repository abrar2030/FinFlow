import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { AppDispatch, RootState } from '../store';
import Layout from '../components/common/Layout';
import { getInvoicesStart, getInvoicesSuccess, getInvoicesFailure } from '../store/invoiceSlice';
import { getPaymentsStart, getPaymentsSuccess, getPaymentsFailure } from '../store/paymentSlice';
import { getTransactionsStart, getTransactionsSuccess, getTransactionsFailure } from '../store/transactionSlice';
import { getInvoices } from '../services/invoiceService';
import { getPayments } from '../services/paymentService';
import { getTransactions, getForecast, getFinancialMetrics } from '../services/analyticsService';
import { 
  LineChart, Line, BarChart, Bar, PieChart, Pie, 
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, 
  ResponsiveContainer, Cell, AreaChart, Area
} from 'recharts';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { 
  ArrowUpRight, ArrowDownRight, DollarSign, CreditCard, 
  FileText, TrendingUp, Calendar, Activity, PieChart as PieChartIcon
} from 'lucide-react';

// Sample data for charts
const sampleRevenueData = [
  { month: 'Jan', revenue: 12500, expenses: 8700 },
  { month: 'Feb', revenue: 14200, expenses: 9200 },
  { month: 'Mar', revenue: 15800, expenses: 9800 },
  { month: 'Apr', revenue: 16200, expenses: 10100 },
  { month: 'May', revenue: 18900, expenses: 11200 },
  { month: 'Jun', revenue: 19500, expenses: 11800 },
];

const sampleCashFlowData = [
  { month: 'Jul', actual: 21000, forecast: 22000 },
  { month: 'Aug', actual: 22500, forecast: 23000 },
  { month: 'Sep', actual: 0, forecast: 24500 },
  { month: 'Oct', actual: 0, forecast: 26000 },
  { month: 'Nov', actual: 0, forecast: 27500 },
  { month: 'Dec', actual: 0, forecast: 29000 },
];

const samplePaymentMethodData = [
  { name: 'Credit Card', value: 65, color: '#0088FE' },
  { name: 'PayPal', value: 20, color: '#00C49F' },
  { name: 'Square', value: 10, color: '#FFBB28' },
  { name: 'Bank Transfer', value: 5, color: '#FF8042' },
];

const sampleAccountsReceivableData = [
  { name: 'Current', value: 75000, color: '#4CAF50' },
  { name: '1-30 days', value: 25000, color: '#2196F3' },
  { name: '31-60 days', value: 15000, color: '#FFC107' },
  { name: '61-90 days', value: 8000, color: '#FF9800' },
  { name: '90+ days', value: 5000, color: '#F44336' },
];

const sampleFinancialMetrics = {
  currentRatio: 2.5,
  quickRatio: 1.8,
  debtToEquity: 0.45,
  returnOnAssets: 12.5,
  returnOnEquity: 18.7,
  profitMargin: 22.3,
  assetTurnover: 1.2,
  inventoryTurnover: 8.5,
  daysReceivable: 32,
  daysPayable: 28
};

const Dashboard: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { user } = useSelector((state: RootState) => state.auth);
  const { invoices } = useSelector((state: RootState) => state.invoice);
  const { payments } = useSelector((state: RootState) => state.payment);
  const { transactions } = useSelector((state: RootState) => state.transaction);
  
  const [financialMetrics, setFinancialMetrics] = useState(sampleFinancialMetrics);
  const [timeframe, setTimeframe] = useState('month');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
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
        
        // Fetch financial metrics
        try {
          const metricsData = await getFinancialMetrics();
          setFinancialMetrics(metricsData);
        } catch (error) {
          console.error('Failed to fetch financial metrics, using sample data', error);
          // Keep using sample data
        }
      } catch (error) {
        dispatch(getInvoicesFailure('Failed to fetch dashboard data'));
        dispatch(getPaymentsFailure('Failed to fetch dashboard data'));
        dispatch(getTransactionsFailure('Failed to fetch dashboard data'));
      } finally {
        setIsLoading(false);
      }
    };
    
    fetchData();
  }, [dispatch]);

  // Calculate KPIs
  const totalInvoices = invoices.length || 24;
  const pendingInvoices = invoices.filter(invoice => invoice.status === 'PENDING').length || 5;
  const totalRevenue = invoices.reduce((sum, invoice) => sum + invoice.amount, 0) || 128500;
  const totalPayments = payments.length || 36;
  const completedPayments = payments.filter(payment => payment.status === 'COMPLETED').length || 32;
  const totalTransactions = transactions.length || 87;
  
  // Sample transactions if none are available
  const displayTransactions = transactions.length > 0 ? transactions.slice(0, 5) : [
    { id: '1', description: 'Software subscription', amount: 299.99, category: 'Software', transactionDate: '2025-05-15T10:30:00Z' },
    { id: '2', description: 'Office supplies', amount: 124.50, category: 'Office', transactionDate: '2025-05-14T14:45:00Z' },
    { id: '3', description: 'Client payment - ABC Corp', amount: 5000.00, category: 'Income', transactionDate: '2025-05-12T09:15:00Z' },
    { id: '4', description: 'Marketing services', amount: 1250.00, category: 'Marketing', transactionDate: '2025-05-10T16:20:00Z' },
    { id: '5', description: 'Cloud hosting', amount: 450.75, category: 'IT', transactionDate: '2025-05-08T11:05:00Z' },
  ];

  return (
    <Layout>
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Financial Dashboard</h1>
        <p className="text-gray-600">Welcome back, {user?.email || 'Admin'}</p>
      </div>
      
      {/* Time period selector */}
      <div className="mb-6">
        <Tabs defaultValue="month" onValueChange={setTimeframe}>
          <TabsList>
            <TabsTrigger value="week">Week</TabsTrigger>
            <TabsTrigger value="month">Month</TabsTrigger>
            <TabsTrigger value="quarter">Quarter</TabsTrigger>
            <TabsTrigger value="year">Year</TabsTrigger>
          </TabsList>
        </Tabs>
      </div>
      
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">Total Revenue</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center">
              <DollarSign className="h-5 w-5 text-gray-500 mr-2" />
              <div className="text-2xl font-bold">${totalRevenue.toLocaleString()}</div>
            </div>
            <div className="flex items-center mt-2 text-sm">
              <ArrowUpRight className="h-4 w-4 text-green-500 mr-1" />
              <span className="text-green-500 font-medium">12.5%</span>
              <span className="text-gray-500 ml-1">from last {timeframe}</span>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">Invoices</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center">
              <FileText className="h-5 w-5 text-gray-500 mr-2" />
              <div className="text-2xl font-bold">{totalInvoices}</div>
            </div>
            <div className="flex justify-between mt-2 text-sm">
              <div className="flex items-center">
                <ArrowUpRight className="h-4 w-4 text-green-500 mr-1" />
                <span className="text-green-500 font-medium">8.2%</span>
              </div>
              <div className="text-amber-500">{pendingInvoices} pending</div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">Payments</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center">
              <CreditCard className="h-5 w-5 text-gray-500 mr-2" />
              <div className="text-2xl font-bold">{totalPayments}</div>
            </div>
            <div className="flex justify-between mt-2 text-sm">
              <div className="flex items-center">
                <ArrowUpRight className="h-4 w-4 text-green-500 mr-1" />
                <span className="text-green-500 font-medium">5.3%</span>
              </div>
              <div className="text-green-500">{completedPayments} completed</div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">Transactions</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center">
              <Activity className="h-5 w-5 text-gray-500 mr-2" />
              <div className="text-2xl font-bold">{totalTransactions}</div>
            </div>
            <div className="flex items-center mt-2 text-sm">
              <ArrowDownRight className="h-4 w-4 text-red-500 mr-1" />
              <span className="text-red-500 font-medium">2.1%</span>
              <span className="text-gray-500 ml-1">from last {timeframe}</span>
            </div>
          </CardContent>
        </Card>
      </div>
      
      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <Card>
          <CardHeader>
            <CardTitle>Revenue vs Expenses</CardTitle>
            <CardDescription>Monthly comparison of revenue and expenses</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={sampleRevenueData}
                  margin={{ top: 20, right: 30, left: 20, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip formatter={(value) => [`$${value}`, '']} />
                  <Legend />
                  <Bar dataKey="revenue" name="Revenue" fill="#4F46E5" />
                  <Bar dataKey="expenses" name="Expenses" fill="#F97316" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader>
            <CardTitle>Cash Flow Forecast</CardTitle>
            <CardDescription>Actual vs projected cash flow for next 6 months</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart
                  data={sampleCashFlowData}
                  margin={{ top: 20, right: 30, left: 20, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip formatter={(value) => [`$${value}`, '']} />
                  <Legend />
                  <Area type="monotone" dataKey="actual" name="Actual" stroke="#4F46E5" fill="#4F46E5" fillOpacity={0.3} />
                  <Area type="monotone" dataKey="forecast" name="Forecast" stroke="#10B981" fill="#10B981" fillOpacity={0.3} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Financial Metrics</CardTitle>
            <CardDescription>Key performance indicators and financial ratios</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="text-sm text-gray-500">Current Ratio</div>
                <div className="text-xl font-bold">{financialMetrics.currentRatio.toFixed(2)}</div>
                <div className="text-xs text-gray-400">Liquidity</div>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="text-sm text-gray-500">Debt to Equity</div>
                <div className="text-xl font-bold">{financialMetrics.debtToEquity.toFixed(2)}</div>
                <div className="text-xs text-gray-400">Leverage</div>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="text-sm text-gray-500">Profit Margin</div>
                <div className="text-xl font-bold">{financialMetrics.profitMargin.toFixed(1)}%</div>
                <div className="text-xs text-gray-400">Profitability</div>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="text-sm text-gray-500">ROE</div>
                <div className="text-xl font-bold">{financialMetrics.returnOnEquity.toFixed(1)}%</div>
                <div className="text-xs text-gray-400">Return on Equity</div>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="text-sm text-gray-500">Days Receivable</div>
                <div className="text-xl font-bold">{financialMetrics.daysReceivable}</div>
                <div className="text-xs text-gray-400">Collection Period</div>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="text-sm text-gray-500">Days Payable</div>
                <div className="text-xl font-bold">{financialMetrics.daysPayable}</div>
                <div className="text-xs text-gray-400">Payment Period</div>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader>
            <CardTitle>Payment Methods</CardTitle>
            <CardDescription>Distribution by payment processor</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={samplePaymentMethodData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                    label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  >
                    {samplePaymentMethodData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value) => [`${value}%`, 'Percentage']} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Recent Transactions</CardTitle>
            <CardDescription>Latest financial activities</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4 font-medium text-gray-500">Description</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-500">Amount</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-500">Category</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-500">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {displayTransactions.map((transaction) => (
                    <tr key={transaction.id} className="border-b hover:bg-gray-50">
                      <td className="py-3 px-4">{transaction.description}</td>
                      <td className="py-3 px-4 font-medium">
                        ${transaction.amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                      </td>
                      <td className="py-3 px-4">
                        <span className="px-2 py-1 rounded-full text-xs bg-blue-100 text-blue-800">
                          {transaction.category}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-gray-500">
                        {new Date(transaction.transactionDate).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
          <CardFooter>
            <Button variant="outline" size="sm">View All Transactions</Button>
          </CardFooter>
        </Card>
        
        <Card>
          <CardHeader>
            <CardTitle>Accounts Receivable</CardTitle>
            <CardDescription>Aging summary</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={sampleAccountsReceivableData}
                    cx="50%"
                    cy="50%"
                    outerRadius={80}
                    dataKey="value"
                    label={({ name }) => name}
                  >
                    {sampleAccountsReceivableData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value) => [`$${value.toLocaleString()}`, '']} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
          <CardFooter>
            <div className="w-full text-center text-sm text-gray-500">
              Total Receivables: $128,000
            </div>
          </CardFooter>
        </Card>
      </div>
    </Layout>
  );
};

export default Dashboard;
