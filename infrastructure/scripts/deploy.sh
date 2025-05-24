#!/bin/bash
# Deployment script for FinFlow applications
# This script deploys all FinFlow microservices to Kubernetes

set -e

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section header
print_header() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print step
print_step() {
  echo -e "${YELLOW}>>> $1${NC}"
}

# Function to check if kubectl is connected to the cluster
check_kubectl() {
  if ! kubectl get nodes &>/dev/null; then
    echo -e "${RED}Error: kubectl is not connected to the cluster.${NC}"
    echo "Please run 'aws eks update-kubeconfig --region <region> --name <cluster-name>' first."
    exit 1
  fi
}

# Check kubectl connection
print_header "Checking prerequisites"
print_step "Verifying kubectl connection"
check_kubectl

# Create namespaces if they don't exist
print_header "Setting up namespaces"
print_step "Creating finflow-prod namespace"
kubectl create namespace finflow-prod --dry-run=client -o yaml | kubectl apply -f -

# Apply database configurations
print_header "Deploying databases"
print_step "Deploying database StatefulSets and Services"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/databases/

# Wait for databases to be ready
print_step "Waiting for databases to be ready"
kubectl rollout status statefulset/auth-db -n finflow-prod --timeout=300s
kubectl rollout status statefulset/payments-db -n finflow-prod --timeout=300s
kubectl rollout status statefulset/accounting-db -n finflow-prod --timeout=300s
kubectl rollout status statefulset/analytics-db -n finflow-prod --timeout=300s
kubectl rollout status statefulset/kafka -n finflow-prod --timeout=300s

# Deploy backend services
print_header "Deploying backend services"
print_step "Deploying Auth Service"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/auth-service/
kubectl rollout status deployment/auth-service -n finflow-prod --timeout=300s

print_step "Deploying Payments Service"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/payments-service/
kubectl rollout status deployment/payments-service -n finflow-prod --timeout=300s

print_step "Deploying Accounting Service"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/accounting-service/
kubectl rollout status deployment/accounting-service -n finflow-prod --timeout=300s

print_step "Deploying Analytics Service"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/analytics-service/
kubectl rollout status deployment/analytics-service -n finflow-prod --timeout=300s

print_step "Deploying Credit Engine"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/credit-engine/
kubectl rollout status deployment/credit-engine -n finflow-prod --timeout=300s

# Deploy API Gateway
print_header "Deploying API Gateway"
print_step "Deploying API Gateway service"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/api-gateway/
kubectl rollout status deployment/api-gateway -n finflow-prod --timeout=300s

# Deploy Frontend
print_header "Deploying Frontend"
print_step "Deploying Frontend application"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/frontend/
kubectl rollout status deployment/frontend -n finflow-prod --timeout=300s

# Apply ingress configurations
print_header "Configuring Ingress"
print_step "Applying Ingress rules"
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/frontend/ingress.yaml
kubectl apply -f /home/ubuntu/finflow-infra/kubernetes/api-gateway/ingress.yaml

# Verify deployments
print_header "Verifying deployments"
print_step "Checking service endpoints"
echo "Frontend service: $(kubectl get svc frontend -n finflow-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "API Gateway service: $(kubectl get svc api-gateway -n finflow-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

print_header "Deployment complete"
echo -e "${GREEN}All FinFlow services have been successfully deployed!${NC}"
echo "You can access the application at: $(kubectl get svc frontend -n finflow-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
