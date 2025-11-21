# FinFlow Backend: Microservices Architecture

## Financial Operations & Workflow Platform - Backend Services

FinFlow's backend is a comprehensive, polyglot microservices architecture designed to power a modern financial operations platform. It provides secure authentication, real-time transaction processing, double-entry accounting, advanced analytics, and machine learning-driven credit management. The architecture is built for **scalability**, **resilience**, and **maintainability**, with each service focusing on a specific domain of financial operations.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
  - [Technology Stack](#technology-stack)
  - [Microservices Overview](#microservices-overview)
  - [Common Components](#common-components)
  - [Event-Driven Communication](#event-driven-communication)
- [Backend Services Detail](#backend-services-detail)
- [Getting Started](#getting-started)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Deployment](#deployment)

---

## Overview

The FinFlow backend is a collection of independent services that communicate primarily through a message broker (Kafka) and RESTful APIs. This design allows for independent scaling, technology flexibility, and isolated development cycles, ensuring the platform can evolve rapidly while maintaining high availability and consistency.

## Architecture

### Technology Stack

The FinFlow backend employs a **polyglot persistence** and **polyglot programming** approach, leveraging the best tool for each specific service's requirements.

| Category                       | Technology                               | Purpose                                                                | Services Used In                                                                                  |
| :----------------------------- | :--------------------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------ |
| **Primary Language (API)**     | **TypeScript/Node.js** (Express/Fastify) | Core business logic, high-concurrency I/O operations.                  | Auth, Accounting, Analytics, Payments, Integration, Multi-Tenant, Performance, Realtime Analytics |
| **Primary Language (ML/Data)** | **Python** (FastAPI, Flask)              | Machine learning, data processing, and complex financial calculations. | Transaction, Credit Engine, AI Features, Compliance, Tax Automation                               |
| **Database**                   | **PostgreSQL**                           | Primary relational data store (e.g., Accounting, Auth, Credit).        | Accounting, Auth, Credit Engine, Compliance                                                       |
| **Message Broker**             | **Apache Kafka**                         | Asynchronous, event-driven communication between services.             | All services (for events like `TransactionCreated`, `PaymentProcessed`)                           |
| **Caching/Session**            | **Redis**                                | High-speed data caching and session management.                        | Auth, Analytics, Payments                                                                         |
| **ML/Data Science**            | **Scikit-learn, Pandas, XGBoost**        | Credit scoring, forecasting, and financial advisory.                   | Credit Engine, AI Features                                                                        |

### Microservices Overview

The backend is structured into distinct, domain-specific services.

| Service Directory            | Primary Function                                                                       | Primary Language | Key Dependencies / Framework          |
| :--------------------------- | :------------------------------------------------------------------------------------- | :--------------- | :------------------------------------ |
| `auth-service`               | User Authentication, Authorization, Session Management, MFA, RBAC.                     | TypeScript       | Node.js, Express                      |
| `accounting-service`         | Double-Entry Accounting, Financial Reporting (Balance Sheet, Income Statement).        | TypeScript       | Node.js, PostgreSQL                   |
| `analytics-service`          | Data Visualization, Trend Analysis, Reporting, Dashboard Metrics.                      | TypeScript       | Node.js, MongoDB, Redis               |
| `payments-service`           | Payment Processing, Gateway Integration (Stripe, PayPal, Square), Payment Lifecycle.   | TypeScript       | Node.js, Redis                        |
| `transaction-service`        | Transaction Validation, Processing, and Core Ledger Entry.                             | Python           | FastAPI, PostgreSQL                   |
| `credit-engine`              | Machine Learning-based Credit Scoring, Risk Assessment, Loan Offer Generation.         | Python           | FastAPI, Scikit-learn, Joblib         |
| `ai-features-service`        | Advanced AI/ML for Cash Flow Forecasting, Financial Advisory, and Predictive Modeling. | Python           | FastAPI, XGBoost, Prophet, TensorFlow |
| `compliance-service`         | Regulatory Compliance (GDPR, PSD2, AML/CFT) and Audit Trail Management.                | Python           | General Python, PostgreSQL            |
| `tax_automation`             | Automated Tax Calculation and Rule Management (e.g., VAT, Sales Tax).                  | Python           | Flask                                 |
| `integration-service`        | Third-party Financial System Integrations (e.g., QuickBooks, Xero).                    | TypeScript       | Node.js, Express                      |
| `multi-tenant-service`       | Data Isolation, Tenant Management, and Multi-Tenant Architecture Support.              | TypeScript       | Node.js, Express                      |
| `realtime-analytics-service` | Real-time Anomaly Detection and Streaming Analytics.                                   | TypeScript       | Node.js, Kafka Streaming              |
| `performance-service`        | Database Optimization and Performance Monitoring.                                      | TypeScript       | Node.js, Database Optimizer           |

### Common Components

The `common` directory contains shared utilities to ensure consistency and reduce boilerplate across the Node.js/TypeScript services.

| Component File | Description                                                                        |
| :------------- | :--------------------------------------------------------------------------------- |
| `app.ts`       | Standardized application setup and middleware configuration.                       |
| `database.ts`  | Centralized database connection and ORM initialization (primarily for PostgreSQL). |
| `index.ts`     | Entry point for the common module.                                                 |
| `kafka.ts`     | Kafka producer and consumer utilities for event-driven communication.              |
| `logger.ts`    | Centralized, structured logging configuration for all services.                    |
| `passport.ts`  | Shared Passport.js configuration for authentication strategies.                    |
| `server.ts`    | Standardized HTTP server creation and startup logic.                               |

### Event-Driven Communication

Communication between services is decoupled using **Apache Kafka** as the central event bus.

| Event Type           | Producer Service    | Consumer Services                         | Purpose                                                                                         |
| :------------------- | :------------------ | :---------------------------------------- | :---------------------------------------------------------------------------------------------- |
| `TransactionCreated` | Transaction Service | Accounting, Analytics, Realtime Analytics | Notifies other services of a new transaction for ledger updates, reporting, and anomaly checks. |
| `PaymentProcessed`   | Payments Service    | Accounting, Credit Engine                 | Triggers accounting entries and updates credit risk models.                                     |
| `UserRegistered`     | Auth Service        | Multi-Tenant, Analytics                   | Initializes tenant data and user-specific analytics profiles.                                   |
| `ComplianceAlert`    | Compliance Service  | Auth, Performance                         | Signals a regulatory issue (e.g., AML flag) that may require action.                            |

## Backend Services Detail

This section provides a deeper look into the core responsibilities and data models of key services.

### Auth Service (`auth-service`)

| Feature            | Description                                                                      |
| :----------------- | :------------------------------------------------------------------------------- |
| **Authentication** | JWT-based token authentication, OAuth integration.                               |
| **Authorization**  | Role-Based Access Control (RBAC) with granular permissions.                      |
| **Security**       | Multi-Factor Authentication (MFA), password policy enforcement, account lockout. |
| **Models**         | `user.model.ts`, `user-preference.model.ts`                                      |

### Accounting Service (`accounting-service`)

| Feature        | Description                                                                          |
| :------------- | :----------------------------------------------------------------------------------- |
| **Core**       | Double-entry accounting engine with robust transaction validation.                   |
| **Reporting**  | Automated generation of Balance Sheets, Income Statements, and Cash Flow Statements. |
| **Compliance** | Trial balance verification, fiscal year management, multi-currency support.          |
| **Models**     | `invoice.model.ts`, `journal-entry.model.ts`, `transaction.model.ts`                 |

### Credit Engine (`credit-engine`)

| Feature     | Description                                                                                 |
| :---------- | :------------------------------------------------------------------------------------------ |
| **Scoring** | Machine Learning models (trained via `train_credit_model.py`) for credit score calculation. |
| **Risk**    | Financial data analysis for risk assessment and creditworthiness determination.             |
| **Offers**  | Automated generation of customized loan offers and terms.                                   |
| **Models**  | `models.py` (Pydantic models for request/response)                                          |

## Getting Started

### Prerequisites

You will need the following installed on your system:

- **Node.js** (v16.x or later) and **npm**
- **Python** (v3.9 or later) and **pip**
- **Docker** and **Docker Compose** (recommended for local environment setup)
- **PostgreSQL** database instance
- **Redis** instance
- **Kafka** broker (or use a local Kafka setup via Docker Compose)

### Quick Setup with Docker Compose

The recommended way to run the entire FinFlow backend locally is using Docker Compose.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/abrar2030/FinFlow.git
    cd FinFlow/backend
    ```
2.  **Configure Environment:**
    Create a `.env` file in the `backend` directory based on a provided template (if available) or the environment variables listed in the service details.
3.  **Build and Run:**
    ```bash
    docker-compose up --build
    ```
    This command will build all service images, set up the necessary network, and start all microservices, databases, and message brokers.

## API Documentation

Each service exposes its own set of RESTful endpoints. The primary API documentation is typically generated using tools like **Swagger/OpenAPI** for the FastAPI and Express services.

| Service Type             | Documentation Access                                                                                     |
| :----------------------- | :------------------------------------------------------------------------------------------------------- |
| **Python (FastAPI)**     | Navigate to `http://localhost:<PORT>/docs` (e.g., for Transaction Service: `http://localhost:3002/docs`) |
| **TypeScript (Express)** | Endpoints are documented inline or via a separate documentation tool (check service READMEs).            |

## Testing

Each service contains its own test suite for unit and integration testing.

| Service Type               | Test Runner                                            | Command to Run Tests                  |
| :------------------------- | :----------------------------------------------------- | :------------------------------------ |
| **TypeScript/Node.js**     | Jest or Mocha (inferred from `package.json` structure) | `npm test` (inside service directory) |
| **Python (FastAPI/Flask)** | Pytest                                                 | `pytest` (inside service directory)   |

## Deployment

The architecture is designed for containerized deployment.

| Method         | Description                                                                                                                                 | Key Files                       |
| :------------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :------------------------------ |
| **Docker**     | Each service has a dedicated `Dockerfile` for containerization.                                                                             | `*/Dockerfile`                  |
| **Kubernetes** | The `credit-engine` service specifically includes a `kubernetes.yaml` manifest, suggesting a K8s deployment strategy for the ML components. | `credit-engine/kubernetes.yaml` |

---
