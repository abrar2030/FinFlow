# Installation Guide

This guide covers all installation methods for FinFlow, including prerequisites, environment setup, and platform-specific instructions.

---

## Table of Contents

- [System Prerequisites](#system-prerequisites)
- [Installation Methods](#installation-methods)
  - [Docker Compose (Recommended)](#docker-compose-recommended)
  - [Manual Installation](#manual-installation)
  - [Kubernetes Deployment](#kubernetes-deployment)
- [Environment Configuration](#environment-configuration)
- [Verification](#verification)
- [Next Steps](#next-steps)

---

## System Prerequisites

### Required Software

| Software           | Minimum Version | Purpose                       | Installation                                                      |
| ------------------ | --------------- | ----------------------------- | ----------------------------------------------------------------- |
| **Node.js**        | v16.0+          | Backend services (TypeScript) | [nodejs.org](https://nodejs.org)                                  |
| **Python**         | v3.9+           | ML services, data processing  | [python.org](https://python.org)                                  |
| **Docker**         | v20.10+         | Containerization              | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| **Docker Compose** | v2.0+           | Multi-container orchestration | Included with Docker Desktop                                      |
| **PostgreSQL**     | v13+            | Primary relational database   | [postgresql.org](https://postgresql.org)                          |
| **MongoDB**        | v5.0+           | Analytics data storage        | [mongodb.com](https://mongodb.com)                                |
| **Redis**          | v6.0+           | Caching and session storage   | [redis.io](https://redis.io)                                      |
| **Apache Kafka**   | v3.0+           | Event streaming               | [kafka.apache.org](https://kafka.apache.org)                      |

### Optional Tools

| Tool          | Purpose                       | Installation                                                              |
| ------------- | ----------------------------- | ------------------------------------------------------------------------- |
| **kubectl**   | Kubernetes cluster management | [kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/) |
| **Terraform** | Infrastructure provisioning   | [terraform.io/downloads](https://www.terraform.io/downloads.html)         |
| **AWS CLI**   | AWS resource management       | [aws.amazon.com/cli](https://aws.amazon.com/cli/)                         |

### System Requirements

| Component   | Development | Production                |
| ----------- | ----------- | ------------------------- |
| **CPU**     | 4 cores     | 8+ cores                  |
| **RAM**     | 8 GB        | 16+ GB                    |
| **Storage** | 20 GB       | 100+ GB (SSD recommended) |
| **Network** | Broadband   | High-speed, low-latency   |

---

## Installation Methods

### Docker Compose (Recommended)

The fastest way to get FinFlow running locally with all services.

#### Step 1: Clone Repository

```bash
git clone https://github.com/quantsingularity/FinFlow.git
cd FinFlow
```

#### Step 2: Run Setup Script

The setup script installs dependencies and configures the environment:

```bash
chmod +x scripts/finflow-setup.sh
./scripts/finflow-setup.sh
```

**Options:**

```bash
./scripts/finflow-setup.sh --help
# Available options:
#   -e, --environment ENV     Set environment (development, staging, production)
#   -s, --skip-dependencies   Skip dependency installation
#   --services SERVICES       Setup specific services (comma-separated)
```

#### Step 3: Start Services

```bash
# Start all services
docker-compose up --build

# Or run in detached mode
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

#### Step 4: Verify Installation

```bash
# Check service status
docker-compose ps

# Test API Gateway
curl http://localhost:8080/health

# Access web frontend
open http://localhost:3000
```

---

### Manual Installation

For development or when Docker is not available.

#### Step 1: Install Backend Services

**TypeScript/Node.js Services:**

```bash
# Auth Service
cd backend/auth-service
npm install
npm run build
npm run start:dev

# Payments Service
cd ../payments-service
npm install
npm run build
npm run start:dev

# Accounting Service
cd ../accounting-service
npm install
npm run build
npm run start:dev

# Analytics Service
cd ../analytics-service
npm install
npm run build
npm run start:dev
```

**Python Services:**

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
cd backend
pip install -r requirements.txt

# Transaction Service
cd transaction-service
uvicorn src.main:app --reload --port 3006

# Credit Engine
cd ../credit-engine
uvicorn src.main:app --reload --port 3005

# AI Features Service
cd ../ai-features-service
python src/main.py

# Compliance Service
cd ../compliance-service
python src/main.py
```

#### Step 2: Install Frontend

**Web Frontend:**

```bash
cd web-frontend
npm install
npm run dev
```

**Mobile Frontend:**

```bash
cd mobile-frontend
npm install
npm start
```

#### Step 3: Setup Databases

**PostgreSQL:**

```bash
# Create database
createdb finflow

# Run migrations (for each service with DB)
cd backend/auth-service
npm run migrate

cd ../accounting-service
npm run migrate
```

**MongoDB:**

```bash
# Start MongoDB
mongod --config /usr/local/etc/mongod.conf

# Create database (auto-created on first use)
```

**Redis:**

```bash
# Start Redis
redis-server

# Or with config
redis-server /usr/local/etc/redis.conf
```

#### Step 4: Setup Kafka

```bash
cd kafka
npm install
npm run start:dev
```

---

### Kubernetes Deployment

For production or scalable deployments.

#### Prerequisites

- Kubernetes cluster (EKS, GKE, AKS, or local minikube)
- kubectl configured
- Docker images built and pushed to registry

#### Step 1: Provision Infrastructure (AWS with Terraform)

```bash
cd infrastructure/terraform

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and apply
terraform init
terraform plan -out=plan.out
terraform apply plan.out

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name finflow-cluster
```

#### Step 2: Deploy to Kubernetes

```bash
cd infrastructure/kubernetes

# Create namespace
kubectl create namespace finflow-prod

# Create secrets
cp secrets.example.yaml secrets.yaml
# Edit secrets.yaml - replace all REPLACE_ME values
kubectl apply -f secrets.yaml

# Deploy databases
kubectl apply -f databases/

# Deploy backend services
kubectl apply -f auth-service/
kubectl apply -f payments-service/
kubectl apply -f accounting-service/
kubectl apply -f analytics-service/
kubectl apply -f credit-engine/

# Deploy API Gateway and Frontend
kubectl apply -f api-gateway/
kubectl apply -f frontend/

# Verify deployment
kubectl get pods -n finflow-prod
kubectl get services -n finflow-prod
```

#### Step 3: Deploy Monitoring

```bash
kubectl apply -f infrastructure/monitoring/kubernetes/

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

---

## Environment Configuration

### Required Environment Variables

Create `.env` files in the appropriate directories:

**Backend Services (TypeScript):**

```bash
# Example: backend/auth-service/.env
NODE_ENV=development
PORT=3001
DATABASE_URL=postgresql://user:password@localhost:5432/finflow
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION=24h
KAFKA_BROKERS=localhost:9092
```

**Backend Services (Python):**

```bash
# Example: backend/credit-engine/.env
ENVIRONMENT=development
PORT=3005
DATABASE_URL=postgresql://user:password@localhost:5432/finflow
KAFKA_BROKERS=localhost:9092
MODEL_PATH=./models/credit_model.pkl
```

**Web Frontend:**

```bash
# web-frontend/.env
VITE_API_URL=http://localhost:8080
VITE_WS_URL=ws://localhost:8080
VITE_ENVIRONMENT=development
```

**Mobile Frontend:**

```bash
# mobile-frontend/.env
API_URL=http://localhost:8080
ENVIRONMENT=development
```

See [CONFIGURATION.md](CONFIGURATION.md) for complete configuration reference.

---

## Verification

### Health Checks

| Service                | Endpoint                     | Expected Response       |
| ---------------------- | ---------------------------- | ----------------------- |
| **API Gateway**        | http://localhost:8080/health | `{"status": "ok"}`      |
| **Auth Service**       | http://localhost:3001/health | `{"status": "healthy"}` |
| **Payments Service**   | http://localhost:3002/health | `{"status": "healthy"}` |
| **Accounting Service** | http://localhost:3003/health | `{"status": "healthy"}` |
| **Analytics Service**  | http://localhost:3004/health | `{"status": "healthy"}` |
| **Credit Engine**      | http://localhost:3005/health | `{"status": "healthy"}` |

### Running Verification Script

```bash
cd backend
chmod +x verify_installation.sh
./verify_installation.sh
```

### Manual Testing

```bash
# Test authentication
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","name":"Test User"}'

# Test payment creation (requires auth token)
curl -X POST http://localhost:3002/api/payments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"amount":100,"currency":"usd","processorType":"stripe"}'
```

---

## Next Steps

After successful installation:

1. **Read Usage Guide**: See [USAGE.md](USAGE.md) for common workflows
2. **Explore Examples**: Check [examples/](examples/) for real-world scenarios
3. **Configure Services**: Review [CONFIGURATION.md](CONFIGURATION.md) for detailed configuration
4. **Setup Monitoring**: See [ARCHITECTURE.md](ARCHITECTURE.md#monitoring) for observability setup

---

## Installation by Platform

| OS / Platform             | Recommended Method       | Notes                                                       |
| ------------------------- | ------------------------ | ----------------------------------------------------------- |
| **macOS**                 | Docker Compose           | Use Docker Desktop; install Node.js via Homebrew            |
| **Linux (Ubuntu/Debian)** | Docker Compose or Manual | Install Docker via apt; use nvm for Node.js                 |
| **Linux (RHEL/CentOS)**   | Docker Compose           | Install Docker via yum; use nvm for Node.js                 |
| **Windows**               | Docker Compose           | Use Docker Desktop with WSL2; install Node.js via installer |
| **Cloud (AWS)**           | Kubernetes (EKS)         | Use provided Terraform configs                              |
| **Cloud (GCP)**           | Kubernetes (GKE)         | Adapt Terraform configs for GCP                             |
| **Cloud (Azure)**         | Kubernetes (AKS)         | Adapt Terraform configs for Azure                           |

---

## Troubleshooting Installation

For common installation issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#installation-issues).
