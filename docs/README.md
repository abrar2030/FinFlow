# FinFlow Platform

FinFlow is an AI-powered financial operations platform built with a microservices architecture. The platform provides comprehensive financial management capabilities including authentication, payments processing, accounting, and AI-powered analytics.

## Architecture

The platform consists of the following components:

- **Frontend Application**: React + TypeScript application with Tailwind CSS for styling
- **Authentication Service**: Node.js + Express service for user authentication and authorization
- **Payments Service**: Node.js + Express service for payment processing with Stripe integration
- **Accounting Service**: Node.js + Express service for invoice and ledger management
- **AI Analytics Service**: Python + FastAPI service for cash flow forecasting and transaction categorization
- **Kafka**: Event streaming platform for asynchronous communication between services

Each service is designed as an independent microservice with its own database and API. Services communicate via REST APIs (defined with OpenAPI 3.0) and Kafka event streams for asynchronous workflows.

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Node.js 16+
- Python 3.8+
- PostgreSQL 14+

### Installation

1. Clone the repository
2. Set up environment variables for each service (see `.env.example` files)
3. Run Docker Compose to start all services:

```bash
docker-compose up -d
```

## Services

### Authentication Service

Handles user registration, login, and OAuth2.0 flows, issuing JWTs for API authentication.

- **Endpoints**: `/auth/register`, `/auth/login`, `/auth/me`, etc.
- **Technologies**: Express.js, Passport.js, bcrypt, jsonwebtoken, Prisma

### Payments Service

Handles initiating and tracking payments, integrating with payment processors via API/webhooks.

- **Endpoints**: `/payments/charge`, `/payments/:id`, `/payments/webhook`
- **Technologies**: Express.js, Stripe SDK, Prisma

### Accounting Service

Manages invoices, ledgers, and reconciliations, tracking money owed and paid.

- **Endpoints**: `/accounting/invoices`, `/accounting/ledger-entry`
- **Technologies**: Express.js, Prisma

### AI Analytics Service

Provides machine learning analytics for cash flow forecasting and expense categorization.

- **Endpoints**: `/analytics/forecast`, `/analytics/categorize`
- **Technologies**: FastAPI, pandas, scikit-learn, Prophet

## Development

Each service can be developed and run independently. See the README in each service directory for specific instructions.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
