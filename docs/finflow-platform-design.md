# FinFlow Platform - System Design Document

## Overview

FinFlow is an AI-powered financial operations platform built with a microservices architecture. This document outlines the detailed system design and project structure for implementing the platform according to the provided architecture specifications.

## System Architecture

The platform consists of the following main components:

1. **Frontend Application** (React + TypeScript)
2. **Authentication Service** (Node.js + Express)
3. **Payments Service** (Node.js + Express)
4. **Accounting Service** (Node.js + Express)
5. **AI Analytics Service** (Python + FastAPI)
6. **Kafka Event Streaming** for asynchronous communication
7. **PostgreSQL Databases** for each service

## Project Structure

```
finflow-platform/
├── docker-compose.yml
├── README.md
├── services/
│   ├── auth-service/
│   ├── payments-service/
│   ├── accounting-service/
│   ├── analytics-service/
│   └── kafka/
└── frontend/
```

## Detailed Component Design

### Frontend Application (React + TypeScript)

```
frontend/
├── public/
│   ├── index.html
│   ├── favicon.ico
│   └── assets/
├── src/
│   ├── components/
│   │   ├── common/
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── Modal.tsx
│   │   │   ├── Navbar.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── index.ts
│   │   ├── dashboard/
│   │   │   ├── DashboardHeader.tsx
│   │   │   ├── KPICard.tsx
│   │   │   ├── RevenueChart.tsx
│   │   │   ├── ExpenseChart.tsx
│   │   │   ├── CashFlowForecast.tsx
│   │   │   └── index.ts
│   │   ├── invoices/
│   │   │   ├── InvoiceForm.tsx
│   │   │   ├── InvoiceList.tsx
│   │   │   ├── InvoiceDetail.tsx
│   │   │   └── index.ts
│   │   ├── payments/
│   │   │   ├── PaymentForm.tsx
│   │   │   ├── PaymentList.tsx
│   │   │   ├── PaymentDetail.tsx
│   │   │   └── index.ts
│   │   └── analytics/
│   │       ├── CashFlowAnalytics.tsx
│   │       ├── ExpenseCategorization.tsx
│   │       └── index.ts
│   ├── pages/
│   │   ├── Login.tsx
│   │   ├── Register.tsx
│   │   ├── Dashboard.tsx
│   │   ├── Invoices.tsx
│   │   ├── Payments.tsx
│   │   ├── Analytics.tsx
│   │   ├── Settings.tsx
│   │   └── NotFound.tsx
│   ├── store/
│   │   ├── index.ts
│   │   ├── auth/
│   │   │   ├── authSlice.ts
│   │   │   └── authActions.ts
│   │   ├── invoices/
│   │   │   ├── invoiceSlice.ts
│   │   │   └── invoiceActions.ts
│   │   ├── payments/
│   │   │   ├── paymentSlice.ts
│   │   │   └── paymentActions.ts
│   │   └── analytics/
│   │       ├── analyticsSlice.ts
│   │       └── analyticsActions.ts
│   ├── services/
│   │   ├── api.ts
│   │   ├── authService.ts
│   │   ├── invoiceService.ts
│   │   ├── paymentService.ts
│   │   └── analyticsService.ts
│   ├── utils/
│   │   ├── formatters.ts
│   │   ├── validators.ts
│   │   └── helpers.ts
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useForm.ts
│   │   └── useApi.ts
│   ├── types/
│   │   ├── index.ts
│   │   ├── auth.types.ts
│   │   ├── invoice.types.ts
│   │   ├── payment.types.ts
│   │   └── analytics.types.ts
│   ├── App.tsx
│   ├── index.tsx
│   └── routes.tsx
├── .env.example
├── .env
├── package.json
├── tsconfig.json
├── tailwind.config.js
├── jest.config.js
├── .eslintrc.js
├── .prettierrc
├── README.md
└── Dockerfile
```

### Authentication Service (Node.js + Express)

```
services/auth-service/
├── src/
│   ├── config/
│   │   ├── index.ts
│   │   ├── database.ts
│   │   ├── kafka.ts
│   │   └── passport.ts
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   └── user.controller.ts
│   ├── middlewares/
│   │   ├── auth.middleware.ts
│   │   ├── error.middleware.ts
│   │   ├── validation.middleware.ts
│   │   └── logger.middleware.ts
│   ├── models/
│   │   └── user.model.ts
│   ├── routes/
│   │   ├── index.ts
│   │   ├── auth.routes.ts
│   │   └── user.routes.ts
│   ├── services/
│   │   ├── auth.service.ts
│   │   └── user.service.ts
│   ├── utils/
│   │   ├── jwt.utils.ts
│   │   ├── password.utils.ts
│   │   └── logger.ts
│   ├── validators/
│   │   ├── auth.validator.ts
│   │   └── user.validator.ts
│   ├── types/
│   │   ├── index.ts
│   │   ├── auth.types.ts
│   │   └── user.types.ts
│   ├── app.ts
│   └── server.ts
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed.ts
├── tests/
│   ├── unit/
│   │   ├── auth.test.ts
│   │   └── user.test.ts
│   └── integration/
│       ├── auth.test.ts
│       └── user.test.ts
├── openapi/
│   └── auth-service.yaml
├── .env.example
├── .env
├── package.json
├── tsconfig.json
├── jest.config.js
├── .eslintrc.js
├── .prettierrc
├── README.md
└── Dockerfile
```

### Payments Service (Node.js + Express)

```
services/payments-service/
├── src/
│   ├── config/
│   │   ├── index.ts
│   │   ├── database.ts
│   │   └── kafka.ts
│   ├── controllers/
│   │   └── payment.controller.ts
│   ├── middlewares/
│   │   ├── auth.middleware.ts
│   │   ├── error.middleware.ts
│   │   ├── validation.middleware.ts
│   │   └── logger.middleware.ts
│   ├── models/
│   │   └── payment.model.ts
│   ├── routes/
│   │   ├── index.ts
│   │   └── payment.routes.ts
│   ├── services/
│   │   ├── payment.service.ts
│   │   ├── stripe.service.ts
│   │   └── kafka.service.ts
│   ├── utils/
│   │   ├── encryption.utils.ts
│   │   └── logger.ts
│   ├── validators/
│   │   └── payment.validator.ts
│   ├── types/
│   │   ├── index.ts
│   │   └── payment.types.ts
│   ├── app.ts
│   └── server.ts
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed.ts
├── tests/
│   ├── unit/
│   │   └── payment.test.ts
│   └── integration/
│       └── payment.test.ts
├── openapi/
│   └── payments-service.yaml
├── .env.example
├── .env
├── package.json
├── tsconfig.json
├── jest.config.js
├── .eslintrc.js
├── .prettierrc
├── README.md
└── Dockerfile
```

### Accounting Service (Node.js + Express)

```
services/accounting-service/
├── src/
│   ├── config/
│   │   ├── index.ts
│   │   ├── database.ts
│   │   └── kafka.ts
│   ├── controllers/
│   │   ├── invoice.controller.ts
│   │   └── ledger.controller.ts
│   ├── middlewares/
│   │   ├── auth.middleware.ts
│   │   ├── error.middleware.ts
│   │   ├── validation.middleware.ts
│   │   └── logger.middleware.ts
│   ├── models/
│   │   ├── invoice.model.ts
│   │   └── ledger.model.ts
│   ├── routes/
│   │   ├── index.ts
│   │   ├── invoice.routes.ts
│   │   └── ledger.routes.ts
│   ├── services/
│   │   ├── invoice.service.ts
│   │   ├── ledger.service.ts
│   │   └── kafka.service.ts
│   ├── utils/
│   │   └── logger.ts
│   ├── validators/
│   │   ├── invoice.validator.ts
│   │   └── ledger.validator.ts
│   ├── types/
│   │   ├── index.ts
│   │   ├── invoice.types.ts
│   │   └── ledger.types.ts
│   ├── app.ts
│   └── server.ts
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed.ts
├── tests/
│   ├── unit/
│   │   ├── invoice.test.ts
│   │   └── ledger.test.ts
│   └── integration/
│       ├── invoice.test.ts
│       └── ledger.test.ts
├── openapi/
│   └── accounting-service.yaml
├── .env.example
├── .env
├── package.json
├── tsconfig.json
├── jest.config.js
├── .eslintrc.js
├── .prettierrc
├── README.md
└── Dockerfile
```

### AI Analytics Service (Python + FastAPI)

```
services/analytics-service/
├── src/
│   ├── config/
│   │   ├── __init__.py
│   │   ├── settings.py
│   │   └── database.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/
│   │   │   ├── __init__.py
│   │   │   ├── forecast.py
│   │   │   └── categorization.py
│   │   └── dependencies.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── security.py
│   │   └── logging.py
│   ├── db/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   └── session.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── forecast_model.py
│   │   └── categorization_model.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── forecast.py
│   │   └── categorization.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── forecast_service.py
│   │   └── categorization_service.py
│   ├── utils/
│   │   ├── __init__.py
│   │   └── helpers.py
│   ├── kafka/
│   │   ├── __init__.py
│   │   ├── consumer.py
│   │   └── producer.py
│   ├── main.py
│   └── __init__.py
├── alembic/
│   ├── versions/
│   ├── env.py
│   └── alembic.ini
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_forecast.py
│   └── test_categorization.py
├── models/
│   ├── cashflow_prophet_model.pkl
│   └── category_model.joblib
├── data/
│   └── synthetic_transactions.csv
├── scripts/
│   ├── train_models.py
│   └── generate_synthetic_data.py
├── openapi/
│   └── analytics-service.yaml
├── .env.example
├── .env
├── requirements.txt
├── pyproject.toml
├── setup.py
├── README.md
└── Dockerfile
```

### Kafka Configuration

```
services/kafka/
├── config/
│   ├── server.properties
│   ├── zookeeper.properties
│   └── topics.json
├── scripts/
│   ├── create-topics.sh
│   └── init-kafka.sh
├── docker-compose.yml
└── README.md
```

## Database Schemas

### Authentication Service Schema (Prisma)

```prisma
// schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id             String    @id @default(uuid())
  email          String    @unique
  hashedPassword String
  role           Role      @default(USER)
  refreshToken   String?
  createdAt      DateTime  @default(now())
  updatedAt      DateTime  @updatedAt

  @@map("users")
}

enum Role {
  USER
  ADMIN
}
```

### Payments Service Schema (Prisma)

```prisma
// schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model Payment {
  id            String    @id @default(uuid())
  userId        String
  amount        Float
  currency      String    @default("USD")
  status        PaymentStatus
  processorId   String?
  processorData Json?
  metadata      Json?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  @@map("payments")
}

enum PaymentStatus {
  PENDING
  PROCESSING
  COMPLETED
  FAILED
  REFUNDED
}
```

### Accounting Service Schema (Prisma)

```prisma
// schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model Invoice {
  id            String         @id @default(uuid())
  userId        String
  client        String
  amount        Float
  dueDate       DateTime
  status        InvoiceStatus  @default(PENDING)
  journalEntries JournalEntry[]
  createdAt     DateTime       @default(now())
  updatedAt     DateTime       @updatedAt

  @@map("invoices")
}

model JournalEntry {
  id            String    @id @default(uuid())
  invoiceId     String?
  invoice       Invoice?  @relation(fields: [invoiceId], references: [id])
  debitAccount  String
  creditAccount String
  amount        Float
  date          DateTime  @default(now())
  description   String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  @@map("journal_entries")
}

enum InvoiceStatus {
  PENDING
  PAID
  OVERDUE
  CANCELLED
}
```

### AI Analytics Service Schema (SQLAlchemy)

```python
# models.py
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
import enum

Base = declarative_base()

class ForecastType(enum.Enum):
    REVENUE = "revenue"
    EXPENSE = "expense"
    CASHFLOW = "cashflow"

class Forecast(Base):
    __tablename__ = "forecasts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, nullable=False)
    forecast_type = Column(Enum(ForecastType), nullable=False)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    data = Column(String, nullable=False)  # JSON string of forecast data points
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

class TransactionCategory(Base):
    __tablename__ = "transaction_categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

class CategorizedTransaction(Base):
    __tablename__ = "categorized_transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, nullable=False)
    description = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    category_id = Column(Integer, ForeignKey("transaction_categories.id"))
    confidence = Column(Float, nullable=False)
    transaction_date = Column(DateTime, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
```

## API Contracts

### Authentication Service OpenAPI Specification

```yaml
# auth-service.yaml
openapi: 3.0.0
info:
  title: Authentication Service API
  version: 1.0.0
  description: API for user authentication and authorization
paths:
  /auth/register:
    post:
      summary: Register a new user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
                  minLength: 8
              required:
                - email
                - password
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  id:
                    type: string
                  email:
                    type: string
        '400':
          description: Invalid input
        '409':
          description: Email already exists
  
  /auth/login:
    post:
      summary: User login
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
              required:
                - email
                - password
      responses:
        '200':
          description: Login successful
          content:
            application/json:
              schema:
                type: object
                properties:
                  accessToken:
                    type: string
                  refreshToken:
                    type: string
        '401':
          description: Invalid credentials
  
  /auth/me:
    get:
      summary: Get current user information
      security:
        - bearerAuth: []
      responses:
        '200':
          description: User information
          content:
            application/json:
              schema:
                type: object
                properties:
                  id:
                    type: string
                  email:
                    type: string
                  role:
                    type: string
        '401':
          description: Unauthorized
  
  /auth/refresh:
    post:
      summary: Refresh access token
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                refreshToken:
                  type: string
              required:
                - refreshToken
      responses:
        '200':
          description: New access token
          content:
            application/json:
              schema:
                type: object
                properties:
                  accessToken:
                    type: string
        '401':
          description: Invalid refresh token

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

### Payments Service OpenAPI Specification

```yaml
# payments-service.yaml
openapi: 3.0.0
info:
  title: Payments Service API
  version: 1.0.0
  description: API for payment processing and tracking
paths:
  /payments/charge:
    post:
      summary: Create a new payment charge
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                amount:
                  type: number
                  minimum: 0.01
                currency:
                  type: string
                  default: USD
                source:
                  type: string
                  description: Payment source token from payment processor
                metadata:
                  type: object
                  description: Additional payment metadata
              required:
                - amount
                - source
      responses:
        '201':
          description: Payment created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Payment'
        '400':
          description: Invalid input
        '401':
          description: Unauthorized
        '500':
          description: Payment processing error
  
  /payments/{id}:
    get:
      summary: Get payment details
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Payment details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Payment'
        '401':
          description: Unauthorized
        '404':
          description: Payment not found
  
  /payments/webhook:
    post:
      summary: Webhook endpoint for payment processor callbacks
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: Webhook processed successfully

components:
  schemas:
    Payment:
      type: object
      properties:
        id:
          type: string
        userId:
          type: string
        amount:
          type: number
        currency:
          type: string
        status:
          type: string
          enum: [PENDING, PROCESSING, COMPLETED, FAILED, REFUNDED]
        processorId:
          type: string
        createdAt:
          type: string
          format: date-time
  
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

### Accounting Service OpenAPI Specification

```yaml
# accounting-service.yaml
openapi: 3.0.0
info:
  title: Accounting Service API
  version: 1.0.0
  description: API for invoice and ledger management
paths:
  /accounting/invoices:
    post:
      summary: Create a new invoice
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                client:
                  type: string
                amount:
                  type: number
                  minimum: 0.01
                dueDate:
                  type: string
                  format: date
              required:
                - client
                - amount
                - dueDate
      responses:
        '201':
          description: Invoice created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Invoice'
        '400':
          description: Invalid input
        '401':
          description: Unauthorized
    
    get:
      summary: Get all invoices for current user
      security:
        - bearerAuth: []
      responses:
        '200':
          description: List of invoices
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Invoice'
        '401':
          description: Unauthorized
  
  /accounting/invoices/{id}:
    get:
      summary: Get invoice details
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Invoice details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Invoice'
        '401':
          description: Unauthorized
        '404':
          description: Invoice not found
  
  /accounting/ledger-entry:
    post:
      summary: Create a new ledger entry
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                invoiceId:
                  type: string
                debitAccount:
                  type: string
                creditAccount:
                  type: string
                amount:
                  type: number
                  minimum: 0.01
                date:
                  type: string
                  format: date-time
                description:
                  type: string
              required:
                - debitAccount
                - creditAccount
                - amount
      responses:
        '201':
          description: Ledger entry created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/JournalEntry'
        '400':
          description: Invalid input
        '401':
          description: Unauthorized

components:
  schemas:
    Invoice:
      type: object
      properties:
        id:
          type: string
        userId:
          type: string
        client:
          type: string
        amount:
          type: number
        dueDate:
          type: string
          format: date
        status:
          type: string
          enum: [PENDING, PAID, OVERDUE, CANCELLED]
        createdAt:
          type: string
          format: date-time
    
    JournalEntry:
      type: object
      properties:
        id:
          type: string
        invoiceId:
          type: string
        debitAccount:
          type: string
        creditAccount:
          type: string
        amount:
          type: number
        date:
          type: string
          format: date-time
        description:
          type: string
        createdAt:
          type: string
          format: date-time
  
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

### AI Analytics Service OpenAPI Specification

```yaml
# analytics-service.yaml
openapi: 3.0.0
info:
  title: AI Analytics Service API
  version: 1.0.0
  description: API for AI-powered financial analytics
paths:
  /analytics/forecast:
    post:
      summary: Generate cash flow forecast
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                forecastType:
                  type: string
                  enum: [revenue, expense, cashflow]
                  default: cashflow
                startDate:
                  type: string
                  format: date
                periods:
                  type: integer
                  minimum: 1
                  maximum: 12
                  default: 3
                historicalData:
                  type: array
                  items:
                    type: object
                    properties:
                      date:
                        type: string
                        format: date
                      amount:
                        type: number
              required:
                - startDate
                - historicalData
      responses:
        '200':
          description: Forecast generated successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  forecastType:
                    type: string
                  startDate:
                    type: string
                    format: date
                  endDate:
                    type: string
                    format: date
                  forecast:
                    type: array
                    items:
                      type: object
                      properties:
                        date:
                          type: string
                          format: date
                        amount:
                          type: number
                        lowerBound:
                          type: number
                        upperBound:
                          type: number
        '400':
          description: Invalid input
        '401':
          description: Unauthorized
  
  /analytics/categorize:
    post:
      summary: Categorize transaction
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                description:
                  type: string
                amount:
                  type: number
              required:
                - description
      responses:
        '200':
          description: Transaction categorized successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  category:
                    type: string
                  confidence:
                    type: number
                    minimum: 0
                    maximum: 1
        '400':
          description: Invalid input
        '401':
          description: Unauthorized

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

## Kafka Topics and Event Schemas

### Kafka Topics

```json
{
  "topics": [
    {
      "name": "user_created",
      "partitions": 3,
      "replication_factor": 2,
      "config": {
        "retention.ms": 604800000
      }
    },
    {
      "name": "invoice_created",
      "partitions": 3,
      "replication_factor": 2,
      "config": {
        "retention.ms": 604800000
      }
    },
    {
      "name": "payment_completed",
      "partitions": 3,
      "replication_factor": 2,
      "config": {
        "retention.ms": 604800000
      }
    },
    {
      "name": "payment_failed",
      "partitions": 3,
      "replication_factor": 2,
      "config": {
        "retention.ms": 604800000
      }
    }
  ]
}
```

### Event Schemas

#### User Created Event

```typescript
interface UserCreatedEvent {
  id: string;
  email: string;
  role: string;
  createdAt: string;
}
```

#### Invoice Created Event

```typescript
interface InvoiceCreatedEvent {
  id: string;
  userId: string;
  client: string;
  amount: number;
  dueDate: string;
  status: string;
  createdAt: string;
}
```

#### Payment Completed Event

```typescript
interface PaymentCompletedEvent {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  status: string;
  processorId: string;
  createdAt: string;
}
```

#### Payment Failed Event

```typescript
interface PaymentFailedEvent {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  reason: string;
  createdAt: string;
}
```

## Docker and Deployment Configuration

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    depends_on:
      - auth-service
      - payments-service
      - accounting-service
      - analytics-service
    environment:
      - REACT_APP_AUTH_API_URL=http://auth-service:4000
      - REACT_APP_PAYMENTS_API_URL=http://payments-service:4001
      - REACT_APP_ACCOUNTING_API_URL=http://accounting-service:4002
      - REACT_APP_ANALYTICS_API_URL=http://analytics-service:4003

  auth-service:
    build: ./services/auth-service
    ports:
      - "4000:4000"
    depends_on:
      - auth-db
      - kafka
    environment:
      - PORT=4000
      - DATABASE_URL=postgresql://postgres:postgres@auth-db:5432/auth
      - JWT_SECRET=your_jwt_secret
      - KAFKA_BROKERS=kafka:9092

  payments-service:
    build: ./services/payments-service
    ports:
      - "4001:4001"
    depends_on:
      - payments-db
      - kafka
    environment:
      - PORT=4001
      - DATABASE_URL=postgresql://postgres:postgres@payments-db:5432/payments
      - JWT_SECRET=your_jwt_secret
      - KAFKA_BROKERS=kafka:9092
      - STRIPE_SECRET=your_stripe_secret
      - STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret

  accounting-service:
    build: ./services/accounting-service
    ports:
      - "4002:4002"
    depends_on:
      - accounting-db
      - kafka
    environment:
      - PORT=4002
      - DATABASE_URL=postgresql://postgres:postgres@accounting-db:5432/accounting
      - JWT_SECRET=your_jwt_secret
      - KAFKA_BROKERS=kafka:9092

  analytics-service:
    build: ./services/analytics-service
    ports:
      - "4003:4003"
    depends_on:
      - analytics-db
      - kafka
    environment:
      - PORT=4003
      - DATABASE_URL=postgresql://postgres:postgres@analytics-db:5432/analytics
      - JWT_SECRET=your_jwt_secret
      - KAFKA_BROKERS=kafka:9092

  auth-db:
    image: postgres:14
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=auth
    volumes:
      - auth-db-data:/var/lib/postgresql/data

  payments-db:
    image: postgres:14
    ports:
      - "5433:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=payments
    volumes:
      - payments-db-data:/var/lib/postgresql/data

  accounting-db:
    image: postgres:14
    ports:
      - "5434:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=accounting
    volumes:
      - accounting-db-data:/var/lib/postgresql/data

  analytics-db:
    image: postgres:14
    ports:
      - "5435:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=analytics
    volumes:
      - analytics-db-data:/var/lib/postgresql/data

  zookeeper:
    image: confluentinc/cp-zookeeper:7.0.1
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:7.0.1
    ports:
      - "9092:9092"
      - "29092:29092"
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1

volumes:
  auth-db-data:
  payments-db-data:
  accounting-db-data:
  analytics-db-data:
```

## Implementation Plan

1. **Project Setup**
   - Create base directory structure
   - Set up Docker and Docker Compose configuration
   - Create README files with setup instructions

2. **Authentication Service**
   - Implement user registration and login
   - Set up JWT authentication
   - Implement role-based authorization
   - Create database schema and migrations
   - Write unit and integration tests

3. **Payments Service**
   - Implement payment processing with Stripe integration
   - Set up webhook handling
   - Create Kafka producers for payment events
   - Create database schema and migrations
   - Write unit and integration tests

4. **Accounting Service**
   - Implement invoice creation and management
   - Set up ledger entry creation
   - Create Kafka consumers for payment events
   - Create database schema and migrations
   - Write unit and integration tests

5. **AI Analytics Service**
   - Implement cash flow forecasting
   - Implement transaction categorization
   - Train and save ML models
   - Create database schema and migrations
   - Write unit and integration tests

6. **Frontend Application**
   - Set up React application with TypeScript
   - Implement authentication and user management
   - Create dashboard with KPIs and charts
   - Implement invoice management
   - Implement payment processing
   - Implement analytics visualization
   - Write component tests

7. **Integration and Testing**
   - Test service-to-service communication
   - Test Kafka event processing
   - Test end-to-end workflows
   - Validate against architecture requirements

This design document provides a comprehensive blueprint for implementing the FinFlow Platform according to the architecture specifications. Each component is designed to be modular, scalable, and maintainable, following best practices for microservices architecture.
