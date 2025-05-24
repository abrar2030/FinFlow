#!/bin/bash
# Setup script for FinFlow infrastructure
# This script sets up the entire infrastructure from scratch

set -e

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print section header
print_header() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print step
print_step() {
  echo -e "${YELLOW}>>> $1${NC}"
}

# Check if AWS CLI is configured
print_header "Checking prerequisites"
print_step "Checking AWS CLI configuration"
if ! aws sts get-caller-identity &>/dev/null; then
  echo "AWS CLI is not configured. Please run 'aws configure' first."
  exit 1
fi

print_step "Checking required tools"
for tool in terraform ansible kubectl helm; do
  if ! command -v $tool &>/dev/null; then
    echo "$tool is not installed. Please install it first."
    exit 1
  fi
done

# Create S3 bucket for Terraform state if it doesn't exist
print_header "Setting up Terraform backend"
print_step "Creating S3 bucket for Terraform state"
BUCKET_NAME="finflow-terraform-state"
REGION=$(aws configure get region)
if ! aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION
  
  aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled
  
  aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
fi

# Create DynamoDB table for Terraform state locking if it doesn't exist
print_step "Creating DynamoDB table for Terraform state locking"
TABLE_NAME="finflow-terraform-locks"
if ! aws dynamodb describe-table --table-name $TABLE_NAME 2>/dev/null; then
  aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION
fi

# Initialize Terraform
print_header "Initializing Terraform"
print_step "Running terraform init"
cd /home/ubuntu/finflow-infra/terraform
terraform init

# Apply Terraform configuration
print_header "Applying Terraform configuration"
print_step "Running terraform apply"
terraform apply -auto-approve

# Configure kubectl
print_header "Configuring kubectl"
print_step "Setting up kubectl configuration"
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Run Ansible playbook
print_header "Running Ansible playbooks"
print_step "Running Ansible site.yml"
cd /home/ubuntu/finflow-infra/ansible
ansible-playbook -i inventory/prod site.yml

# Deploy applications
print_header "Deploying applications"
print_step "Running deployment script"
cd /home/ubuntu/finflow-infra
./scripts/deploy.sh

# Set up monitoring
print_header "Setting up monitoring"
print_step "Running monitoring setup script"
./scripts/monitoring-setup.sh

print_header "Infrastructure setup complete"
echo "You can now access the following resources:"
echo "- Kubernetes Dashboard: $(kubectl get svc kubernetes-dashboard -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "- Grafana: $(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "- Kibana: $(kubectl get svc kibana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "- Frontend: $(kubectl get svc frontend -n finflow-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "- API Gateway: $(kubectl get svc api-gateway -n finflow-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
