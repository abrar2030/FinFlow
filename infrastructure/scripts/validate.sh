#!/bin/bash
# Infrastructure validation script for FinFlow
# This script validates the infrastructure setup

set -e

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}✓ $2${NC}"
  else
    echo -e "${RED}✗ $2${NC}"
    if [ -n "$3" ]; then
      echo -e "  ${YELLOW}$3${NC}"
    fi
  fi
}

echo "=== FinFlow Infrastructure Validation ==="
echo "Starting validation at $(date)"
echo

# Check directory structure
echo "Checking directory structure..."
DIRS=(
  "docker"
  "kubernetes"
  "ansible"
  "terraform"
  "scripts"
)

for dir in "${DIRS[@]}"; do
  if [ -d "/finflow-infra/$dir" ]; then
    print_status 0 "Directory $dir exists"
  else
    print_status 1 "Directory $dir does not exist" "Create the directory: mkdir -p /finflow-infra/$dir"
  fi
done

# Check Docker files
echo -e "\nChecking Docker files..."
DOCKER_DIRS=(
  "frontend"
  "api-gateway"
  "auth-service"
  "payments-service"
  "accounting-service"
  "analytics-service"
  "credit-engine"
)

for dir in "${DOCKER_DIRS[@]}"; do
  if [ -f "/finflow-infra/docker/$dir/Dockerfile" ]; then
    print_status 0 "Dockerfile for $dir exists"
  else
    print_status 1 "Dockerfile for $dir does not exist" "Create the Dockerfile: touch /finflow-infra/docker/$dir/Dockerfile"
  fi
done

# Check Kubernetes manifests
echo -e "\nChecking Kubernetes manifests..."
K8S_DIRS=(
  "frontend"
  "api-gateway"
  "auth-service"
  "payments-service"
  "accounting-service"
  "analytics-service"
  "credit-engine"
  "databases"
  "monitoring"
)

for dir in "${K8S_DIRS[@]}"; do
  if [ -d "/finflow-infra/kubernetes/$dir" ]; then
    print_status 0 "Kubernetes manifests for $dir exist"
  else
    print_status 1 "Kubernetes manifests for $dir do not exist" "Create the directory: mkdir -p /finflow-infra/kubernetes/$dir"
  fi
done

# Check Ansible playbooks and roles
echo -e "\nChecking Ansible playbooks and roles..."
ANSIBLE_ROLES=(
  "common"
  "docker"
  "kubernetes"
  "monitoring"
  "deployment"
)

if [ -f "/finflow-infra/ansible/site.yml" ]; then
  print_status 0 "Ansible site.yml exists"
else
  print_status 1 "Ansible site.yml does not exist" "Create the file: touch /finflow-infra/ansible/site.yml"
fi

for role in "${ANSIBLE_ROLES[@]}"; do
  if [ -d "/finflow-infra/ansible/roles/$role" ]; then
    print_status 0 "Ansible role $role exists"
  else
    print_status 1 "Ansible role $role does not exist" "Create the directory: mkdir -p /finflow-infra/ansible/roles/$role"
  fi
done

# Check Terraform modules
echo -e "\nChecking Terraform modules..."
TF_MODULES=(
  "vpc"
  "eks"
  "rds"
  "ecr"
  "route53"
  "bastion"
)

if [ -f "/finflow-infra/terraform/main.tf" ]; then
  print_status 0 "Terraform main.tf exists"
else
  print_status 1 "Terraform main.tf does not exist" "Create the file: touch /finflow-infra/terraform/main.tf"
fi

if [ -f "/finflow-infra/terraform/variables.tf" ]; then
  print_status 0 "Terraform variables.tf exists"
else
  print_status 1 "Terraform variables.tf does not exist" "Create the file: touch /finflow-infra/terraform/variables.tf"
fi

for module in "${TF_MODULES[@]}"; do
  if [ -d "/finflow-infra/terraform/modules/$module" ]; then
    print_status 0 "Terraform module $module exists"
  else
    print_status 1 "Terraform module $module does not exist" "Create the directory: mkdir -p /finflow-infra/terraform/modules/$module"
  fi
done

# Check Helm values
echo -e "\nChecking Helm values..."
HELM_VALUES=(
  "prometheus-values.yaml"
  "fluentd-values.yaml"
  "elasticsearch-values.yaml"
  "grafana-values.yaml"
)

for value in "${HELM_VALUES[@]}"; do
  if [ -f "/finflow-infra/terraform/helm-values/$value" ]; then
    print_status 0 "Helm values file $value exists"
  else
    print_status 1 "Helm values file $value does not exist" "Create the file: touch /finflow-infra/terraform/helm-values/$value"
  fi
done

# Check documentation
echo -e "\nChecking documentation..."
if [ -f "/finflow-infra/documentation.md" ]; then
  print_status 0 "Documentation file exists"
else
  print_status 1 "Documentation file does not exist" "Create the file: touch /finflow-infra/documentation.md"
fi

# Check automation scripts
echo -e "\nChecking automation scripts..."
SCRIPTS=(
  "setup.sh"
  "deploy.sh"
  "backup.sh"
  "monitoring-setup.sh"
)

for script in "${SCRIPTS[@]}"; do
  if [ -f "/finflow-infra/scripts/$script" ]; then
    print_status 0 "Script $script exists"
  else
    print_status 1 "Script $script does not exist" "Create the script: touch /finflow-infra/scripts/$script"
  fi
done

echo -e "\nValidation completed at $(date)"
echo "=== End of Validation ==="
