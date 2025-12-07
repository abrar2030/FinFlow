#!/bin/bash

set -euo pipefail

# FinFlow Monitoring Automation
# This script automates monitoring setup, dashboard configuration, and alert management
# Version: 1.0.0

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
LOG_DIR="$PROJECT_ROOT/logs"
MONITORING_DIR="$PROJECT_ROOT/monitoring"

# --- Colors & Helpers ---
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_CYAN="\033[36m"

print_header() {
  echo -e "\n${COLOR_BLUE}==================================================${COLOR_RESET}"
  echo -e "${COLOR_BLUE} $1 ${COLOR_RESET}"
  echo -e "${COLOR_BLUE}==================================================${COLOR_RESET}"
}

print_success() {
  echo -e "${COLOR_GREEN}[SUCCESS] $1${COLOR_RESET}"
}

print_error() {
  echo -e "${COLOR_RED}[ERROR] $1${COLOR_RESET}" >&2
}

print_warning() {
  echo -e "${COLOR_YELLOW}[WARNING] $1${COLOR_RESET}"
}

print_info() {
  echo -e "${COLOR_CYAN}[INFO] $1${COLOR_RESET}"
}

log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [$level] $message" >> "$LOG_DIR/monitoring.log"
}

# --- Command Line Arguments ---
VERBOSE=false
ACTION="setup"
SERVICES="all"
DASHBOARD_ONLY=false
ALERTS_ONLY=false
GRAFANA_PORT=3000
PROMETHEUS_PORT=9090

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -a, --action ACTION        Action to perform (setup, start, stop, status)"
  echo "  -s, --services SERVICES    Comma-separated list of services to monitor (default: all)"
  echo "  --dashboard-only           Only set up dashboards (skip Prometheus/Grafana setup)"
  echo "  --alerts-only              Only set up alerts (skip Prometheus/Grafana setup)"
  echo "  --grafana-port PORT        Grafana port (default: 3000)"
  echo "  --prometheus-port PORT     Prometheus port (default: 9090)"
  echo
  echo "Examples:"
  echo "  $0 --action setup"
  echo "  $0 --action start"
  echo "  $0 --services auth-service,payments-service"
  exit 0
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -a|--action) ACTION="$2"; shift 2 ;;
    -s|--services) SERVICES="$2"; shift 2 ;;
    --dashboard-only) DASHBOARD_ONLY=true; shift ;;
    --alerts-only) ALERTS_ONLY=true; shift ;;
    --grafana-port) GRAFANA_PORT="$2"; shift 2 ;;
    --prometheus-port) PROMETHEUS_PORT="$2"; shift 2 ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Initialization ---
print_header "FinFlow Monitoring Automation"
print_info "Starting monitoring automation with action: $ACTION"

# Create necessary directories
mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$MONITORING_DIR"

# Initialize log file
echo "=== FinFlow Monitoring Log $(date) ===" > "$LOG_DIR/monitoring.log"
log_message "INFO" "Starting monitoring automation with action: $ACTION"

# --- Check Prerequisites ---
print_header "Checking Prerequisites"

check_prerequisites() {
  # Check if Docker is installed and running
  if ! command -v docker &> /dev/null; then
    print_error "Docker is required but not installed."
    log_message "ERROR" "Docker is required but not installed"
    exit 1
  fi
  
  if ! docker info &> /dev/null; then
    print_error "Docker is not running."
    log_message "ERROR" "Docker is not running"
    exit 1
  fi
  
  # Check if Docker Compose is installed
  if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then\n    DOCKER_COMPOSE_CMD="docker-compose"\n  elif command -v docker compose &> /dev/null; then\n    DOCKER_COMPOSE_CMD="docker compose"\n  else
    print_error "Docker Compose is required but not installed."
    log_message "ERROR" "Docker Compose is required but not installed"
    exit 1
  fi
  
  print_success "All prerequisites are met"
  log_message "INFO" "All prerequisites are met"
}

check_prerequisites

# --- Generate Configuration Files ---
print_header "Generating Configuration Files"

generate_prometheus_config() {
  print_info "Generating Prometheus configuration..."
  log_message "INFO" "Generating Prometheus configuration"
  
  # Determine which services to monitor
  if [ "$SERVICES" = "all" ]; then
    local backend_services=("auth-service" "payments-service" "accounting-service" "analytics-service" "credit-engine")
  else
    IFS=',' read -ra backend_services <<< "$SERVICES"
  fi
  
  # Create Prometheus configuration
  cat > "$MONITORING_DIR/prometheus.yml" << EOL
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

rule_files:
  - "alerts.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

EOL

  # Add service-specific scrape configs
  for service in "${backend_services[@]}"; do
    cat >> "$MONITORING_DIR/prometheus.yml" << EOL
  - job_name: '${service}'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['${service}:3000']

EOL
  done
  
  print_success "Prometheus configuration generated"
  log_message "INFO" "Prometheus configuration generated"
}

generate_alerts_config() {
  print_info "Generating alerts configuration..."
  log_message "INFO" "Generating alerts configuration"
  
  # Create alerts configuration
  cat > "$MONITORING_DIR/alerts.yml" << EOL
groups:
  - name: FinFlow Alerts
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ \$labels.instance }} down"
          description: "{{ \$labels.instance }} of job {{ \$labels.job }} has been down for more than 1 minute."

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ \$labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes on {{ \$labels.instance }}."

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ \$labels.instance }}"
          description: "Memory usage is above 80% for more than 5 minutes on {{ \$labels.instance }}."

      - alert: HighDiskUsage
        expr: node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100 < 20
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High disk usage on {{ \$labels.instance }}"
          description: "Disk usage is above 80% for more than 5 minutes on {{ \$labels.instance }}."

      - alert: APIHighResponseTime
        expr: http_request_duration_seconds{quantile="0.9"} > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High API response time on {{ \$labels.instance }}"
          description: "90th percentile of API response time is above 1 second for more than 5 minutes on {{ \$labels.instance }}."
EOL
  
  print_success "Alerts configuration generated"
  log_message "INFO" "Alerts configuration generated"
}

generate_alertmanager_config() {
  print_info "Generating Alertmanager configuration..."
  log_message "INFO" "Generating Alertmanager configuration"
  
  # Create Alertmanager configuration
  cat > "$MONITORING_DIR/alertmanager.yml" << EOL
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'job']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'email-notifications'

receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'alerts@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'alertmanager'
        auth_password: 'password'
        send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
EOL
  
  print_success "Alertmanager configuration generated"
  log_message "INFO" "Alertmanager configuration generated"
}

generate_docker_compose() {
  print_info "Generating Docker Compose configuration..."
  log_message "INFO" "Generating Docker Compose configuration"
  
  # Create Docker Compose configuration
  cat > "$MONITORING_DIR/docker-compose.yml" << EOL
version: '3'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: finflow-prometheus
    ports:
      - "${PROMETHEUS_PORT}:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alerts.yml:/etc/prometheus/alerts.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    restart: unless-stopped

  alertmanager:
    image: prom/alertmanager:latest
    container_name: finflow-alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: finflow-grafana
    ports:
      - "${GRAFANA_PORT}:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    depends_on:
      - prometheus
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: finflow-node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped

volumes:
  prometheus_data:
  alertmanager_data:
  grafana_data:
EOL
  
  print_success "Docker Compose configuration generated"
  log_message "INFO" "Docker Compose configuration generated"
}

generate_grafana_dashboards() {
  print_info "Generating Grafana dashboards..."
  log_message "INFO" "Generating Grafana dashboards"
  
  # Create Grafana provisioning directories
  mkdir -p "$MONITORING_DIR/grafana/provisioning/datasources"
  mkdir -p "$MONITORING_DIR/grafana/provisioning/dashboards"
  mkdir -p "$MONITORING_DIR/grafana/dashboards"
  
  # Create Prometheus datasource
  cat > "$MONITORING_DIR/grafana/provisioning/datasources/prometheus.yml" << EOL
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
EOL
  
  # Create dashboard provider
  cat > "$MONITORING_DIR/grafana/provisioning/dashboards/dashboards.yml" << EOL
apiVersion: 1

providers:
  - name: 'FinFlow'
    orgId: 1
    folder: 'FinFlow'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: true
EOL
  
  # Create system overview dashboard
  cat > "$MONITORING_DIR/grafana/dashboards/system-overview.json" << EOL
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 1,
  "links": [],
  "panels": [
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 2,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\\"idle\\"}[5m])) * 100)",
          "legendFormat": "CPU Usage - {{instance}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "CPU Usage",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "percent",
          "label": null,
          "logBase": 1,
          "max": "100",
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 4,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
          "legendFormat": "Memory Usage - {{instance}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Memory Usage",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "percent",
          "label": null,
          "logBase": 1,
          "max": "100",
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 8
      },
      "hiddenSeries": false,
      "id": 6,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "100 - (node_filesystem_avail_bytes{mountpoint=\\"/\\"} / node_filesystem_size_bytes{mountpoint=\\"/\\"} * 100)",
          "legendFormat": "Disk Usage - {{instance}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Disk Usage",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "percent",
          "label": null,
          "logBase": 1,
          "max": "100",
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 8
      },
      "hiddenSeries": false,
      "id": 8,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "rate(node_network_receive_bytes_total[5m])",
          "legendFormat": "Network Receive - {{instance}}",
          "refId": "A"
        },
        {
          "expr": "rate(node_network_transmit_bytes_total[5m])",
          "legendFormat": "Network Transmit - {{instance}}",
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Network Traffic",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "bytes",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "refresh": "10s",
  "schemaVersion": 22,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "",
  "title": "System Overview",
  "uid": "system-overview",
  "version": 1
}
EOL
  
  # Create service-specific dashboard
  cat > "$MONITORING_DIR/grafana/dashboards/services-dashboard.json" << EOL
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 2,
  "links": [],
  "panels": [
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 2,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "rate(http_requests_total[5m])",
          "legendFormat": "Requests - {{job}} - {{instance}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "HTTP Request Rate",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 4,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "http_request_duration_seconds{quantile=\\"0.5\\"}",
          "legendFormat": "P50 - {{job}} - {{instance}}",
          "refId": "A"
        },
        {
          "expr": "http_request_duration_seconds{quantile=\\"0.9\\"}",
          "legendFormat": "P90 - {{job}} - {{instance}}",
          "refId": "B"
        },
        {
          "expr": "http_request_duration_seconds{quantile=\\"0.99\\"}",
          "legendFormat": "P99 - {{job}} - {{instance}}",
          "refId": "C"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "HTTP Response Time",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "s",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 8
      },
      "hiddenSeries": false,
      "id": 6,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "rate(http_requests_total{status=~\\"5..\\"} [5m])",
          "legendFormat": "5xx Errors - {{job}} - {{instance}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "HTTP Error Rate",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 8
      },
      "hiddenSeries": false,
      "id": 8,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "process_resident_memory_bytes",
          "legendFormat": "Memory Usage - {{job}} - {{instance}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Service Memory Usage",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "bytes",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "refresh": "10s",
  "schemaVersion": 22,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "",
  "title": "Services Dashboard",
  "uid": "services-dashboard",
  "version": 1
}
EOL
  
  print_success "Grafana dashboards generated"
  log_message "INFO" "Grafana dashboards generated"
}

generate_config_files() {
  # Generate Prometheus configuration
  generate_prometheus_config
  
  # Generate alerts configuration
  generate_alerts_config
  
  # Generate Alertmanager configuration
  generate_alertmanager_config
  
  # Generate Docker Compose configuration
  generate_docker_compose
  
  # Generate Grafana dashboards
  generate_grafana_dashboards
  
  print_success "All configuration files generated"
  log_message "INFO" "All configuration files generated"
}

if [ "$DASHBOARD_ONLY" = false ] && [ "$ALERTS_ONLY" = false ]; then
  generate_config_files
elif [ "$DASHBOARD_ONLY" = true ]; then
  generate_grafana_dashboards
elif [ "$ALERTS_ONLY" = true ]; then
  generate_alerts_config
fi

# --- Perform Action ---
print_header "Performing Action: $ACTION"

perform_action() {
  case "$ACTION" in
    setup)
      print_info "Setting up monitoring stack..."
      log_message "INFO" "Setting up monitoring stack"
      
      # Check if Docker Compose file exists
      if [ ! -f "$MONITORING_DIR/docker-compose.yml" ]; then
        print_error "Docker Compose file not found"
        log_message "ERROR" "Docker Compose file not found"
        return 1
      fi
      
      # Create directories for volumes
      mkdir -p "$MONITORING_DIR/prometheus_data"
      mkdir -p "$MONITORING_DIR/alertmanager_data"
      mkdir -p "$MONITORING_DIR/grafana_data"
      
      print_success "Monitoring stack setup completed"
      log_message "INFO" "Monitoring stack setup completed"
      ;;
      
    start)
      print_info "Starting monitoring stack..."
      log_message "INFO" "Starting monitoring stack"
      
      # Check if Docker Compose file exists
      if [ ! -f "$MONITORING_DIR/docker-compose.yml" ]; then
        print_error "Docker Compose file not found"
        log_message "ERROR" "Docker Compose file not found"
        return 1
      fi
      
      # Start the monitoring stack
      (cd "$MONITORING_DIR" && docker-compose up -d) || {
        print_error "Failed to start monitoring stack"
        log_message "ERROR" "Failed to start monitoring stack"
        return 1
      }
      
      print_success "Monitoring stack started"
      log_message "INFO" "Monitoring stack started"
      ;;
      
    stop)
      print_info "Stopping monitoring stack..."
      log_message "INFO" "Stopping monitoring stack"
      
      # Check if Docker Compose file exists
      if [ ! -f "$MONITORING_DIR/docker-compose.yml" ]; then
        print_error "Docker Compose file not found"
        log_message "ERROR" "Docker Compose file not found"
        return 1
      }
      
      # Stop the monitoring stack
      (cd "$MONITORING_DIR" && docker-compose down) || {
        print_error "Failed to stop monitoring stack"
        log_message "ERROR" "Failed to stop monitoring stack"
        return 1
      }
      
      print_success "Monitoring stack stopped"
      log_message "INFO" "Monitoring stack stopped"
      ;;
      
    status)
      print_info "Checking monitoring stack status..."
      log_message "INFO" "Checking monitoring stack status"
      
      # Check if Docker Compose file exists
      if [ ! -f "$MONITORING_DIR/docker-compose.yml" ]; then
        print_error "Docker Compose file not found"
        log_message "ERROR" "Docker Compose file not found"
        return 1
      }
      
      # Check monitoring stack status
      (cd "$MONITORING_DIR" && docker-compose ps) || {
        print_error "Failed to check monitoring stack status"
        log_message "ERROR" "Failed to check monitoring stack status"
        return 1
      }
      
      print_success "Monitoring stack status checked"
      log_message "INFO" "Monitoring stack status checked"
      ;;
      
    *)
      print_error "Unknown action: $ACTION"
      log_message "ERROR" "Unknown action: $ACTION"
      return 1
      ;;
  esac
  
  return 0
}

perform_action
action_status=$?

# --- Summary ---
print_header "Monitoring Summary"

if [ $action_status -eq 0 ]; then
  print_success "Monitoring action '$ACTION' completed successfully!"
  log_message "INFO" "Monitoring action '$ACTION' completed successfully"
  
  if [ "$ACTION" = "start" ] || [ "$ACTION" = "setup" ]; then
    echo -e "\n${COLOR_GREEN}Monitoring Access:${COLOR_RESET}"
    echo -e "Prometheus: ${COLOR_CYAN}http://localhost:${PROMETHEUS_PORT}${COLOR_RESET}"
    echo -e "Grafana: ${COLOR_CYAN}http://localhost:${GRAFANA_PORT}${COLOR_RESET} (admin/admin)"
    echo -e "Alertmanager: ${COLOR_CYAN}http://localhost:9093${COLOR_RESET}"
  fi
  
  log_message "INFO" "Monitoring summary provided to user"
else
  print_error "Monitoring action '$ACTION' failed"
  print_info "Please check the log file for details: $LOG_DIR/monitoring.log"
  log_message "ERROR" "Monitoring action '$ACTION' failed"
fi

exit $action_status
