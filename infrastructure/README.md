# FinFlow Infrastructure - Complete Guide

## Overview

This directory contains the complete infrastructure-as-code for the FinFlow application, including:

- **Terraform**: AWS infrastructure provisioning (VPC, EKS, RDS, etc.)
- **Kubernetes**: Application deployment manifests and configurations
- **Ansible**: Server configuration and deployment automation
- **CI/CD**: GitHub Actions workflows for continuous integration and deployment
- **Monitoring**: Prometheus, Grafana, and EFK stack configurations
- **Docker**: Optimized Dockerfiles for all services

## Prerequisites

### Required Tools

| Tool          | Minimum Version | Installation                                                               |
| ------------- | --------------- | -------------------------------------------------------------------------- |
| **Terraform** | >= 1.5.0        | [terraform.io/downloads](https://www.terraform.io/downloads.html)          |
| **kubectl**   | >= 1.28         | [kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/) |
| **AWS CLI**   | >= 2.0          | [aws.amazon.com/cli/](https://aws.amazon.com/cli/)                         |
| **Ansible**   | >= 2.9          | `pip install ansible`                                                      |
| **Helm**      | >= 3.0          | [helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/)         |
| **Docker**    | >= 20.10        | [docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)         |

### Optional Tools (for validation)

```bash
# Terraform linting and security
brew install tflint tfsec  # or use package manager

# Kubernetes manifest validation
brew install kubeval

# YAML linting
pip install yamllint ansible-lint
```

## Quick Start

### 1. Terraform - Provision AWS Infrastructure

```bash
cd terraform

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values

# Initialize Terraform
terraform init

# Review planned changes
terraform plan -out=plan.out

# Apply infrastructure (requires AWS credentials)
terraform apply plan.out

# Get kubeconfig for EKS cluster
aws eks update-kubeconfig --region us-west-2 --name finflow-cluster
```

### 2. Kubernetes - Deploy Applications

```bash
cd kubernetes

# Create namespace
kubectl create namespace finflow-prod

# Create secrets from template
cp secrets.example.yaml secrets.yaml
# Edit secrets.yaml and replace all REPLACE_ME values
kubectl apply -f secrets.yaml

# Deploy databases (StatefulSets)
kubectl apply -f databases/

# Deploy services
kubectl apply -f auth-service/
kubectl apply -f payments-service/
kubectl apply -f accounting-service/
kubectl apply -f analytics-service/
kubectl apply -f credit-engine/

# Deploy API Gateway and Frontend
kubectl apply -f api-gateway/
kubectl apply -f frontend/

# Verify deployments
kubectl get pods -n finflow-prod
kubectl get services -n finflow-prod
```

### 3. Monitoring - Deploy Observability Stack

```bash
# Deploy monitoring namespace and components
kubectl apply -f monitoring/kubernetes/namespace.yaml
kubectl apply -f monitoring/kubernetes/

# Access Grafana dashboard
kubectl port-forward -n monitoring svc/grafana 3000:80
# Open http://localhost:3000
```

### 4. Ansible - Configure Servers (if needed)

```bash
cd ansible

# Copy inventory template
cp inventory.example inventory
# Edit inventory with your server IPs

# Run full site playbook
ansible-playbook -i inventory site.yml

# Or run specific roles
ansible-playbook -i inventory site.yml --tags docker,kubernetes
```

## Validation and Testing

### Terraform Validation

```bash
cd terraform

# Format check
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Security scan (if tfsec installed)
tfsec .

# Lint (if tflint installed)
tflint --init
tflint
```

### Kubernetes Validation

```bash
cd kubernetes

# YAML lint
yamllint .

# Dry-run apply
kubectl apply --dry-run=client -f auth-service/
kubectl apply --dry-run=server -f auth-service/  # Requires cluster access

# Validate with kubeval (if installed)
kubeval auth-service/*.yaml
```

### Ansible Validation

```bash
cd ansible

# Syntax check
ansible-playbook site.yml --syntax-check

# Dry-run (check mode)
ansible-playbook -i inventory site.yml --check

# Lint
ansible-lint site.yml
```

### CI/CD Validation

```bash
cd ci-cd

# YAML syntax check
yamllint *.yml

# Test locally with act (if installed)
act -l  # List workflows
act pull_request  # Run PR workflow locally
```

## Configuration Files

### Environment-Specific Configuration

All sensitive values should be managed outside version control:

1. **Terraform**: Use `terraform.tfvars` (from `terraform.tfvars.example`)
2. **Kubernetes**: Use `secrets.yaml` (from `secrets.example.yaml`)
3. **Ansible**: Use `ansible-vault` for encrypted variables
4. **CI/CD**: Use GitHub Secrets for sensitive values

### AWS Credentials

Configure AWS CLI before running Terraform:

```bash
# Configure credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Or use IAM roles (recommended for EC2/EKS)
```

### Kubernetes Secrets

Create secrets using the template:

```bash
# Base64 encode values
echo -n 'my-secret-value' | base64

# Apply secrets
kubectl apply -f secrets.yaml

# Verify (be careful, this shows secrets!)
kubectl get secret auth-secrets -n finflow-prod -o yaml
```

### Backend Configuration

Terraform uses S3 backend by default. For local development:

```bash
# Copy local backend configuration
cp backend-local.tf.example backend-local.tf

# Comment out S3 backend in main.tf
# Then run terraform init
```

## Deployment Workflows

### Full Stack Deployment

```bash
# 1. Provision infrastructure
cd terraform && terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --name finflow-cluster --region us-west-2

# 3. Deploy applications
cd ../kubernetes
kubectl apply -f secrets.yaml
kubectl apply -f databases/
kubectl apply -f */  # Deploy all services

# 4. Setup monitoring
kubectl apply -f ../monitoring/kubernetes/

# 5. Verify
kubectl get pods -A
```

### Rolling Updates

```bash
# Update image tag in deployment.yaml or use kubectl set image
kubectl set image deployment/auth-service \
  auth-service=your-registry/finflow/auth-service:v1.2.0 \
  -n finflow-prod

# Monitor rollout
kubectl rollout status deployment/auth-service -n finflow-prod

# Rollback if needed
kubectl rollout undo deployment/auth-service -n finflow-prod
```

### Scaling

```bash
# Manual scaling
kubectl scale deployment/payments-service --replicas=5 -n finflow-prod

# Horizontal Pod Autoscaler (HPA) is configured in deployments
kubectl get hpa -n finflow-prod
```

## Troubleshooting

### Common Issues

#### Terraform Init Fails

```bash
# Clear lock file and retry
rm -rf .terraform .terraform.lock.hcl
terraform init
```

#### kubectl Cannot Connect

```bash
# Refresh kubeconfig
aws eks update-kubeconfig --name finflow-cluster --region us-west-2

# Test connection
kubectl cluster-info
kubectl get nodes
```

#### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n finflow-prod

# Check logs
kubectl logs <pod-name> -n finflow-prod

# Common issues:
# - ImagePullBackOff: Check registry credentials
# - CrashLoopBackOff: Check application logs
# - Pending: Check resource availability
```

#### Secrets Not Found

```bash
# Verify secrets exist
kubectl get secrets -n finflow-prod

# Create missing secrets from template
kubectl apply -f secrets.yaml
```

### Debug Commands

```bash
# Terraform
terraform show  # Show current state
terraform state list  # List resources
terraform state show <resource>  # Show specific resource

# Kubernetes
kubectl get events -n finflow-prod --sort-by='.lastTimestamp'
kubectl top pods -n finflow-prod  # Resource usage
kubectl exec -it <pod-name> -n finflow-prod -- /bin/sh  # Shell access

# Ansible
ansible all -i inventory -m ping  # Test connectivity
ansible-playbook site.yml -i inventory -vvv  # Verbose output
```

## Security Best Practices

1. **Never commit secrets** to version control
2. **Use IAM roles** instead of access keys where possible
3. **Enable encryption** for all data at rest (RDS, S3, EBS)
4. **Use HTTPS/TLS** for all external communication
5. **Implement network policies** to restrict pod-to-pod communication
6. **Regularly update** dependencies and base images
7. **Use least privilege** principle for all IAM roles
8. **Enable audit logging** (CloudTrail, K8s audit logs)

## Maintenance

### Backup Procedures

```bash
# Database backups (automated via RDS)
# Terraform state backup
terraform state pull > terraform.tfstate.backup

# Kubernetes resources backup
kubectl get all -n finflow-prod -o yaml > k8s-backup.yaml
```

### Update Procedures

```bash
# Update Terraform modules
cd terraform
terraform init -upgrade
terraform plan
terraform apply

# Update Kubernetes manifests
kubectl apply -f <updated-manifest>.yaml

# Update Helm charts
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/helm-values/prometheus-values.yaml
```

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Ansible Documentation](https://docs.ansible.com/)

## Validation Logs

All validation outputs are stored in `validation_logs/`:

- `terraform_init.log` - Terraform initialization output
- `terraform_validate_final.log` - Terraform validation result
- `kubernetes_yamllint.log` - Kubernetes YAML lint results
- `ansible_lint.log` - Ansible playbook lint results
- `cicd_yamllint.log` - CI/CD workflow validation
