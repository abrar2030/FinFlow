# Accounting Workflows Example

Complete accounting workflow examples using FinFlow.

---

## Workflow 1: Create and Pay Invoice

### Step 1: Create Invoice

```javascript
const createInvoice = async () => {
  const invoice = {
    invoiceNumber: "INV-2025-001",
    customerId: "cust-uuid-123",
    customerName: "Acme Corporation",
    date: "2025-01-20",
    dueDate: "2025-02-20",
    items: [
      {
        description: "Consulting Services - January",
        quantity: 40,
        unitPrice: 150.0,
        amount: 6000.0,
      },
      {
        description: "Software License",
        quantity: 1,
        unitPrice: 500.0,
        amount: 500.0,
      },
    ],
    subtotal: 6500.0,
    tax: 650.0,
    total: 7150.0,
  };

  const response = await axios.post(
    "http://localhost:3003/api/invoices",
    invoice,
    {
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  console.log("Invoice created:", response.data);
  return response.data;
};
```

### Step 2: Record Payment

```javascript
const recordPayment = async (invoiceId, amount) => {
  // Create journal entry for payment received
  const journalEntry = {
    date: new Date().toISOString().split("T")[0],
    description: `Payment received for invoice ${invoiceId}`,
    entries: [
      {
        accountCode: "1000",
        accountName: "Cash",
        debit: amount,
        credit: 0,
      },
      {
        accountCode: "1100",
        accountName: "Accounts Receivable",
        debit: 0,
        credit: amount,
      },
    ],
  };

  const response = await axios.post(
    "http://localhost:3003/api/journal-entries",
    journalEntry,
    {
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  console.log("Payment recorded:", response.data);
};
```

---

## Workflow 2: Monthly Closing

### Generate Financial Reports

```javascript
const monthlyClosing = async (month, year) => {
  const startDate = `${year}-${month.toString().padStart(2, "0")}-01`;
  const endDate = `${year}-${month.toString().padStart(2, "0")}-31`;

  // Balance Sheet
  const balanceSheet = await axios.get(
    "http://localhost:3003/api/reports/balance-sheet",
    {
      params: { startDate, endDate },
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  // Income Statement
  const incomeStatement = await axios.get(
    "http://localhost:3003/api/reports/income-statement",
    {
      params: { startDate, endDate },
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  // Cash Flow Statement
  const cashFlow = await axios.get(
    "http://localhost:3003/api/reports/cash-flow",
    {
      params: { startDate, endDate },
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  return {
    balanceSheet: balanceSheet.data,
    incomeStatement: incomeStatement.data,
    cashFlow: cashFlow.data,
  };
};

// Generate reports for January 2025
const reports = await monthlyClosing(1, 2025);
console.log("Balance Sheet:", reports.balanceSheet);
console.log("Income Statement:", reports.incomeStatement);
```

---

## Workflow 3: Expense Recording

```javascript
const recordExpense = async (expense) => {
  const journalEntry = {
    date: expense.date,
    description: expense.description,
    entries: [
      {
        accountCode: expense.expenseAccount,
        accountName: expense.expenseAccountName,
        debit: expense.amount,
        credit: 0,
      },
      {
        accountCode: "1000",
        accountName: "Cash",
        debit: 0,
        credit: expense.amount,
      },
    ],
  };

  const response = await axios.post(
    "http://localhost:3003/api/journal-entries",
    journalEntry,
    {
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  console.log("Expense recorded:", response.data);
};

// Example: Record office rent
await recordExpense({
  date: "2025-01-01",
  description: "Office rent - January 2025",
  amount: 2000.0,
  expenseAccount: "5100",
  expenseAccountName: "Rent Expense",
});
```

---

For more examples, see [Usage Guide](../USAGE.md).
