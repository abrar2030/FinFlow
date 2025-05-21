# FinFlow - Financial Operations & Workflow Platform

[![CI/CD Status](https://img.shields.io/github/actions/workflow/status/abrar2030/FinFlow/ci-cd.yml?branch=main&label=CI/CD&logo=github)](https://github.com/abrar2030/FinFlow/actions)
[![Test Coverage](https://img.shields.io/badge/coverage-96%25-brightgreen)](https://github.com/abrar2030/FinFlow/tree/main/coverage)
[![License](https://img.shields.io/github/license/abrar2030/FinFlow?style=flat-square)](LICENSE)

<div align="center">
  <img src="docs/images/FinFlow_Dashboard.bmp" alt="FinFlow Dashboard" width="80%">
</div>

> **Note**: This project is under active development. Features and functionalities are continuously being enhanced to improve financial operations capabilities and user experience.

## 📋 Executive Summary

FinFlow is a comprehensive financial operations platform that streamlines payment processing, accounting, analytics, and credit management through a unified microservices architecture. The platform provides secure authentication, real-time transaction processing, and advanced financial analytics to help businesses manage their financial workflows efficiently.

**Key Highlights:**
- Multi-processor payment gateway integration (Stripe, PayPal, Square)
- Double-entry accounting system with financial reporting
- Interactive analytics dashboard with real-time metrics
- Secure authentication with role-based access control
- Microservices architecture for scalability and resilience
- Modern mobile frontend with comprehensive feature coverage

## 📑 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Quick Setup](#quick-setup)
  - [Manual Setup](#manual-setup)
- [Architecture](#architecture)
- [API Documentation](#api-documentation)
- [Testing](#testing)
  - [Test Coverage](#test-coverage)
  - [Running Tests](#running-tests)
  - [Generating Coverage Reports](#generating-coverage-reports)
  - [Test Structure](#test-structure)
- [Troubleshooting](#troubleshooting)
- [Feature Implementation Status](#feature-implementation-status)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

FinFlow is a modern financial operations platform designed to help businesses streamline their financial workflows, from payment processing to accounting and analytics. The platform combines traditional financial operations with cutting-edge technology to provide a secure, scalable, and efficient solution for managing financial data and processes.

## ✨ Key Features

### Authentication & Authorization

- **Multi-factor Authentication**: Secure user authentication with SMS and authenticator app support
- **Role-based Access Control**: Granular permissions for different user roles
- **OAuth Integration**: Support for third-party authentication providers (Google, GitHub, Microsoft)
- **Session Management**: Secure session handling and token-based authentication

### Payment Processing

- **Multiple Payment Processors**: Integrated support for Stripe, PayPal, and Square
- **Real-time Transaction Processing**: Instant payment verification and processing
- **Recurring Payments**: Automated billing for subscription-based services
- **Digital Wallet Support**: Integration with Apple Pay, Google Pay, and PayPal

### Accounting & Reconciliation

- **Double-Entry Accounting**: Robust accounting engine with double-entry bookkeeping
- **Financial Reporting**: Generate balance sheets, income statements, and cash flow reports
- **Reconciliation Tools**: Automated account reconciliation and discrepancy detection
- **Trial Balance**: Automatic generation of trial balance reports

### Analytics & Reporting

- **Interactive Dashboards**: Visual representation of financial metrics and KPIs
- **Transaction Analysis**: Detailed breakdown of transaction data
- **Trend Visualization**: Historical data analysis with interactive charts
- **Export Capabilities**: Data export in multiple formats (CSV, Excel, PDF)

### Credit Management

- **Credit Scoring**: Automated credit risk assessment
- **Loan Processing**: Streamlined loan application and approval workflow
- **Repayment Tracking**: Automated tracking of loan repayments
- **Default Prediction**: ML-based prediction of default risk

### Mobile Frontend

- **Cross-platform Support**: React Native implementation for iOS and Android
- **Offline Capabilities**: Core functionality available without internet connection
- **Biometric Authentication**: Secure login with fingerprint and face recognition
- **Real-time Notifications**: Push notifications for important financial events
- **Responsive Design**: Optimized for various screen sizes and orientations

## 🚀 Getting Started

### Prerequisites

Before setting up FinFlow, ensure you have the following installed:

- **Node.js** (v16+)
- **Docker** and Docker Compose
- **PostgreSQL** (v13+)
- **MongoDB** (v5+)
- **Redis** (v6+)

### Quick Setup

The easiest way to set up the development environment is to use the provided setup script:

```bash
# Clone the repository
git clone https://github.com/abrar2030/FinFlow.git
cd FinFlow

# Run the setup script
./setup_env.sh

# Start the application
docker-compose up
```

After running these commands, you can access:
- Frontend: http://localhost:3000
- API Gateway: http://localhost:8080
- Swagger Documentation: http://localhost:8080/api-docs

### Manual Setup

If you prefer to set up each service individually, follow these steps:

#### 1. Environment Configuration

Create a `.env` file in the root directory with the following variables:

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
```

#### 2. Backend Services

Start each service individually:

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

# Credit Engine
cd backend/credit-engine
npm install
npm run start:dev
```

#### 3. Frontend

```bash
# Web Dashboard
cd frontend
npm install
npm start

# Mobile Frontend
cd mobile-frontend
npm install
npm start
```

## 🏗️ Architecture

FinFlow follows a microservices architecture with the following components:

### Service Architecture

```
FinFlow/
├── Backend Services
│   ├── Auth Service - User authentication and authorization
│   ├── Payments Service - Payment processing and gateway integration
│   ├── Accounting Service - Double-entry accounting and financial reporting
│   ├── Analytics Service - Data analysis and visualization
│   └── Credit Engine - Credit scoring and loan management
├── Frontend Applications
│   ├── Web Dashboard - React-based admin interface
│   └── Mobile App - React Native client
├── Infrastructure
│   ├── API Gateway - Request routing and composition
│   ├── Service Mesh - Inter-service communication
│   ├── Message Broker - Event-driven communication
│   └── Monitoring Stack - Logging, metrics, and alerting
└── Data Layer
    ├── Transactional Database - PostgreSQL for ACID operations
    ├── Analytics Database - MongoDB for flexible data storage
    └── Document Store - For unstructured data
```

### Event-Driven Communication

FinFlow uses an event-driven architecture for communication between services:

1. **Payment Events**: Trigger accounting entries, analytics updates, and credit assessments
2. **User Events**: Manage authentication state and authorization updates
3. **System Events**: Handle infrastructure scaling and monitoring alerts

### Technology Stack

#### Backend
- **Languages**: Node.js, TypeScript
- **Frameworks**: Express.js, NestJS
- **Database**: PostgreSQL, MongoDB
- **Caching**: Redis
- **Message Queue**: RabbitMQ, Kafka
- **API Documentation**: OpenAPI, Swagger

#### Frontend
- **Web Framework**: React with TypeScript
- **Mobile Framework**: React Native with Expo
- **State Management**: Redux Toolkit
- **UI Components**: Material-UI, Tailwind CSS (Web), Native Base (Mobile)
- **Data Visualization**: Recharts (Web), Victory Native (Mobile)
- **API Client**: Axios, React Query

#### DevOps & Infrastructure
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus, Grafana
- **Logging**: ELK Stack
- **Cloud**: AWS, Google Cloud Platform

## 📚 API Documentation

FinFlow provides comprehensive API documentation using OpenAPI/Swagger. When running the application, you can access the documentation at:

- **Auth Service API**: `http://localhost:3001/api-docs`
- **Payments Service API**: `http://localhost:3002/api-docs`
- **Accounting Service API**: `http://localhost:3003/api-docs`
- **Analytics Service API**: `http://localhost:3004/api-docs`
- **Credit Engine API**: `http://localhost:3005/api-docs`

### API Examples

#### Authentication

```bash
# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'

# Response
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123",
    "email": "user@example.com",
    "role": "admin"
  }
}
```

#### Creating a Payment

```bash
# Create payment
curl -X POST http://localhost:3002/api/payments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "amount": 100.00,
    "currency": "usd",
    "processorType": "stripe",
    "source": "tok_visa",
    "metadata": {
      "orderId": "order_123"
    }
  }'

# Response
{
  "id": "pay_123",
  "amount": 100.00,
  "currency": "usd",
  "status": "completed",
  "processorId": "ch_1234",
  "processorType": "stripe",
  "createdAt": "2025-05-20T10:30:00Z"
}
```

## 🧪 Testing

FinFlow includes comprehensive testing across all services to ensure reliability, security, and accuracy of financial operations. Our testing strategy covers unit tests, integration tests, and end-to-end tests for both backend and frontend components.

### Test Coverage

The project maintains high test coverage across all critical components:

| Service | Coverage | Critical Paths |
|---------|----------|---------------|
| Auth Service | 95% | Authentication flows, token validation, OAuth integration |
| Payments Service | 97% | Payment processing, multiple processors, refunds |
| Accounting Service | 94% | Journal entries, financial reporting, double-entry validation |
| Analytics Service | 92% | Data analysis, metrics calculation, forecasting |
| Web Frontend | 90% | UI components, Redux store, API services |
| Mobile Frontend | 96% | All screens, Redux integration, navigation flows |
| End-to-End Flows | 85% | Critical user journeys across services |

### Running Tests

To run the tests for each component of the system:

#### Backend Service Tests

Each backend service has its own test suite that can be run independently:

```bash
# Install dependencies first (if not already installed)
cd backend/auth-service
npm install

# Run auth service tests
npm test

# Run with coverage report
npm test -- --coverage
```

Repeat the same process for other services:
- `backend/payments-service`
- `backend/accounting-service`
- `backend/analytics-service`

#### Web Frontend Tests

The web frontend tests cover components, Redux store, and API services:

```bash
# Install dependencies first
cd frontend
npm install

# Run all frontend tests
npm test

# Run with coverage report
npm test -- --coverage

# Run a specific test file
npm test -- PaymentForm.test.tsx
```

#### Mobile Frontend Tests

The mobile frontend has comprehensive test coverage for all screens and components:

```bash
# Install dependencies first
cd mobile-frontend
npm install

# Run all mobile tests
npm test

# Run with coverage report
npm test -- --coverage

# Run a specific test file
npm test -- LoginScreen.test.tsx
```

#### End-to-End Tests

End-to-end tests validate complete user flows across services:

```bash
# Make sure the application is running locally first
# Then run the E2E tests
cd e2e
npm install
npm test
```

### Generating Coverage Reports

To generate a comprehensive coverage report for the entire project:

```bash
# From the project root
./run-tests.sh
```

This script will:
1. Run all tests across backend services
2. Run frontend tests
3. Run mobile frontend tests
4. Generate individual coverage reports
5. Merge them into a combined report
6. Output the report to the `coverage-reports/combined` directory

You can view the HTML coverage report by opening `coverage-reports/combined/index.html` in your browser.

### Test Structure

The test files are organized following the project structure:

```
FinFlow/
├── backend/
│   ├── auth-service/
│   │   └── tests/
│   │       ├── auth.service.test.ts     # Unit tests
│   │       └── auth.integration.test.ts # Integration tests
│   ├── payments-service/
│   │   └── tests/
│   │       ├── payment.service.test.ts
│   │       └── payment.integration.test.ts
│   └── ...
├── web-frontend/
│   └── src/
│       ├── components/
│       │   └── __tests__/
│       │       └── PaymentForm.test.tsx
│       ├── pages/
│       │   └── __tests__/
│       │       ├── Dashboard.test.tsx
│       │       └── Login.test.tsx
│       └── store/
│           └── __tests__/
│               └── paymentSlice.test.ts
├── mobile-frontend/
│   └── src/
│       ├── components/
│       │   └── __tests__/
│       │       ├── Button.test.tsx
│       │       ├── Card.test.tsx
│       │       └── InputField.test.tsx
│       ├── screens/
│       │   └── __tests__/
│       │       ├── LoginScreen.test.tsx
│       │       ├── DashboardScreen.test.tsx
│       │       ├── PaymentsScreen.test.tsx
│       │       └── AnalyticsScreen.test.tsx
│       ├── hooks/
│       │   └── __tests__/
│       │       ├── useAuth.test.tsx
│       │       └── usePayments.test.tsx
│       └── store/
│           └── __tests__/
│               ├── authSlice.test.ts
│               └── paymentsSlice.test.ts
└── e2e/
    ├── auth.spec.ts
    ├── payment.spec.ts
    ├── accounting.spec.ts
    └── dashboard.spec.ts
```

#### Mobile Frontend Test Coverage

The mobile frontend maintains comprehensive test coverage across all major components:

| Category | Coverage | Components Tested |
|----------|----------|-------------------|
| Authentication | 98% | Login, Register, Password Reset flows |
| Dashboard | 97% | Metrics display, navigation, data refresh |
| Payments | 96% | Transaction list, payment creation, details view |
| Analytics | 95% | Charts, filters, period selection |
| Accounting | 94% | Financial reports, balance sheet, income statement |
| Credit | 97% | Credit score, loan management, application flow |
| Navigation | 98% | Stack navigation, tab navigation, deep linking |
| Common Components | 99% | Buttons, cards, inputs, loading states |
| Redux Store | 96% | All slices, actions, reducers, selectors |
| API Integration | 93% | Service calls, error handling, caching |

#### Test Types

1. **Unit Tests**: Test individual functions and components in isolation
2. **Integration Tests**: Test interactions between components and services
3. **End-to-End Tests**: Test complete user flows from frontend to backend

## ❓ Troubleshooting

### Common Issues and Solutions

#### Database Connection Issues

**Problem**: Services fail to connect to the database.

**Solution**:
1. Verify that PostgreSQL is running: `sudo service postgresql status`
2. Check database credentials in `.env` file
3. Ensure the database exists: `psql -U postgres -c "SELECT 1 FROM pg_database WHERE datname='finflow'"`
4. If the database doesn't exist, create it: `psql -U postgres -c "CREATE DATABASE finflow"`

#### Payment Processing Failures

**Problem**: Payments fail to process with external providers.

**Solution**:
1. Verify API keys in `.env` file
2. Check that the payment processor is available
3. For testing, use test mode credentials and test card numbers
4. Review logs for specific error messages: `docker-compose logs payments-service`

#### Authentication Issues

**Problem**: Unable to log in or access protected routes.

**Solution**:
1. Ensure JWT_SECRET is properly set in `.env`
2. Check that the token hasn't expired
3. Verify user credentials in the database
4. Clear browser cookies and local storage

#### Mobile App Issues

**Problem**: Mobile app fails to connect to backend services.

**Solution**:
1. Verify API endpoint configuration in the mobile app
2. Check network connectivity on the mobile device
3. Ensure backend services are running and accessible
4. Clear app cache and restart the application
5. Check for version compatibility issues

#### Docker Compose Issues

**Problem**: Docker Compose fails to start services.

**Solution**:
1. Check if ports are already in use: `netstat -tulpn | grep <port>`
2. Ensure Docker and Docker Compose are up to date
3. Try rebuilding the containers: `docker-compose build --no-cache`
4. Check container logs: `docker-compose logs`

#### Test Execution Issues

**Problem**: Tests fail to run or produce unexpected failures.

**Solution**:
1. Ensure all dependencies are installed: `npm install` in each service directory
2. Check for environment variables needed by tests
3. For integration tests, verify that required services (databases, etc.) are running
4. For end-to-end tests, ensure the application is running locally
5. Check test logs for specific error messages

### Getting Help

If you encounter issues not covered here:

1. Check the GitHub Issues page for similar problems
2. Join our community Discord server for real-time help
3. Review the logs for specific error messages
4. Open a new issue with detailed reproduction steps

## 📊 Feature Implementation Status

| Feature | Status | Description | Planned Release |
| --- | --- | --- | --- |
| **Authentication & Authorization** |  |  |  |
| User Registration | ✅ Implemented | User signup with email verification | v1.0 |
| Multi-factor Authentication | ✅ Implemented | SMS and authenticator app support | v1.0 |
| Role-based Access Control | ✅ Implemented | Granular permission management | v1.0 |
| OAuth Integration | ✅ Implemented | Support for Google, GitHub, Microsoft | v1.1 |
| **Payment Processing** |  |  |  |
| Credit Card Processing | ✅ Implemented | Major card networks support | v1.0 |
| ACH Transfers | ✅ Implemented | Direct bank account transfers | v1.0 |
| Digital Wallet Integration | ✅ Implemented | Apple Pay, Google Pay, PayPal | v1.1 |
| Recurring Payments | ✅ Implemented | Subscription billing automation | v1.1 |
| **Accounting & Reconciliation** |  |  |  |
| Double-Entry Accounting | ✅ Implemented | Automated journal entries | v1.0 |
| Financial Reporting | ✅ Implemented | Balance sheet, income statement | v1.0 |
| Reconciliation Tools | ✅ Implemented | Account matching and verification | v1.1 |
| Tax Calculation | 🔄 In Progress | Automated tax computation | v1.2 |
| **Analytics & Reporting** |  |  |  |
| Interactive Dashboards | ✅ Implemented | Visual KPI representation | v1.0 |
| Transaction Analysis | ✅ Implemented | Detailed transaction breakdowns | v1.0 |
| Trend Visualization | ✅ Implemented | Historical data analysis | v1.1 |
| Predictive Analytics | 🔄 In Progress | ML-based financial forecasting | v1.2 |
| **Credit Management** |  |  |  |
| Credit Scoring | ✅ Implemented | Risk assessment algorithms | v1.0 |
| Loan Processing | ✅ Implemented | Application and approval workflow | v1.0 |
| Repayment Tracking | ✅ Implemented | Automated payment monitoring | v1.1 |
| Default Prediction | 🔄 In Progress | ML-based risk forecasting | v1.2 |
| **Mobile Frontend** |  |  |  |
| Authentication | ✅ Implemented | Secure login and registration | v1.2 |
| Dashboard | ✅ Implemented | Key metrics and overview | v1.2 |
| Payments | ✅ Implemented | Transaction management | v1.2 |
| Analytics | ✅ Implemented | Mobile-optimized data visualization | v1.2 |
| Accounting | ✅ Implemented | Financial report viewing | v1.2 |
| Credit Management | ✅ Implemented | Score monitoring and loan management | v1.2 |
| Offline Support | 🔄 In Progress | Core functionality without internet | v1.3 |
| Push Notifications | 🔄 In Progress | Real-time alerts and updates | v1.3 |

## 🤝 Contributing

We welcome contributions to FinFlow! Please see our [Contributing Guide](CONTRIBUTING.md) for more details on how to get involved.

## 📄 License

FinFlow is licensed under the [MIT License](LICENSE).
