#!/bin/bash
# Backup script for FinFlow infrastructure
# This script creates backups of databases and configuration

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

# Set backup directory
BACKUP_DIR="/finflow-backups/$(date +%Y-%m-%d)"
S3_BUCKET="finflow-backups"
REGION=$(aws configure get region)

# Check kubectl connection
print_header "Checking prerequisites"
print_step "Verifying kubectl connection"
check_kubectl

# Create backup directory
print_header "Setting up backup directory"
print_step "Creating local backup directory"
mkdir -p $BACKUP_DIR/kubernetes
mkdir -p $BACKUP_DIR/databases

# Backup Kubernetes resources
print_header "Backing up Kubernetes resources"
print_step "Backing up all resources in finflow-prod namespace"
kubectl get all -n finflow-prod -o yaml > $BACKUP_DIR/kubernetes/all-resources.yaml

print_step "Backing up ConfigMaps"
kubectl get configmaps -n finflow-prod -o yaml > $BACKUP_DIR/kubernetes/configmaps.yaml

print_step "Backing up Secrets"
kubectl get secrets -n finflow-prod -o yaml > $BACKUP_DIR/kubernetes/secrets.yaml

print_step "Backing up PersistentVolumeClaims"
kubectl get pvc -n finflow-prod -o yaml > $BACKUP_DIR/kubernetes/pvcs.yaml

# Backup databases
print_header "Backing up databases"

# Function to backup a PostgreSQL database
backup_postgres() {
  local service=$1
  local db_name=$2
  print_step "Backing up $service database"
  
  # Create a temporary pod to run pg_dump
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pg-dump-$service
  namespace: finflow-prod
spec:
  containers:
  - name: pg-dump
    image: postgres:14
    command: ["sleep", "3600"]
    volumeMounts:
    - name: backup-volume
      mountPath: /backup
  volumes:
  - name: backup-volume
    emptyDir: {}
EOF

  # Wait for the pod to be ready
  kubectl wait --for=condition=Ready pod/pg-dump-$service -n finflow-prod --timeout=60s

  # Run pg_dump
  kubectl exec -n finflow-prod pg-dump-$service -- bash -c "PGPASSWORD=\$POSTGRES_PASSWORD pg_dump -h $service -U postgres -d $db_name -F c -f /backup/$service-$(date +%Y-%m-%d).dump"

  # Copy the backup file from the pod
  kubectl cp finflow-prod/pg-dump-$service:/backup/$service-$(date +%Y-%m-%d).dump $BACKUP_DIR/databases/$service-$(date +%Y-%m-%d).dump

  # Delete the temporary pod
  kubectl delete pod pg-dump-$service -n finflow-prod
}

# Backup each database
backup_postgres "auth-db" "auth"
backup_postgres "payments-db" "payments"
backup_postgres "accounting-db" "accounting"
backup_postgres "analytics-db" "analytics"

# Backup Terraform state
print_header "Backing up Terraform state"
print_step "Copying Terraform state files"
mkdir -p $BACKUP_DIR/terraform
aws s3 cp s3://finflow-terraform-state $BACKUP_DIR/terraform --recursive

# Backup Ansible inventory and variables
print_header "Backing up Ansible files"
print_step "Copying Ansible inventory and variables"
mkdir -p $BACKUP_DIR/ansible
cp -r /FinFlow/infrastructure/ansible/inventory $BACKUP_DIR/ansible/
cp -r /FinFlow/infrastructure/ansible/vars $BACKUP_DIR/ansible/

# Create a compressed archive of all backups
print_header "Creating compressed archive"
print_step "Creating tar.gz archive of all backups"
cd $(dirname $BACKUP_DIR)
tar -czf finflow-backup-$(date +%Y-%m-%d).tar.gz $(basename $BACKUP_DIR)

# Upload to S3 if bucket exists
print_header "Uploading to S3"
print_step "Checking if S3 bucket exists"
if aws s3api head-bucket --bucket $S3_BUCKET 2>/dev/null; then
  print_step "Uploading backup archive to S3"
  aws s3 cp finflow-backup-$(date +%Y-%m-%d).tar.gz s3://$S3_BUCKET/
else
  print_step "Creating S3 bucket for backups"
  aws s3api create-bucket \
    --bucket $S3_BUCKET \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION
  
  aws s3api put-bucket-versioning \
    --bucket $S3_BUCKET \
    --versioning-configuration Status=Enabled
  
  aws s3api put-bucket-encryption \
    --bucket $S3_BUCKET \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
  
  print_step "Uploading backup archive to S3"
  aws s3 cp finflow-backup-$(date +%Y-%m-%d).tar.gz s3://$S3_BUCKET/
fi

# Cleanup old backups (keep last 7 days)
print_header "Cleaning up old backups"
print_step "Removing backups older than 7 days"
find /finflow-backups -type d -name "????-??-??" -mtime +7 -exec rm -rf {} \;

print_header "Backup complete"
echo -e "${GREEN}Backup completed successfully!${NC}"
echo "Backup archive: /finflow-backups/finflow-backup-$(date +%Y-%m-%d).tar.gz"
echo "S3 location: s3://$S3_BUCKET/finflow-backup-$(date +%Y-%m-%d).tar.gz"
