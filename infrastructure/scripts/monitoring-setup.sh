#!/bin/bash
# Monitoring setup script for FinFlow infrastructure
# This script sets up the monitoring stack (Prometheus, Grafana, Fluentd, Elasticsearch, Kibana)

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

# Function to check if Helm is installed
check_helm() {
  if ! command -v helm &>/dev/null; then
    echo -e "${RED}Error: helm is not installed.${NC}"
    echo "Please install Helm first."
    exit 1
  fi
}

# Check prerequisites
print_header "Checking prerequisites"
print_step "Verifying kubectl connection"
check_kubectl

print_step "Verifying Helm installation"
check_helm

# Create monitoring namespace
print_header "Setting up monitoring namespace"
print_step "Creating monitoring namespace"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
print_header "Adding Helm repositories"
print_step "Adding Prometheus repository"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

print_step "Adding Elasticsearch repository"
helm repo add elastic https://helm.elastic.co

print_step "Adding Grafana repository"
helm repo add grafana https://grafana.github.io/helm-charts

print_step "Updating Helm repositories"
helm repo update

# Install Prometheus stack
print_header "Installing Prometheus stack"
print_step "Deploying Prometheus, Alertmanager, and Grafana"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values /FinFlow/infrastructure/terraform/helm-values/prometheus-values.yaml \
  --timeout 10m

# Wait for Prometheus to be ready
print_step "Waiting for Prometheus to be ready"
kubectl rollout status deployment/prometheus-kube-prometheus-operator -n monitoring --timeout=300s
kubectl rollout status statefulset/prometheus-prometheus-kube-prometheus-prometheus -n monitoring --timeout=300s
kubectl rollout status deployment/prometheus-grafana -n monitoring --timeout=300s

# Install Elasticsearch
print_header "Installing Elasticsearch"
print_step "Deploying Elasticsearch cluster"
helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace monitoring \
  --values /FinFlow/infrastructure/terraform/helm-values/elasticsearch-values.yaml \
  --timeout 10m

# Wait for Elasticsearch to be ready
print_step "Waiting for Elasticsearch to be ready"
kubectl rollout status statefulset/elasticsearch-master -n monitoring --timeout=600s

# Install Fluentd
print_header "Installing Fluentd"
print_step "Deploying Fluentd for log collection"
helm upgrade --install fluentd stable/fluentd-elasticsearch \
  --namespace monitoring \
  --values /FinFlow/infrastructure/terraform/helm-values/fluentd-values.yaml \
  --timeout 5m

# Wait for Fluentd to be ready
print_step "Waiting for Fluentd to be ready"
kubectl rollout status daemonset/fluentd -n monitoring --timeout=300s

# Install Kibana
print_header "Installing Kibana"
print_step "Deploying Kibana for log visualization"
helm upgrade --install kibana elastic/kibana \
  --namespace monitoring \
  --set elasticsearchHosts="http://elasticsearch-master:9200" \
  --timeout 5m

# Wait for Kibana to be ready
print_step "Waiting for Kibana to be ready"
kubectl rollout status deployment/kibana-kibana -n monitoring --timeout=300s

# Configure service monitors for FinFlow services
print_header "Configuring service monitors"
print_step "Creating ServiceMonitor resources for FinFlow services"

cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: finflow-services
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/part-of: finflow
  namespaceSelector:
    matchNames:
      - finflow-prod
  endpoints:
  - port: metrics
    interval: 15s
EOF

# Create Grafana dashboards
print_header "Configuring Grafana dashboards"
print_step "Creating Grafana dashboards for FinFlow services"

# Apply Grafana configuration
kubectl apply -f /FinFlow/infrastructure/kubernetes/monitoring/grafana-dashboards-configmap.yaml

# Set up alerts
print_header "Configuring alerts"
print_step "Creating PrometheusRule resources for alerts"

cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: finflow-alerts
  namespace: monitoring
  labels:
    release: prometheus
spec:
  groups:
  - name: finflow.rules
    rules:
    - alert: HighErrorRate
      expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: High HTTP error rate
        description: "Error rate is above 5% for the last 5 minutes (current value: {{ $value }})"
    - alert: ServiceDown
      expr: up{job=~".*finflow.*"} == 0
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Service {{ \$labels.job }} is down"
        description: "{{ \$labels.job }} has been down for more than 2 minutes"
    - alert: HighCPUUsage
      expr: container_cpu_usage_seconds_total{namespace="finflow-prod"} > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage in {{ \$labels.pod }}"
        description: "Pod {{ \$labels.pod }} has high CPU usage ({{ \$value }})"
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes{namespace="finflow-prod"} / container_spec_memory_limit_bytes{namespace="finflow-prod"} > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage in {{ \$labels.pod }}"
        description: "Pod {{ \$labels.pod }} has high memory usage ({{ \$value }})"
EOF

# Create ingress for monitoring services
print_header "Configuring ingress for monitoring services"
print_step "Creating ingress resources for Grafana, Prometheus, and Kibana"

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  rules:
  - host: grafana.finflow.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-grafana
            port:
              number: 80
  - host: prometheus.finflow.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-kube-prometheus-prometheus
            port:
              number: 9090
  - host: kibana.finflow.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kibana-kibana
            port:
              number: 5601
  tls:
  - hosts:
    - grafana.finflow.example.com
    - prometheus.finflow.example.com
    - kibana.finflow.example.com
    secretName: monitoring-tls
EOF

# Verify monitoring setup
print_header "Verifying monitoring setup"
print_step "Checking Prometheus pods"
kubectl get pods -n monitoring -l app=prometheus

print_step "Checking Grafana pods"
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

print_step "Checking Elasticsearch pods"
kubectl get pods -n monitoring -l app=elasticsearch-master

print_step "Checking Fluentd pods"
kubectl get pods -n monitoring -l app=fluentd

print_step "Checking Kibana pods"
kubectl get pods -n monitoring -l app=kibana

print_header "Monitoring setup complete"
echo -e "${GREEN}Monitoring stack has been successfully deployed!${NC}"
echo "You can access the monitoring services at:"
echo "- Grafana: https://grafana.finflow.example.com"
echo "- Prometheus: https://prometheus.finflow.example.com"
echo "- Kibana: https://kibana.finflow.example.com"
echo ""
echo "Default Grafana credentials:"
echo "- Username: admin"
echo "- Password: $(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
