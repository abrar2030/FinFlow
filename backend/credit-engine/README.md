# FinFlow Credit Engine

This service provides AI-driven credit scoring and loan offers as part of the FinFlow platform.

## Features

- Credit scoring based on financial metrics
- Loan offers generation based on credit scores
- GDPR compliance endpoints for data export and deletion
- Comprehensive audit logging
- OpenAPI documentation
- Kubernetes deployment configuration

## Setup

### Prerequisites

- Python 3.11+
- Kafka cluster for event streaming
- Access to the Authentication service for JWT validation

### Installation

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Train the credit scoring model:
```bash
python src/train_credit_model.py
```

### Configuration

Set the following environment variables:

- `PORT`: Service port (default: 8000)
- `JWT_SECRET`: Secret key for JWT validation
- `KAFKA_BROKERS`: Comma-separated list of Kafka brokers

### Running the Service

```bash
uvicorn src.main:app --host 0.0.0.0 --port 8000
```

## API Documentation

The API is documented using OpenAPI 3.0. When the service is running, you can access the Swagger UI at:

```
http://localhost:8000/docs
```

## Docker

Build the Docker image:

```bash
docker build -t finflow/credit-engine:latest .
```

Run the container:

```bash
docker run -p 8000:8000 -e JWT_SECRET=your_secret -e KAFKA_BROKERS=kafka:9092 finflow/credit-engine:latest
```

## Kubernetes Deployment

Apply the Kubernetes configuration:

```bash
kubectl apply -f kubernetes.yaml
```

## Testing

Run the tests:

```bash
pytest tests/
```

## GDPR Compliance

This service implements GDPR compliance endpoints:

- `GET /user/data`: Export all user data
- `DELETE /user/data`: Delete all user data (right to be forgotten)

## Integration with Other Services

The Credit Engine integrates with:

- Authentication Service: For JWT validation
- Kafka: For event streaming (consuming user events, publishing credit score events)
- Analytics Service: For data analysis and reporting
