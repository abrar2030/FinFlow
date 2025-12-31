# API Reference

Complete REST API documentation for all FinFlow services.

---

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Auth Service API](#auth-service-api)
- [Payments Service API](#payments-service-api)
- [Accounting Service API](#accounting-service-api)
- [Analytics Service API](#analytics-service-api)
- [Credit Engine API](#credit-engine-api)
- [Common Patterns](#common-patterns)

---

## Overview

FinFlow exposes RESTful APIs for all services. All APIs follow these conventions:

- **Base URL**: `http://localhost:8080/api` (via API Gateway)
- **Content-Type**: `application/json`
- **Authentication**: Bearer token in `Authorization` header
- **Rate Limiting**: 100 requests per minute per IP
- **Versioning**: URLs may include version (`/v1/`)

### Service Ports (Direct Access)

| Service                 | Port | Base URL                  | Swagger Docs                   |
| ----------------------- | ---- | ------------------------- | ------------------------------ |
| **Auth Service**        | 3001 | http://localhost:3001/api | http://localhost:3001/api-docs |
| **Payments Service**    | 3002 | http://localhost:3002/api | http://localhost:3002/api-docs |
| **Accounting Service**  | 3003 | http://localhost:3003/api | http://localhost:3003/api-docs |
| **Analytics Service**   | 3004 | http://localhost:3004/api | http://localhost:3004/api-docs |
| **Credit Engine**       | 3005 | http://localhost:3005/api | http://localhost:3005/docs     |
| **Transaction Service** | 3006 | http://localhost:3006/api | http://localhost:3006/docs     |

---

## Authentication

All API endpoints (except registration and login) require a valid JWT token.

### Obtaining a Token

```bash
# Register new user
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!",
    "name": "John Doe"
  }'

# Login to get token
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }'
```

### Using the Token

```bash
curl -X GET http://localhost:3004/api/analytics/dashboard \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Auth Service API

Base URL: `/api/auth`

### POST /register

Register a new user account.

| Parameter  | Type   | Required? | Default | Description                                              | Example            |
| ---------- | ------ | --------- | ------- | -------------------------------------------------------- | ------------------ |
| `email`    | string | Yes       | -       | User email address                                       | `user@example.com` |
| `password` | string | Yes       | -       | Password (min 8 chars, 1 uppercase, 1 number, 1 special) | `SecurePass123!`   |
| `name`     | string | Yes       | -       | Full name                                                | `John Doe`         |
| `phone`    | string | No        | -       | Phone number                                             | `+1234567890`      |

**Request Example:**

```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "John Doe",
  "phone": "+1234567890"
}
```

**Response Example (200 OK):**

```json
{
  "user": {
    "id": "uuid-string",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "2025-01-15T10:30:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh-token-string"
}
```

---

### POST /login

Authenticate user and receive JWT token.

| Parameter  | Type   | Required? | Default | Description   | Example            |
| ---------- | ------ | --------- | ------- | ------------- | ------------------ |
| `email`    | string | Yes       | -       | User email    | `user@example.com` |
| `password` | string | Yes       | -       | User password | `SecurePass123!`   |

**Request Example:**

```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response Example (200 OK):**

```json
{
  "user": {
    "id": "uuid-string",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh-token-string",
  "expiresIn": "24h"
}
```

---

### GET /me

Get current authenticated user information.

**Headers:**

- `Authorization: Bearer <token>`

**Response Example (200 OK):**

```json
{
  "id": "uuid-string",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "user",
  "createdAt": "2025-01-15T10:30:00Z",
  "lastLogin": "2025-01-20T14:20:00Z"
}
```

---

### POST /refresh

Refresh access token using refresh token.

| Parameter      | Type   | Required? | Default | Description         | Example                |
| -------------- | ------ | --------- | ------- | ------------------- | ---------------------- |
| `refreshToken` | string | Yes       | -       | Valid refresh token | `refresh-token-string` |

**Response Example (200 OK):**

```json
{
  "token": "new-jwt-token",
  "expiresIn": "24h"
}
```

---

### POST /logout

Logout user and invalidate tokens.

**Headers:**

- `Authorization: Bearer <token>`

**Response Example (200 OK):**

```json
{
  "message": "Logged out successfully"
}
```

---

## Payments Service API

Base URL: `/api/payments`

### POST /payments

Create a new payment.

| Parameter       | Type   | Required? | Default | Description                                      | Example                |
| --------------- | ------ | --------- | ------- | ------------------------------------------------ | ---------------------- |
| `amount`        | number | Yes       | -       | Payment amount (in smallest currency unit)       | `10000` (=$100.00)     |
| `currency`      | string | Yes       | -       | ISO currency code                                | `usd`                  |
| `processorType` | string | Yes       | -       | Payment processor (`stripe`, `paypal`, `square`) | `stripe`               |
| `source`        | string | Yes       | -       | Payment source/token                             | `tok_visa`             |
| `description`   | string | No        | -       | Payment description                              | `Order #12345`         |
| `metadata`      | object | No        | `{}`    | Additional metadata                              | `{"orderId": "12345"}` |

**Request Example:**

```json
{
  "amount": 10000,
  "currency": "usd",
  "processorType": "stripe",
  "source": "tok_visa",
  "description": "Order #12345",
  "metadata": {
    "orderId": "12345",
    "customerId": "cust_abc123"
  }
}
```

**Response Example (200 OK):**

```json
{
  "id": "payment-uuid",
  "amount": 10000,
  "currency": "usd",
  "status": "succeeded",
  "processorType": "stripe",
  "processorTransactionId": "ch_stripe_transaction_id",
  "createdAt": "2025-01-20T15:30:00Z",
  "metadata": {
    "orderId": "12345",
    "customerId": "cust_abc123"
  }
}
```

---

### GET /payments/:id

Get payment details by ID.

**Path Parameters:**

- `id` (string): Payment UUID

**Response Example (200 OK):**

```json
{
  "id": "payment-uuid",
  "amount": 10000,
  "currency": "usd",
  "status": "succeeded",
  "processorType": "stripe",
  "description": "Order #12345",
  "createdAt": "2025-01-20T15:30:00Z",
  "updatedAt": "2025-01-20T15:30:05Z"
}
```

---

### POST /payments/:id/refund

Refund a payment.

| Parameter | Type   | Required? | Default     | Description   | Example            |
| --------- | ------ | --------- | ----------- | ------------- | ------------------ |
| `amount`  | number | No        | Full amount | Refund amount | `5000`             |
| `reason`  | string | No        | -           | Refund reason | `Customer request` |

**Response Example (200 OK):**

```json
{
  "refundId": "refund-uuid",
  "paymentId": "payment-uuid",
  "amount": 5000,
  "status": "succeeded",
  "createdAt": "2025-01-20T16:00:00Z"
}
```

---

## Accounting Service API

Base URL: `/api/accounting`

### POST /invoices

Create a new invoice.

| Parameter       | Type   | Required? | Default | Description             | Example        |
| --------------- | ------ | --------- | ------- | ----------------------- | -------------- |
| `invoiceNumber` | string | Yes       | -       | Unique invoice number   | `INV-2025-001` |
| `customerId`    | string | Yes       | -       | Customer ID             | `cust-uuid`    |
| `customerName`  | string | Yes       | -       | Customer name           | `Acme Corp`    |
| `date`          | string | Yes       | -       | Invoice date (ISO 8601) | `2025-01-20`   |
| `dueDate`       | string | Yes       | -       | Payment due date        | `2025-02-20`   |
| `items`         | array  | Yes       | -       | Invoice line items      | See example    |
| `subtotal`      | number | Yes       | -       | Subtotal amount         | `1000.00`      |
| `tax`           | number | Yes       | -       | Tax amount              | `100.00`       |
| `total`         | number | Yes       | -       | Total amount            | `1100.00`      |

**Request Example:**

```json
{
  "invoiceNumber": "INV-2025-001",
  "customerId": "cust-uuid",
  "customerName": "Acme Corp",
  "date": "2025-01-20",
  "dueDate": "2025-02-20",
  "items": [
    {
      "description": "Consulting Services",
      "quantity": 10,
      "unitPrice": 100.0,
      "amount": 1000.0
    }
  ],
  "subtotal": 1000.0,
  "tax": 100.0,
  "total": 1100.0
}
```

**Response Example (200 OK):**

```json
{
  "id": "invoice-uuid",
  "invoiceNumber": "INV-2025-001",
  "status": "draft",
  "total": 1100.0,
  "createdAt": "2025-01-20T10:00:00Z"
}
```

---

### POST /journal-entries

Create double-entry journal entry.

| Parameter     | Type   | Required? | Default | Description                         | Example            |
| ------------- | ------ | --------- | ------- | ----------------------------------- | ------------------ |
| `date`        | string | Yes       | -       | Entry date (ISO 8601)               | `2025-01-20`       |
| `description` | string | Yes       | -       | Entry description                   | `Sale of services` |
| `entries`     | array  | Yes       | -       | Debit/credit entries (must balance) | See example        |

**Request Example:**

```json
{
  "date": "2025-01-20",
  "description": "Sale of services",
  "entries": [
    {
      "accountCode": "1100",
      "accountName": "Accounts Receivable",
      "debit": 1000.0,
      "credit": 0
    },
    {
      "accountCode": "4000",
      "accountName": "Sales Revenue",
      "debit": 0,
      "credit": 1000.0
    }
  ]
}
```

**Response Example (200 OK):**

```json
{
  "id": "journal-entry-uuid",
  "date": "2025-01-20",
  "status": "posted",
  "totalDebit": 1000.0,
  "totalCredit": 1000.0,
  "createdAt": "2025-01-20T11:00:00Z"
}
```

---

### GET /reports/balance-sheet

Generate balance sheet report.

**Query Parameters:**

| Parameter   | Type   | Required? | Default       | Description       | Example      |
| ----------- | ------ | --------- | ------------- | ----------------- | ------------ |
| `startDate` | string | No        | First of year | Report start date | `2025-01-01` |
| `endDate`   | string | No        | Today         | Report end date   | `2025-12-31` |

**Response Example (200 OK):**

```json
{
  "reportDate": "2025-12-31",
  "assets": {
    "currentAssets": {
      "cash": 50000.0,
      "accountsReceivable": 25000.0,
      "total": 75000.0
    },
    "fixedAssets": {
      "equipment": 30000.0,
      "total": 30000.0
    },
    "totalAssets": 105000.0
  },
  "liabilities": {
    "currentLiabilities": {
      "accountsPayable": 15000.0,
      "total": 15000.0
    },
    "totalLiabilities": 15000.0
  },
  "equity": {
    "retainedEarnings": 90000.0,
    "totalEquity": 90000.0
  }
}
```

---

## Analytics Service API

Base URL: `/api/analytics`

### GET /dashboard

Get dashboard metrics and KPIs.

**Query Parameters:**

| Parameter   | Type   | Required? | Default | Description                           | Example |
| ----------- | ------ | --------- | ------- | ------------------------------------- | ------- |
| `timeRange` | string | No        | `30d`   | Time range (`7d`, `30d`, `90d`, `1y`) | `30d`   |

**Response Example (200 OK):**

```json
{
  "period": "30d",
  "revenue": {
    "total": 125000.0,
    "change": 15.5,
    "trend": "up"
  },
  "expenses": {
    "total": 75000.0,
    "change": 8.2,
    "trend": "up"
  },
  "profit": {
    "total": 50000.0,
    "margin": 40.0
  },
  "transactions": {
    "count": 250,
    "avgValue": 500.0
  },
  "topCustomers": [
    {
      "id": "cust-uuid",
      "name": "Acme Corp",
      "revenue": 25000.0
    }
  ]
}
```

---

### GET /forecast

Get cash flow forecast.

**Query Parameters:**

| Parameter | Type   | Required? | Default | Description                  | Example |
| --------- | ------ | --------- | ------- | ---------------------------- | ------- |
| `months`  | number | No        | `12`    | Number of months to forecast | `12`    |

**Response Example (200 OK):**

```json
{
  "forecast": [
    {
      "month": "2025-02",
      "projected": 45000.0,
      "confidence": 0.85
    },
    {
      "month": "2025-03",
      "projected": 48000.0,
      "confidence": 0.82
    }
  ],
  "summary": {
    "avgMonthly": 46500.0,
    "trend": "increasing",
    "seasonalPattern": "detected"
  }
}
```

---

## Credit Engine API

Base URL: `/api/credit`

### POST /score

Calculate credit score.

| Parameter       | Type   | Required? | Default | Description               | Example |
| --------------- | ------ | --------- | ------- | ------------------------- | ------- |
| `income`        | number | Yes       | -       | Annual income             | `75000` |
| `numInvoices`   | number | Yes       | -       | Number of invoices        | `45`    |
| `avgCashflow`   | number | Yes       | -       | Average monthly cash flow | `5000`  |
| `delinquencies` | number | Yes       | -       | Number of delinquencies   | `0`     |

**Request Example:**

```json
{
  "income": 75000,
  "numInvoices": 45,
  "avgCashflow": 5000,
  "delinquencies": 0
}
```

**Response Example (200 OK):**

```json
{
  "credit_score": 0.78,
  "risk_category": "LOW_RISK",
  "timestamp": "2025-01-20T14:30:00Z",
  "factors": {
    "income_impact": 0.3,
    "invoice_history": 0.25,
    "cashflow_stability": 0.28,
    "delinquency_penalty": 0.0
  }
}
```

---

### POST /loan-offer

Generate loan offer based on credit assessment.

| Parameter         | Type   | Required? | Default | Description            | Example     |
| ----------------- | ------ | --------- | ------- | ---------------------- | ----------- |
| `applicantId`     | string | Yes       | -       | Applicant user ID      | `user-uuid` |
| `requestedAmount` | number | Yes       | -       | Requested loan amount  | `50000`     |
| `creditScore`     | number | Yes       | -       | Credit score (0.0-1.0) | `0.78`      |

**Response Example (200 OK):**

```json
{
  "approved": true,
  "offeredAmount": 50000,
  "interestRate": 5.5,
  "termMonths": 36,
  "monthlyPayment": 1506.85,
  "conditions": ["Proof of income required", "Personal guarantee"]
}
```

---

## Common Patterns

### Error Responses

All endpoints return consistent error format:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Invalid email format",
    "details": {
      "field": "email",
      "value": "invalid-email"
    }
  }
}
```

**Common Error Codes:**

| Code                  | HTTP Status | Description                       |
| --------------------- | ----------- | --------------------------------- |
| `INVALID_REQUEST`     | 400         | Request validation failed         |
| `UNAUTHORIZED`        | 401         | Missing or invalid authentication |
| `FORBIDDEN`           | 403         | Insufficient permissions          |
| `NOT_FOUND`           | 404         | Resource not found                |
| `CONFLICT`            | 409         | Resource already exists           |
| `RATE_LIMIT_EXCEEDED` | 429         | Too many requests                 |
| `INTERNAL_ERROR`      | 500         | Internal server error             |

---

### Pagination

List endpoints support pagination:

```bash
GET /api/payments?page=2&limit=50&sort=createdAt&order=desc
```

**Response includes:**

```json
{
  "data": [...],
  "pagination": {
    "page": 2,
    "limit": 50,
    "total": 250,
    "totalPages": 5,
    "hasNext": true,
    "hasPrevious": true
  }
}
```

---

### Filtering

Most list endpoints support filtering:

```bash
GET /api/payments?status=succeeded&startDate=2025-01-01&endDate=2025-01-31
```

---

### Webhooks

Services emit events that can be subscribed to via webhooks:

**Event Types:**

| Event               | Service    | Description                    |
| ------------------- | ---------- | ------------------------------ |
| `payment.created`   | Payments   | New payment created            |
| `payment.succeeded` | Payments   | Payment processed successfully |
| `payment.failed`    | Payments   | Payment processing failed      |
| `invoice.created`   | Accounting | New invoice created            |
| `invoice.paid`      | Accounting | Invoice marked as paid         |

**Webhook Payload Example:**

```json
{
  "event": "payment.succeeded",
  "timestamp": "2025-01-20T15:30:00Z",
  "data": {
    "id": "payment-uuid",
    "amount": 10000,
    "currency": "usd"
  }
}
```

---

For more examples, see:

- [Payment Processing Example](examples/payment-processing.md)
- [Accounting Workflows Example](examples/accounting-workflows.md)
- [Credit Scoring Example](examples/credit-scoring.md)
