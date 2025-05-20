#!/bin/bash

# FinFlow Environment Setup Script
# This script sets up the development environment for the FinFlow platform

set -e

echo "🚀 Setting up FinFlow development environment..."

# Check for required tools
check_command() {
  if ! command -v $1 &> /dev/null; then
    echo "❌ $1 is required but not installed. Please install it and try again."
    exit 1
  fi
}

check_command node
check_command npm
check_command docker
check_command docker-compose

# Install global dependencies
echo "📦 Installing global dependencies..."
npm install -g typescript ts-node

# Setup backend services
echo "🔧 Setting up backend services..."
for service in backend/auth-service backend/payments-service backend/accounting-service backend/analytics-service; do
  if [ -d "$service" ]; then
    echo "Setting up $service..."
    (cd $service && npm install)
  fi
done

# Setup credit engine (Python)
if [ -d "backend/credit-engine" ]; then
  echo "Setting up credit engine..."
  if command -v python3 &> /dev/null; then
    python_cmd="python3"
  elif command -v python &> /dev/null; then
    python_cmd="python"
  else
    echo "❌ Python is required but not installed. Please install Python 3.x and try again."
    exit 1
  fi
  
  # Check for virtual environment
  if command -v virtualenv &> /dev/null; then
    (cd backend/credit-engine && virtualenv venv && source venv/bin/activate && pip install -r requirements.txt && deactivate)
  else
    echo "⚠️ virtualenv not found. Installing dependencies globally (not recommended)..."
    (cd backend/credit-engine && $python_cmd -m pip install -r requirements.txt)
  fi
fi

# Setup frontend
if [ -d "frontend" ]; then
  echo "🖥️ Setting up frontend..."
  (cd frontend && npm install)
fi

# Setup Kafka (if needed)
if [ -d "kafka" ]; then
  echo "📨 Setting up Kafka..."
  (cd kafka && npm install)
fi

# Setup monitoring (if needed)
if [ -d "monitoring" ]; then
  echo "📊 Setting up monitoring..."
  (cd monitoring && npm install)
fi

# Create necessary directories
mkdir -p logs data/mongodb data/postgres data/kafka

# Setup environment variables
echo "🔐 Setting up environment variables..."
if [ ! -f ".env" ]; then
  cat > .env << EOL
# FinFlow Environment Variables
NODE_ENV=development

# Auth Service
AUTH_PORT=3001
JWT_SECRET=your_jwt_secret_key_change_in_production
JWT_EXPIRY=24h

# Payments Service
PAYMENTS_PORT=3002
STRIPE_API_KEY=your_stripe_api_key

# Accounting Service
ACCOUNTING_PORT=3003

# Analytics Service
ANALYTICS_PORT=3004

# Credit Engine
CREDIT_ENGINE_PORT=3005

# Database
POSTGRES_USER=finflow
POSTGRES_PASSWORD=finflow_password
POSTGRES_DB=finflow
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Kafka
KAFKA_BROKER=localhost:9092
KAFKA_ZOOKEEPER=localhost:2181
EOL
  echo "✅ Created default .env file. Please update with your actual configuration."
else
  echo "⚠️ .env file already exists. Skipping creation."
fi

echo "🔄 Checking Docker services..."
docker-compose -f infrastructure/docker-compose.yml pull

echo "✅ FinFlow environment setup complete!"
echo "🚀 To start the application, run: docker-compose -f infrastructure/docker-compose.yml up -d"
echo "📝 Then start each service with: npm run dev (in their respective directories)"
