# FinFlow Backend

## Financial Operations & Workflow Platform - Backend Services

FinFlow's backend is a comprehensive microservices architecture that powers the financial operations platform, providing secure authentication, real-time transaction processing, accounting, analytics, and credit management capabilities. The backend is designed for scalability, resilience, and maintainability, with each service focusing on a specific domain of financial operations.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
  - [Microservices](#microservices)
  - [Common Components](#common-components)
  - [Event-Driven Communication](#event-driven-communication)
- [Backend Services](#backend-services)
  - [Auth Service](#auth-service)
  - [Accounting Service](#accounting-service)
  - [Analytics Service](#analytics-service)
  - [Compliance Service](#compliance-service)
  - [Credit Engine](#credit-engine)
  - [Payments Service](#payments-service)
  - [Transaction Service](#transaction-service)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Quick Setup](#quick-setup)
  - [Manual Setup](#manual-setup)
  - [Environment Configuration](#environment-configuration)
- [API Documentation](#api-documentation)
- [Testing](#testing)
  - [Running Tests](#running-tests)
  - [Test Coverage](#test-coverage)
- [Deployment](#deployment)
  - [Docker Deployment](#docker-deployment)
  - [Kubernetes Deployment](#kubernetes-deployment)
- [Monitoring and Logging](#monitoring-and-logging)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

The FinFlow backend is built on a modern microservices architecture that enables scalable, resilient, and maintainable financial operations. Each service is designed to handle specific aspects of financial workflows, from authentication and payment processing to accounting, analytics, and compliance.

The backend leverages industry-standard technologies and best practices to provide a secure, high-performance foundation for financial operations. It supports multi-processor payment gateway integration, double-entry accounting, real-time analytics, and advanced credit management, all through a unified API layer.

## Architecture

### Microservices

FinFlow's backend follows a microservices architecture, with each service focusing on a specific domain:

```
FinFlow/backend/
├── Auth Service - User authentication and authorization
├── Accounting Service - Double-entry accounting and financial reporting
├── Analytics Service - Data analysis and visualization
├── Compliance Service - Regulatory compliance and reporting
├── Credit Engine - Credit scoring and loan management
├── Payments Service - Payment processing and gateway integration
├── Transaction Service - Transaction validation and processing
└── Common - Shared utilities and components
```

This architecture enables:

- **Independent Scaling**: Each service can be scaled based on its specific load requirements
- **Technology Flexibility**: Services can use different technologies based on their specific needs
- **Isolated Development**: Teams can work on different services without affecting others
- **Resilience**: Failures in one service don't necessarily affect others
- **Continuous Deployment**: Services can be deployed independently

### Common Components

The `common` directory contains shared utilities and components used across multiple services:

- **Database Connections**: Standardized database connection management
- **Logging**: Centralized logging configuration
- **Kafka Integration**: Event bus communication utilities
- **Authentication**: Shared authentication components
- **Server Configuration**: Common server setup and middleware

### Event-Driven Communication

FinFlow uses an event-driven architecture for communication between services, primarily through Kafka:

1. **Payment Events**: Trigger accounting entries, analytics updates, and credit assessments
2. **User Events**: Manage authentication state and authorization updates
3. **Transaction Events**: Coordinate transaction processing across services
4. **Compliance Events**: Trigger compliance checks and reporting
5. **System Events**: Handle infrastructure scaling and monitoring alerts

This approach enables loose coupling between services and supports eventual consistency across the system.

## Backend Services

### Auth Service

The Authentication Service handles user authentication, authorization, and session management for the FinFlow platform.

**Key Features:**
- Multi-factor authentication with SMS and authenticator app support
- Role-based access control with granular permissions
- OAuth integration with third-party providers (Google, GitHub, Microsoft)
- Secure session handling and token-based authentication
- Password policy enforcement and account lockout protection

**API Endpoints:**
- `POST /api/auth/register`: Register a new user
- `POST /api/auth/login`: Authenticate a user
- `POST /api/auth/refresh`: Refresh authentication token
- `GET /api/auth/me`: Get current user information
- `POST /api/auth/logout`: Log out a user
- `POST /api/auth/mfa/enable`: Enable multi-factor authentication
- `POST /api/auth/mfa/verify`: Verify MFA token

**Environment Variables:**
- `AUTH_SERVICE_PORT`: Port for the Auth service (default: 3001)
- `JWT_SECRET`: Secret key for JWT token generation
- `JWT_EXPIRATION`: Token expiration time in seconds
- `MFA_SECRET_KEY`: Secret key for MFA token generation
- `REDIS_HOST`: Redis host for session storage
- `REDIS_PORT`: Redis port for session storage

### Accounting Service

The Accounting Service provides double-entry accounting capabilities, financial reporting, and reconciliation tools for the FinFlow platform.

**Key Features:**
- Double-entry accounting engine with transaction validation
- Financial reporting (balance sheets, income statements, cash flow)
- Automated account reconciliation and discrepancy detection
- Trial balance generation and verification
- Multi-currency support with exchange rate management
- Fiscal year and period management

**API Endpoints:**
- `POST /api/accounting/transactions`: Create a new accounting transaction
- `GET /api/accounting/transactions`: Get all transactions
- `GET /api/accounting/accounts`: Get all accounts
- `POST /api/accounting/accounts`: Create a new account
- `GET /api/accounting/reports/balance-sheet`: Generate balance sheet
- `GET /api/accounting/reports/income-statement`: Generate income statement
- `GET /api/accounting/reports/cash-flow`: Generate cash flow statement

**Environment Variables:**
- `ACCOUNTING_SERVICE_PORT`: Port for the Accounting service (default: 3003)
- `POSTGRES_HOST`: PostgreSQL host
- `POSTGRES_PORT`: PostgreSQL port
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name
- `KAFKA_BROKER`: Kafka broker address for event publishing

### Analytics Service

The Analytics Service provides data analysis, visualization, and reporting capabilities for the FinFlow platform.

**Key Features:**
- Interactive dashboards with real-time metrics
- Transaction analysis with detailed breakdowns
- Trend visualization with historical data analysis
- Export capabilities in multiple formats (CSV, Excel, PDF)
- Scheduled reports and notifications
- Custom metric definition and tracking

**API Endpoints:**
- `GET /api/analytics/dashboard`: Get dashboard metrics
- `GET /api/analytics/transactions`: Get transaction analytics
- `GET /api/analytics/revenue`: Get revenue analytics
- `GET /api/analytics/users`: Get user analytics
- `POST /api/analytics/reports/generate`: Generate custom report
- `GET /api/analytics/reports/{id}`: Get a specific report
- `GET /api/analytics/export/{format}`: Export analytics data

**Environment Variables:**
- `ANALYTICS_SERVICE_PORT`: Port for the Analytics service (default: 3004)
- `MONGODB_URI`: MongoDB connection URI
- `REDIS_HOST`: Redis host for caching
- `REDIS_PORT`: Redis port for caching
- `KAFKA_BROKER`: Kafka broker address for event consumption

### Compliance Service

The Compliance Service implements GDPR, PSD2, and AML/CFT regulatory requirements for the FinFlow platform.

**Key Features:**
- GDPR compliance with data subject rights management
- PSD2 compliance with third-party provider consent management
- AML/CFT compliance with entity screening against watchlists
- Risk assessment and categorization for compliance
- Comprehensive audit trail for regulatory reporting

**API Endpoints:**
- `POST /gdpr/data-requests`: Create a new GDPR data request
- `GET /gdpr/data-requests/{request_id}`: Get the status of a GDPR data request
- `POST /psd2/consents`: Create a new PSD2 consent for third-party access
- `DELETE /psd2/consents/{consent_id}`: Revoke a PSD2 consent
- `GET /psd2/consents/{consent_id}/validate`: Validate a PSD2 consent
- `POST /aml/screening`: Screen an entity against AML/CFT watchlists
- `GET /aml/screening/{screening_id}`: Get an AML screening result
- `POST /aml/reschedule/{entity_type}/{entity_id}`: Schedule periodic rescreening
- `GET /health`: Service health check

**Environment Variables:**
- `CREDIT_ENGINE_PORT`: Port for the Credit Engine service (default: 3005)
- `POSTGRES_HOST`: PostgreSQL host
- `POSTGRES_PORT`: PostgreSQL port
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name
- `MODEL_PATH`: Path to trained machine learning model

### Credit Engine

The Credit Engine provides credit scoring, risk assessment, and loan offer generation capabilities for the FinFlow platform.

**Key Features:**
- Credit score calculation using machine learning models
- Risk assessment based on financial data analysis
- Loan offer generation with customized terms
- Financial data analysis for creditworthiness determination
- Machine learning model training and inference

**API Endpoints:**
- `POST /api/credit/score`: Calculate credit score
- `GET /api/credit/score/:id`: Get credit score by ID
- `POST /api/credit/offers`: Generate loan offers
- `GET /api/credit/offers`: Get all loan offers
- `GET /api/credit/offers/:id`: Get loan offer details by ID

**Environment Variables:**
- `CREDIT_ENGINE_PORT`: Port for the Credit Engine service (default: 3005)
- `POSTGRES_HOST`: PostgreSQL host
- `POSTGRES_PORT`: PostgreSQL port
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name
- `MODEL_PATH`: Path to trained machine learning model

### Payments Service

The Payments Service handles payment processing, tracking, and integration with payment providers like Stripe in the FinFlow platform.

**Key Features:**
- Payment processing via Stripe integration
- Payment method management
- Transaction history and tracking
- Payment status updates and notifications
- Webhook handling for payment events

**API Endpoints:**
- `POST /api/payments/process`: Process a new payment
- `GET /api/payments`: Get all payments for the current user
- `GET /api/payments/:id`: Get payment details by ID
- `POST /api/payments/methods`: Add a new payment method
- `GET /api/payments/methods`: Get all payment methods for the current user
- `DELETE /api/payments/methods/:id`: Delete a payment method
- `POST /api/payments/webhook`: Handle payment provider webhooks

**Environment Variables:**
- `PAYMENTS_PORT`: Port for the Payments service (default: 3002)
- `STRIPE_API_KEY`: Stripe API key for payment processing
- `STRIPE_WEBHOOK_SECRET`: Secret for validating Stripe webhook events
- `POSTGRES_HOST`: PostgreSQL host
- `POSTGRES_PORT`: PostgreSQL port
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name
- `KAFKA_BROKER`: Kafka broker address for event publishing

### Transaction Service

The Transaction Service provides robust transaction validation, database optimization, and caching for high-volume financial transactions in the FinFlow platform.

**Key Features:**
- Comprehensive transaction validation with multi-layered risk scoring
- Optimized database operations for high-volume transaction processing
- Advanced caching with multi-level primary and fallback strategies
- Batch processing for efficient handling of transaction batches
- High-performance design for throughput-intensive financial environments

**Architecture:**
- Models: Pydantic models for request/response validation
- Validation: Comprehensive transaction validation logic
- Database: Optimized database operations with connection pooling

## Getting Started

### Prerequisites

Before setting up the FinFlow backend, ensure you have the following installed:

- **Node.js** (v16+)
- **Python** (v3.8+) for the Credit Engine service
- **Docker** and Docker Compose
- **PostgreSQL** (v13+)
- **MongoDB** (v5+)
- **Redis** (v6+)
- **Kafka** (v2.8+)

### Quick Setup

The easiest way to set up the development environment is to use the provided setup script:

```bash
# Clone the repository
git clone https://github.com/abrar2030/FinFlow.git
cd FinFlow

# Run the setup script
./setup_env.sh

# Start the backend services
docker-compose up
```

After running these commands, you can access:

- API Gateway: http://localhost:8080
- Swagger Documentation: http://localhost:8080/api-docs

### Manual Setup

If you prefer to set up each service individually, follow these steps:

#### 1. Environment Configuration

Create a `.env` file in the backend directory with the following variables:

```
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_password
DB_NAME=finflow

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT Configuration
JWT_SECRET=your_jwt_secret
JWT_EXPIRATION=86400

# Payment Gateway Configuration
STRIPE_SECRET=your_stripe_secret
STRIPE_PUBLIC_KEY=your_stripe_public_key
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret
SQUARE_ACCESS_TOKEN=your_square_access_token
SQUARE_LOCATION_ID=your_square_location_id

# Kafka Configuration
KAFKA_BROKER=localhost:9092
```

#### 2. Start Each Service

```bash
# Auth Service
cd backend/auth-service
npm install
npm run start:dev

# Payments Service
cd backend/payments-service
npm install
npm run start:dev

# Accounting Service
cd backend/accounting-service
npm install
npm run start:dev

# Analytics Service
cd backend/analytics-service
npm install
npm run start:dev

# Compliance Service
cd backend/compliance-service
npm install
npm run start:dev

# Credit Engine
cd backend/credit-engine
pip install -r requirements.txt
python src/main.py

# Transaction Service
cd backend/transaction-service
npm install
npm run start:dev
```

## API Documentation

FinFlow provides comprehensive API documentation using OpenAPI/Swagger:

- **Combined API Documentation**: Available at `http://localhost:8080/api-docs` when running the API Gateway
- **Individual Service Documentation**:
  - Auth Service: `http://localhost:3001/api-docs`
  - Payments Service: `http://localhost:3002/api-docs`
  - Accounting Service: `http://localhost:3003/api-docs`
  - Analytics Service: `http://localhost:3004/api-docs`
  - Compliance Service: `http://localhost:3005/api-docs`
  - Credit Engine: `http://localhost:3006/api-docs`
  - Transaction Service: `http://localhost:3007/api-docs`

The API documentation includes:

- Endpoint descriptions and usage examples
- Request and response schemas
- Authentication requirements
- Error codes and handling
- Rate limiting information

## Testing

### Running Tests

Each service includes a comprehensive test suite. To run tests for a specific service:

```bash
cd backend/<service-name>
npm test
```

For the Credit Engine:

```bash
cd backend/credit-engine
pytest
```

To run all backend tests:

```bash
cd backend
./run_all_tests.sh
```

### Test Coverage

Generate test coverage reports for a specific service:

```bash
cd backend/<service-name>
npm run test:coverage
```

For the Credit Engine:

```bash
cd backend/credit-engine
pytest --cov=src
```

The coverage reports are generated in the `coverage` directory of each service.

## Deployment

### Docker Deployment

FinFlow backend services can be deployed using Docker:

```bash
# Build all services
docker-compose build

# Deploy all services
docker-compose up -d
```

To deploy a specific service:

```bash
docker-compose up -d <service-name>
```

### Kubernetes Deployment

For production environments, Kubernetes deployment files are provided:

```bash
# Deploy to Kubernetes
kubectl apply -f backend/kubernetes/

# Deploy a specific service
kubectl apply -f backend/<service-name>/kubernetes.yaml
```

## Monitoring and Logging

FinFlow backend includes comprehensive monitoring and logging:

- **Centralized Logging**: All services log to a centralized ELK stack
- **Metrics Collection**: Prometheus metrics exposed by each service
- **Dashboards**: Grafana dashboards for visualizing metrics
- **Alerts**: Alertmanager configuration for critical alerts
- **Distributed Tracing**: Jaeger integration for request tracing

To access the monitoring stack:

- Kibana (Logs): `http://localhost:5601`
- Grafana (Dashboards): `http://localhost:3000`
- Prometheus (Metrics): `http://localhost:9090`
- Jaeger (Tracing): `http://localhost:16686`

## Security

FinFlow implements multiple security layers:

- **Authentication**: JWT-based authentication with refresh tokens
- **Authorization**: Role-based access control for all endpoints
- **Data Encryption**: TLS for all communications and data at rest
- **Input Validation**: Strict validation for all API inputs
- **Rate Limiting**: Protection against brute force and DoS attacks
- **Audit Logging**: Comprehensive logging of security events
- **Dependency Scanning**: Regular scanning for vulnerable dependencies
- **Container Security**: Minimal container images with security scanning

## Troubleshooting

### Common Issues

#### Service Connection Errors

If services cannot connect to each other:

1. Check that all services are running: `docker-compose ps`
2. Verify network configuration: `docker network inspect finflow_network`
3. Check service logs: `docker-compose logs <service-name>`

#### Database Connection Issues

If services cannot connect to the database:

1. Verify database is running: `docker-compose ps postgres`
2. Check database logs: `docker-compose logs postgres`
3. Verify environment variables are correctly set

#### Authentication Failures

If authentication is failing:

1. Check JWT_SECRET is consistent across services
2. Verify token expiration settings
3. Check Redis connection for session storage

### Debugging

Each service includes debugging tools:

- **Debug Logs**: Enable debug logs by setting `LOG_LEVEL=debug`
- **API Inspection**: Use the `/debug` endpoints (in development only)
- **Health Checks**: Access `/health` endpoints to verify service status

## Contributing

We welcome contributions to the FinFlow backend! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Submit a pull request

### Development Guidelines

- Follow the established code style and architecture
- Write tests for all new features
- Update documentation for API changes
- Use conventional commit messages

## License

FinFlow is licensed under the MIT License. See the LICENSE file for details.
