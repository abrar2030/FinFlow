# Configuration Guide

Complete configuration reference for all FinFlow services and components.

---

## Table of Contents

- [Overview](#overview)
- [Environment Variables](#environment-variables)
- [Service Configuration](#service-configuration)
- [Database Configuration](#database-configuration)
- [Infrastructure Configuration](#infrastructure-configuration)
- [Configuration Examples](#configuration-examples)

---

## Overview

FinFlow uses environment variables for configuration. Each service has its own `.env` file, with common configuration inherited from the root `.env` file.

**Configuration Files:**

- `/.env` - Global configuration
- `/backend/{service}/.env` - Service-specific configuration
- `/web-frontend/.env` - Web frontend configuration
- `/mobile-frontend/.env` - Mobile app configuration

---

## Environment Variables

### Common Variables (All Services)

| Option          | Type   | Default                  | Description                           | Where to set (env/file) |
| --------------- | ------ | ------------------------ | ------------------------------------- | ----------------------- |
| `NODE_ENV`      | string | `development`            | Environment mode                      | `.env` file             |
| `LOG_LEVEL`     | string | `info`                   | Logging level (debug/info/warn/error) | `.env` file             |
| `PORT`          | number | Service-specific         | Service port number                   | `.env` file             |
| `KAFKA_BROKERS` | string | `localhost:9092`         | Kafka broker addresses                | `.env` file             |
| `REDIS_URL`     | string | `redis://localhost:6379` | Redis connection URL                  | `.env` file             |

---

### Auth Service Configuration

| Option                       | Type    | Default | Description                  | Where to set      |
| ---------------------------- | ------- | ------- | ---------------------------- | ----------------- |
| `PORT`                       | number  | `3001`  | Service port                 | `.env`            |
| `DATABASE_URL`               | string  | -       | PostgreSQL connection string | `.env`            |
| `JWT_SECRET`                 | string  | -       | Secret key for JWT signing   | `.env` (required) |
| `JWT_EXPIRATION`             | string  | `24h`   | JWT token expiration time    | `.env`            |
| `REFRESH_TOKEN_EXPIRATION`   | string  | `7d`    | Refresh token expiration     | `.env`            |
| `BCRYPT_ROUNDS`              | number  | `10`    | Password hashing rounds      | `.env`            |
| `MFA_ENABLED`                | boolean | `false` | Enable multi-factor auth     | `.env`            |
| `OAUTH_GOOGLE_CLIENT_ID`     | string  | -       | Google OAuth client ID       | `.env`            |
| `OAUTH_GOOGLE_CLIENT_SECRET` | string  | -       | Google OAuth secret          | `.env`            |
| `OAUTH_GITHUB_CLIENT_ID`     | string  | -       | GitHub OAuth client ID       | `.env`            |
| `OAUTH_GITHUB_CLIENT_SECRET` | string  | -       | GitHub OAuth secret          | `.env`            |

**Example `.env` for Auth Service:**

```bash
NODE_ENV=development
PORT=3001
DATABASE_URL=postgresql://user:password@localhost:5432/finflow
JWT_SECRET=your-super-secret-key-change-in-production
JWT_EXPIRATION=24h
REFRESH_TOKEN_EXPIRATION=7d
REDIS_URL=redis://localhost:6379
KAFKA_BROKERS=localhost:9092
MFA_ENABLED=true
```

---

### Payments Service Configuration

| Option                   | Type   | Default   | Description                    | Where to set      |
| ------------------------ | ------ | --------- | ------------------------------ | ----------------- |
| `PORT`                   | number | `3002`    | Service port                   | `.env`            |
| `STRIPE_API_KEY`         | string | -         | Stripe secret key              | `.env` (required) |
| `STRIPE_PUBLISHABLE_KEY` | string | -         | Stripe publishable key         | `.env`            |
| `STRIPE_WEBHOOK_SECRET`  | string | -         | Stripe webhook secret          | `.env`            |
| `PAYPAL_CLIENT_ID`       | string | -         | PayPal client ID               | `.env`            |
| `PAYPAL_CLIENT_SECRET`   | string | -         | PayPal secret                  | `.env`            |
| `PAYPAL_MODE`            | string | `sandbox` | PayPal mode (sandbox/live)     | `.env`            |
| `SQUARE_ACCESS_TOKEN`    | string | -         | Square access token            | `.env`            |
| `SQUARE_LOCATION_ID`     | string | -         | Square location ID             | `.env`            |
| `PAYMENT_TIMEOUT_MS`     | number | `30000`   | Payment timeout (milliseconds) | `.env`            |

**Example `.env` for Payments Service:**

```bash
NODE_ENV=production
PORT=3002
STRIPE_API_KEY=sk_live_your_stripe_key
STRIPE_PUBLISHABLE_KEY=pk_live_your_publishable_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_secret
PAYPAL_MODE=live
REDIS_URL=redis://localhost:6379
KAFKA_BROKERS=kafka-1:9092,kafka-2:9092
```

---

### Accounting Service Configuration

| Option                  | Type    | Default | Description                   | Where to set |
| ----------------------- | ------- | ------- | ----------------------------- | ------------ |
| `PORT`                  | number  | `3003`  | Service port                  | `.env`       |
| `DATABASE_URL`          | string  | -       | PostgreSQL connection string  | `.env`       |
| `FISCAL_YEAR_START`     | string  | `01-01` | Fiscal year start (MM-DD)     | `.env`       |
| `DEFAULT_CURRENCY`      | string  | `USD`   | Default currency code         | `.env`       |
| `ENABLE_MULTI_CURRENCY` | boolean | `false` | Enable multi-currency support | `.env`       |
| `EXCHANGE_RATE_API_KEY` | string  | -       | Exchange rate API key         | `.env`       |

**Example `.env`:**

```bash
PORT=3003
DATABASE_URL=postgresql://user:password@localhost:5432/finflow
FISCAL_YEAR_START=01-01
DEFAULT_CURRENCY=USD
ENABLE_MULTI_CURRENCY=true
EXCHANGE_RATE_API_KEY=your_api_key
```

---

### Analytics Service Configuration

| Option              | Type   | Default | Description               | Where to set |
| ------------------- | ------ | ------- | ------------------------- | ------------ |
| `PORT`              | number | `3004`  | Service port              | `.env`       |
| `MONGODB_URL`       | string | -       | MongoDB connection string | `.env`       |
| `REDIS_URL`         | string | -       | Redis connection URL      | `.env`       |
| `CACHE_TTL_SECONDS` | number | `300`   | Cache TTL (seconds)       | `.env`       |
| `FORECAST_MONTHS`   | number | `12`    | Default forecast period   | `.env`       |

---

### Credit Engine Configuration

| Option             | Type   | Default                     | Description                  | Where to set |
| ------------------ | ------ | --------------------------- | ---------------------------- | ------------ |
| `PORT`             | number | `3005`                      | Service port                 | `.env`       |
| `DATABASE_URL`     | string | -                           | PostgreSQL connection string | `.env`       |
| `MODEL_PATH`       | string | `./models/credit_model.pkl` | ML model file path           | `.env`       |
| `MIN_CREDIT_SCORE` | number | `0.5`                       | Minimum approval score       | `.env`       |
| `MAX_LOAN_AMOUNT`  | number | `100000`                    | Maximum loan amount          | `.env`       |

**Example `.env`:**

```bash
PORT=3005
DATABASE_URL=postgresql://user:password@localhost:5432/finflow
MODEL_PATH=/app/models/credit_model.pkl
MIN_CREDIT_SCORE=0.6
MAX_LOAN_AMOUNT=100000
KAFKA_BROKERS=localhost:9092
```

---

### Web Frontend Configuration

| Option                | Type   | Default                 | Description               | Where to set |
| --------------------- | ------ | ----------------------- | ------------------------- | ------------ |
| `VITE_API_URL`        | string | `http://localhost:8080` | API Gateway URL           | `.env`       |
| `VITE_WS_URL`         | string | `ws://localhost:8080`   | WebSocket URL             | `.env`       |
| `VITE_ENVIRONMENT`    | string | `development`           | Environment name          | `.env`       |
| `VITE_SENTRY_DSN`     | string | -                       | Sentry error tracking DSN | `.env`       |
| `VITE_GA_TRACKING_ID` | string | -                       | Google Analytics ID       | `.env`       |

**Example `.env`:**

```bash
VITE_API_URL=https://api.finflow.com
VITE_WS_URL=wss://api.finflow.com
VITE_ENVIRONMENT=production
VITE_SENTRY_DSN=https://your-sentry-dsn
```

---

### Mobile Frontend Configuration

| Option              | Type    | Default                 | Description                 | Where to set |
| ------------------- | ------- | ----------------------- | --------------------------- | ------------ |
| `API_URL`           | string  | `http://localhost:8080` | API Gateway URL             | `.env`       |
| `ENVIRONMENT`       | string  | `development`           | Environment name            | `.env`       |
| `ENABLE_BIOMETRICS` | boolean | `true`                  | Enable biometric auth       | `.env`       |
| `OFFLINE_MODE`      | boolean | `true`                  | Enable offline capabilities | `.env`       |

---

## Database Configuration

### PostgreSQL

**Connection String Format:**

```
postgresql://username:password@hostname:port/database?options
```

**Common Options:**

- `sslmode=require` - Enforce SSL connection
- `max_connections=100` - Connection pool size
- `idle_in_transaction_session_timeout=30000` - Transaction timeout

**Example:**

```bash
DATABASE_URL=postgresql://finflow_user:secure_password@localhost:5432/finflow?sslmode=require&max_connections=50
```

---

### MongoDB

**Connection String Format:**

```
mongodb://username:password@hostname:port/database?options
```

**Example:**

```bash
MONGODB_URL=mongodb://finflow_user:password@localhost:27017/finflow_analytics?authSource=admin&maxPoolSize=50
```

---

### Redis

**Connection String Format:**

```
redis://[:password@]hostname:port[/database]
```

**Example:**

```bash
REDIS_URL=redis://:password@localhost:6379/0
```

---

## Infrastructure Configuration

### Kafka Configuration

**Environment Variables:**

```bash
KAFKA_BROKERS=kafka-1:9092,kafka-2:9092,kafka-3:9092
KAFKA_CLIENT_ID=finflow-service
KAFKA_GROUP_ID=finflow-consumers
KAFKA_SSL_ENABLED=true
KAFKA_SASL_USERNAME=your_username
KAFKA_SASL_PASSWORD=your_password
```

**Topic Configuration:**

- `payment.events` - Payment-related events
- `transaction.events` - Transaction events
- `user.events` - User authentication events
- `analytics.events` - Analytics data stream

---

### API Gateway Configuration

| Option                    | Type   | Default | Description             |
| ------------------------- | ------ | ------- | ----------------------- |
| `PORT`                    | number | `8080`  | Gateway port            |
| `RATE_LIMIT_WINDOW_MS`    | number | `60000` | Rate limit window (ms)  |
| `RATE_LIMIT_MAX_REQUESTS` | number | `100`   | Max requests per window |
| `CORS_ORIGINS`            | string | `*`     | Allowed CORS origins    |
| `AUTH_SERVICE_URL`        | string | -       | Auth service URL        |
| `PAYMENTS_SERVICE_URL`    | string | -       | Payments service URL    |

---

## Configuration Examples

### Development Environment

**Backend Service (Node.js):**

```bash
NODE_ENV=development
PORT=3001
LOG_LEVEL=debug
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/finflow_dev
REDIS_URL=redis://localhost:6379
KAFKA_BROKERS=localhost:9092
JWT_SECRET=dev-secret-key-not-for-production
```

### Production Environment

**Backend Service (Node.js):**

```bash
NODE_ENV=production
PORT=3001
LOG_LEVEL=info
DATABASE_URL=postgresql://prod_user:secure_password@db.finflow.com:5432/finflow?sslmode=require
REDIS_URL=rediss://:password@redis.finflow.com:6379
KAFKA_BROKERS=kafka-1.finflow.com:9092,kafka-2.finflow.com:9092
JWT_SECRET=${JWT_SECRET_FROM_SECRETS_MANAGER}
SENTRY_DSN=https://your-sentry-dsn
```

### Docker Compose Environment

**`.env` file:**

```bash
# Database
POSTGRES_USER=finflow
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=finflow

# Redis
REDIS_PASSWORD=redis_password

# Services
AUTH_SERVICE_PORT=3001
PAYMENTS_SERVICE_PORT=3002
ACCOUNTING_SERVICE_PORT=3003

# Kafka
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092
```

---

## Configuration Best Practices

1. **Never commit secrets** - Use `.env.example` as template, keep `.env` in `.gitignore`
2. **Use environment-specific configs** - Separate configs for dev/staging/production
3. **Validate on startup** - Services should validate required config on startup
4. **Use secret managers** - AWS Secrets Manager, HashiCorp Vault for production
5. **Document all options** - Keep this guide updated with new configuration options

---

For deployment configuration, see [INSTALLATION.md](INSTALLATION.md).
For infrastructure setup, see [ARCHITECTURE.md](ARCHITECTURE.md).
