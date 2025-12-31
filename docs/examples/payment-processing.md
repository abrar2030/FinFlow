# Payment Processing Example

Complete example of processing payments using FinFlow.

---

## Overview

This example demonstrates how to:

1. Create a payment using Stripe
2. Handle payment success/failure
3. Create accounting entries
4. Query payment status

---

## Prerequisites

- FinFlow services running
- Valid JWT token
- Stripe API keys configured

---

## Step 1: Authenticate

```javascript
const axios = require("axios");

// Login to get JWT token
const login = async () => {
  const response = await axios.post("http://localhost:3001/api/auth/login", {
    email: "user@example.com",
    password: "password123",
  });

  return response.data.token;
};

const token = await login();
```

---

## Step 2: Create Payment

```javascript
const createPayment = async (token) => {
  const paymentData = {
    amount: 10000, // $100.00 in cents
    currency: "usd",
    processorType: "stripe",
    source: "tok_visa", // Test token
    description: "Order #12345",
    metadata: {
      orderId: "12345",
      customerId: "cust_abc123",
    },
  };

  try {
    const response = await axios.post(
      "http://localhost:3002/api/payments",
      paymentData,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      },
    );

    console.log("Payment created:", response.data);
    return response.data;
  } catch (error) {
    console.error("Payment failed:", error.response.data);
    throw error;
  }
};
```

---

## Step 3: Handle Payment Result

```javascript
const handlePayment = async (payment) => {
  if (payment.status === "succeeded") {
    console.log("✓ Payment successful");
    console.log("Transaction ID:", payment.processorTransactionId);

    // Create accounting entry
    await createAccountingEntry(payment);
  } else if (payment.status === "failed") {
    console.error("✗ Payment failed");
    console.error("Error:", payment.error);
  }
};
```

---

## Step 4: Create Accounting Entry

```javascript
const createAccountingEntry = async (payment) => {
  const journalEntry = {
    date: new Date().toISOString().split("T")[0],
    description: `Payment received for ${payment.description}`,
    entries: [
      {
        accountCode: "1000",
        accountName: "Cash",
        debit: payment.amount / 100,
        credit: 0,
      },
      {
        accountCode: "1100",
        accountName: "Accounts Receivable",
        debit: 0,
        credit: payment.amount / 100,
      },
    ],
  };

  const response = await axios.post(
    "http://localhost:3003/api/journal-entries",
    journalEntry,
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  );

  console.log("Accounting entry created:", response.data);
};
```

---

## Step 5: Query Payment Status

```javascript
const getPaymentStatus = async (paymentId) => {
  const response = await axios.get(
    `http://localhost:3002/api/payments/${paymentId}`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  );

  return response.data;
};

// Usage
const status = await getPaymentStatus(payment.id);
console.log("Current status:", status.status);
```

---

## Complete Example

```javascript
const processPayment = async () => {
  try {
    // 1. Login
    const token = await login();

    // 2. Create payment
    const payment = await createPayment(token);

    // 3. Handle result
    await handlePayment(payment);

    // 4. Check status
    const status = await getPaymentStatus(payment.id);
    console.log("Final status:", status);
  } catch (error) {
    console.error("Error processing payment:", error.message);
  }
};

processPayment();
```

---

## Expected Output

```
Payment created: {
  id: 'payment-uuid-123',
  amount: 10000,
  currency: 'usd',
  status: 'succeeded',
  processorType: 'stripe',
  processorTransactionId: 'ch_3abc123...',
  createdAt: '2025-01-20T15:30:00Z'
}
✓ Payment successful
Transaction ID: ch_3abc123...
Accounting entry created: {
  id: 'journal-entry-uuid',
  date: '2025-01-20',
  status: 'posted'
}
Current status: succeeded
```

---

## Error Handling

```javascript
try {
  const payment = await createPayment(token);
} catch (error) {
  if (error.response) {
    // Server responded with error
    console.error("Status:", error.response.status);
    console.error("Error:", error.response.data.error);

    if (error.response.status === 401) {
      console.log("Token expired, refreshing...");
      // Refresh token and retry
    } else if (error.response.status === 400) {
      console.log("Invalid payment data");
    }
  } else if (error.request) {
    // No response received
    console.error("Network error:", error.message);
  }
}
```

---

## See Also

- [API Documentation](../API.md#payments-service-api)
- [Configuration Guide](../CONFIGURATION.md#payments-service-configuration)
- [Troubleshooting](../TROUBLESHOOTING.md#payment-processing-issues)
