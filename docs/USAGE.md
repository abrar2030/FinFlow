# Usage Guide

This guide demonstrates common usage patterns for FinFlow, including CLI commands and programmatic API usage.

---

## Table of Contents

- [Quick Start Examples](#quick-start-examples)
- [CLI Usage](#cli-usage)
- [Library/API Usage](#libraryapi-usage)
- [Common Workflows](#common-workflows)
- [Authentication Patterns](#authentication-patterns)
- [Best Practices](#best-practices)

---

## Quick Start Examples

### Example 1: Process a Payment

**CLI:**

```bash
# Start development environment
./scripts/finflow-dev.sh --action start

# Process a payment using REST API
curl -X POST http://localhost:3002/api/payments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "amount": 150.00,
    "currency": "usd",
    "processorType": "stripe",
    "source": "tok_visa",
    "description": "Order #12345",
    "metadata": {
      "orderId": "12345",
      "customerId": "cust_abc123"
    }
  }'
```

**Library (Node.js):**

```javascript
const axios = require("axios");

async function processPayment() {
  const response = await axios.post(
    "http://localhost:3002/api/payments",
    {
      amount: 150.0,
      currency: "usd",
      processorType: "stripe",
      source: "tok_visa",
      description: "Order #12345",
      metadata: {
        orderId: "12345",
        customerId: "cust_abc123",
      },
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.JWT_TOKEN}`,
        "Content-Type": "application/json",
      },
    },
  );

  console.log("Payment processed:", response.data);
  return response.data;
}
```

**Library (Python):**

```python
import requests
import os

def process_payment():
    url = 'http://localhost:3002/api/payments'
    headers = {
        'Authorization': f'Bearer {os.getenv("JWT_TOKEN")}',
        'Content-Type': 'application/json'
    }
    data = {
        'amount': 150.00,
        'currency': 'usd',
        'processorType': 'stripe',
        'source': 'tok_visa',
        'description': 'Order #12345',
        'metadata': {
            'orderId': '12345',
            'customerId': 'cust_abc123'
        }
    }

    response = requests.post(url, json=data, headers=headers)
    response.raise_for_status()
    print('Payment processed:', response.json())
    return response.json()
```

---

### Example 2: Create Journal Entry (Accounting)

**CLI:**

```bash
curl -X POST http://localhost:3003/api/journal-entries \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "date": "2025-01-15",
    "description": "Sale of services",
    "entries": [
      {
        "accountCode": "1100",
        "accountName": "Accounts Receivable",
        "debit": 1000.00,
        "credit": 0
      },
      {
        "accountCode": "4000",
        "accountName": "Sales Revenue",
        "debit": 0,
        "credit": 1000.00
      }
    ]
  }'
```

**Library (TypeScript):**

```typescript
import axios from "axios";

interface JournalEntryLine {
  accountCode: string;
  accountName: string;
  debit: number;
  credit: number;
}

interface JournalEntry {
  date: string;
  description: string;
  entries: JournalEntryLine[];
}

async function createJournalEntry(entry: JournalEntry) {
  const response = await axios.post(
    "http://localhost:3003/api/journal-entries",
    entry,
    {
      headers: {
        Authorization: `Bearer ${process.env.JWT_TOKEN}`,
        "Content-Type": "application/json",
      },
    },
  );

  console.log("Journal entry created:", response.data);
  return response.data;
}

// Usage
createJournalEntry({
  date: "2025-01-15",
  description: "Sale of services",
  entries: [
    {
      accountCode: "1100",
      accountName: "Accounts Receivable",
      debit: 1000,
      credit: 0,
    },
    {
      accountCode: "4000",
      accountName: "Sales Revenue",
      debit: 0,
      credit: 1000,
    },
  ],
});
```

---

### Example 3: Calculate Credit Score

**CLI:**

```bash
curl -X POST http://localhost:3005/api/credit/score \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "income": 75000,
    "numInvoices": 45,
    "avgCashflow": 5000,
    "delinquencies": 0
  }'
```

**Library (Python):**

```python
import requests
import os

def calculate_credit_score(income, num_invoices, avg_cashflow, delinquencies):
    url = 'http://localhost:3005/api/credit/score'
    headers = {
        'Authorization': f'Bearer {os.getenv("JWT_TOKEN")}',
        'Content-Type': 'application/json'
    }
    data = {
        'income': income,
        'numInvoices': num_invoices,
        'avgCashflow': avg_cashflow,
        'delinquencies': delinquencies
    }

    response = requests.post(url, json=data, headers=headers)
    response.raise_for_status()
    result = response.json()

    print(f"Credit Score: {result['credit_score']:.2f}")
    print(f"Risk Category: {result['risk_category']}")

    return result

# Usage
score = calculate_credit_score(
    income=75000,
    num_invoices=45,
    avg_cashflow=5000,
    delinquencies=0
)
```

---

## CLI Usage

### Development Scripts

FinFlow includes comprehensive CLI scripts for development and operations.

#### Start Development Environment

```bash
# Start all services
./scripts/finflow-dev.sh --action start

# Start specific services
./scripts/finflow-dev.sh --action start --services auth-service,payments-service

# Start with debug mode
./scripts/finflow-dev.sh --action start --debug

# Check service status
./scripts/finflow-dev.sh --action status
```

#### Run Tests

```bash
# Run all tests
./scripts/finflow-test-runner.sh --type all

# Run unit tests only
./scripts/finflow-test-runner.sh --type unit

# Run tests for specific services
./scripts/finflow-test-runner.sh --services auth-service,payments-service

# Run with coverage report
./scripts/finflow-test-runner.sh --coverage --report html
```

#### Database Management

```bash
# Run migrations
./scripts/finflow-db.sh --action migrate --environment development

# Seed development data
./scripts/finflow-db.sh --action seed --environment development

# Create backup
./scripts/finflow-db.sh --action backup --environment production

# Restore from backup
./scripts/finflow-db.sh --action restore --backup-name backup-2025-01-15

# Check database health
./scripts/finflow-db.sh --action health
```

#### Code Quality

```bash
# Run linting
./scripts/finflow-quality.sh --mode check

# Auto-fix issues
./scripts/finflow-quality.sh --mode fix

# Install pre-commit hooks
./scripts/finflow-quality.sh --install-hooks

# Run vulnerability scan
./scripts/finflow-quality.sh --vulnerability-scan

# Generate quality report
./scripts/finflow-quality.sh --report
```

#### Deployment

```bash
# Deploy to staging
./scripts/finflow-deploy.sh --environment staging

# Deploy specific services
./scripts/finflow-deploy.sh --environment production --services payments-service

# Deploy with tests
./scripts/finflow-deploy.sh --environment production

# Rollback deployment
./scripts/finflow-deploy.sh --rollback --environment production

# Blue-green deployment
./scripts/finflow-deploy.sh --blue-green --environment production
```

#### Monitoring

```bash
# Setup monitoring stack
./scripts/finflow-monitor.sh --action setup

# Start monitoring
./scripts/finflow-monitor.sh --action start

# View monitoring status
./scripts/finflow-monitor.sh --action status

# Setup dashboards only
./scripts/finflow-monitor.sh --action setup --dashboard-only
```

---

## Library/API Usage

### Authentication

All API requests require authentication via JWT tokens.

#### Register User

```javascript
const axios = require("axios");

async function registerUser(email, password, name) {
  const response = await axios.post("http://localhost:3001/api/auth/register", {
    email,
    password,
    name,
  });

  return response.data; // Contains user data and JWT token
}
```

#### Login

```javascript
async function login(email, password) {
  const response = await axios.post("http://localhost:3001/api/auth/login", {
    email,
    password,
  });

  // Save token for subsequent requests
  const token = response.data.token;
  localStorage.setItem("jwt_token", token);

  return response.data;
}
```

#### Using Token in Requests

```javascript
const token = localStorage.getItem("jwt_token");

axios.defaults.headers.common["Authorization"] = `Bearer ${token}`;

// Now all requests include the token
const response = await axios.get(
  "http://localhost:3004/api/analytics/dashboard",
);
```

---

### Payment Operations

#### Create Payment

```typescript
interface CreatePaymentRequest {
  amount: number;
  currency: string;
  processorType: "stripe" | "paypal" | "square";
  source: string;
  description?: string;
  metadata?: Record<string, any>;
}

async function createPayment(payment: CreatePaymentRequest) {
  const response = await axios.post(
    "http://localhost:3002/api/payments",
    payment,
  );
  return response.data;
}
```

#### Get Payment Status

```javascript
async function getPaymentStatus(paymentId) {
  const response = await axios.get(
    `http://localhost:3002/api/payments/${paymentId}`,
  );
  return response.data;
}
```

#### Process Refund

```javascript
async function refundPayment(paymentId, amount) {
  const response = await axios.post(
    `http://localhost:3002/api/payments/${paymentId}/refund`,
    {
      amount,
    },
  );
  return response.data;
}
```

---

### Accounting Operations

#### Create Invoice

```typescript
interface InvoiceItem {
  description: string;
  quantity: number;
  unitPrice: number;
  amount: number;
}

interface CreateInvoiceRequest {
  invoiceNumber: string;
  customerId: string;
  customerName: string;
  date: string;
  dueDate: string;
  items: InvoiceItem[];
  subtotal: number;
  tax: number;
  total: number;
}

async function createInvoice(invoice: CreateInvoiceRequest) {
  const response = await axios.post(
    "http://localhost:3003/api/invoices",
    invoice,
  );
  return response.data;
}
```

#### Generate Financial Report

```javascript
async function generateBalanceSheet(startDate, endDate) {
  const response = await axios.get(
    "http://localhost:3003/api/reports/balance-sheet",
    {
      params: { startDate, endDate },
    },
  );
  return response.data;
}

async function generateIncomeStatement(startDate, endDate) {
  const response = await axios.get(
    "http://localhost:3003/api/reports/income-statement",
    {
      params: { startDate, endDate },
    },
  );
  return response.data;
}
```

---

### Analytics Operations

#### Get Dashboard Metrics

```javascript
async function getDashboardMetrics(timeRange = "30d") {
  const response = await axios.get(
    "http://localhost:3004/api/analytics/dashboard",
    {
      params: { timeRange },
    },
  );
  return response.data;
}
```

#### Cash Flow Forecast

```python
import requests

def get_cash_flow_forecast(months=12):
    url = 'http://localhost:3004/api/analytics/forecast'
    params = {'months': months}
    headers = {'Authorization': f'Bearer {token}'}

    response = requests.get(url, params=params, headers=headers)
    response.raise_for_status()
    return response.json()
```

---

## Common Workflows

### Workflow 1: Complete Payment Transaction

```javascript
async function completePaymentWorkflow(customerId, amount, items) {
  try {
    // 1. Create invoice
    const invoice = await createInvoice({
      customerId,
      items,
      total: amount,
      // ... other invoice details
    });

    // 2. Process payment
    const payment = await createPayment({
      amount: invoice.total,
      currency: "usd",
      processorType: "stripe",
      source: "tok_visa",
      metadata: { invoiceId: invoice.id },
    });

    // 3. Create accounting entries
    await createJournalEntry({
      date: new Date().toISOString(),
      description: `Payment for invoice ${invoice.invoiceNumber}`,
      entries: [
        { accountCode: "1000", accountName: "Cash", debit: amount, credit: 0 },
        {
          accountCode: "1100",
          accountName: "Accounts Receivable",
          debit: 0,
          credit: amount,
        },
      ],
    });

    console.log("Payment workflow completed successfully");
    return { invoice, payment };
  } catch (error) {
    console.error("Payment workflow failed:", error);
    throw error;
  }
}
```

### Workflow 2: Credit Application

```python
async def process_credit_application(applicant_data):
    """Complete credit application workflow"""

    # 1. Calculate credit score
    score_result = await calculate_credit_score(
        income=applicant_data['income'],
        num_invoices=applicant_data['num_invoices'],
        avg_cashflow=applicant_data['avg_cashflow'],
        delinquencies=applicant_data['delinquencies']
    )

    # 2. Generate loan offer if approved
    if score_result['risk_category'] in ['LOW_RISK', 'MEDIUM_RISK']:
        loan_offer = await generate_loan_offer(
            applicant_id=applicant_data['id'],
            credit_score=score_result['credit_score']
        )
        return {'approved': True, 'offer': loan_offer}

    return {'approved': False, 'reason': 'High risk'}
```

---

## Authentication Patterns

### Pattern 1: Token Management

```javascript
class AuthManager {
  constructor() {
    this.token = null;
    this.refreshToken = null;
  }

  async login(email, password) {
    const response = await axios.post("/api/auth/login", { email, password });
    this.token = response.data.token;
    this.refreshToken = response.data.refreshToken;
    this.setAuthHeader();
  }

  setAuthHeader() {
    axios.defaults.headers.common["Authorization"] = `Bearer ${this.token}`;
  }

  async refreshAccessToken() {
    const response = await axios.post("/api/auth/refresh", {
      refreshToken: this.refreshToken,
    });
    this.token = response.data.token;
    this.setAuthHeader();
  }

  logout() {
    this.token = null;
    this.refreshToken = null;
    delete axios.defaults.headers.common["Authorization"];
  }
}
```

### Pattern 2: Multi-Factor Authentication

```javascript
async function loginWithMFA(email, password) {
  // Step 1: Initial login
  const response = await axios.post("/api/auth/login", { email, password });

  if (response.data.mfaRequired) {
    // Step 2: Get MFA code from user
    const mfaCode = await promptForMFACode();

    // Step 3: Verify MFA
    const mfaResponse = await axios.post("/api/auth/verify-mfa", {
      sessionId: response.data.sessionId,
      code: mfaCode,
    });

    return mfaResponse.data;
  }

  return response.data;
}
```

---

## Best Practices

### Error Handling

```javascript
async function makeAPICall(url, data) {
  try {
    const response = await axios.post(url, data);
    return { success: true, data: response.data };
  } catch (error) {
    if (error.response) {
      // Server responded with error
      console.error("API Error:", error.response.data);
      return { success: false, error: error.response.data };
    } else if (error.request) {
      // No response received
      console.error("Network Error:", error.message);
      return { success: false, error: "Network error" };
    } else {
      // Other errors
      console.error("Error:", error.message);
      return { success: false, error: error.message };
    }
  }
}
```

### Rate Limiting

```javascript
// Implement exponential backoff for rate-limited requests
async function retryWithBackoff(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.response?.status === 429 && i < maxRetries - 1) {
        const delay = Math.pow(2, i) * 1000;
        console.log(`Rate limited. Retrying in ${delay}ms...`);
        await new Promise((resolve) => setTimeout(resolve, delay));
      } else {
        throw error;
      }
    }
  }
}
```

### Logging

```javascript
const winston = require("winston");

const logger = winston.createLogger({
  level: "info",
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: "error.log", level: "error" }),
    new winston.transports.File({ filename: "combined.log" }),
  ],
});

// Use in API calls
async function processPayment(data) {
  logger.info("Processing payment", { data });
  try {
    const result = await createPayment(data);
    logger.info("Payment processed successfully", { paymentId: result.id });
    return result;
  } catch (error) {
    logger.error("Payment processing failed", { error: error.message, data });
    throw error;
  }
}
```

---

## Next Steps

- **Explore Examples**: See [examples/](examples/) for detailed tutorials
- **API Reference**: See [API.md](API.md) for complete endpoint documentation
- **CLI Reference**: See [CLI.md](CLI.md) for all available commands
