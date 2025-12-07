#!/bin/bash
set -euo pipefail
# FinFlow Enhanced Deployment Script
# This script automates the build and deployment process with environment-specific configuration
# Version: 1.0.0

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
LOG_DIR="$PROJECT_ROOT/logs"
DEPLOY_DIR="$PROJECT_ROOT/deploy"

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
  echo "[$timestamp] [$level] $message" >> "$LOG_DIR/deploy.log"
}

# --- Command Line Arguments ---
VERBOSE=false
ENV="development"
SERVICES="all"
SKIP_BUILD=false
SKIP_TESTS=false
ROLLBACK=false
BLUE_GREEN=false

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -e, --environment ENV      Set environment (development, staging, production)"
  echo "  -s, --services SERVICES    Comma-separated list of services to deploy (default: all)"
  echo "  --skip-build               Skip build step"
  echo "  --skip-tests               Skip tests"
  echo "  --rollback                 Rollback to previous version"
  echo "  --blue-green               Use blue-green deployment strategy"
  echo
  echo "Examples:"
  echo "  $0 --environment production"
  echo "  $0 --services auth-service,payments-service"
  echo "  $0 --blue-green --environment staging"
  exit 0
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -e|--environment) ENV="$2"; shift 2 ;;
    -s|--services) SERVICES="$2"; shift 2 ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    --skip-tests) SKIP_TESTS=true; shift ;;
    --rollback) ROLLBACK=true; shift ;;
    --blue-green) BLUE_GREEN=true; shift ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Initialization ---
print_header "FinFlow Deployment"
print_info "Starting deployment process for environment: $ENV"

# Create necessary directories
mkdir -p "$LOG_DIR" "$DEPLOY_DIR" "$DEPLOY_DIR/history"

# Initialize log file
echo "=== FinFlow Deployment Log $(date) ===" > "$LOG_DIR/deploy.log"
log_message "INFO" "Starting deployment for environment: $ENV"

# --- Validate Deployment Environment ---
print_header "Validating Deployment Environment"

validate_environment() {
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
  if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
    print_error "Docker Compose is required but not installed."
    log_message "ERROR" "Docker Compose is required but not installed"
    exit 1
  fi
  
  # Check if Node.js is installed
  if ! command -v node &> /dev/null; then
    print_error "Node.js is required but not installed."
    log_message "ERROR" "Node.js is required but not installed"
    exit 1
  fi
  
  # Check Node.js version
  NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
  if [[ $NODE_VERSION -lt 16 ]]; then
    print_warning "Node.js version 16+ recommended. Found: v$NODE_VERSION"
    log_message "WARNING" "Node.js version 16+ recommended. Found: v$NODE_VERSION"
  fi
  
  # Check if npm is installed
  if ! command -v npm &> /dev/null; then
    print_error "npm is required but not installed."
    log_message "ERROR" "npm is required but not installed"
    exit 1
  fi
  
  # Check if environment-specific configuration exists
  if [ "$ENV" != "development" ]; then
    if [ ! -f "$PROJECT_ROOT/.env.${ENV}" ]; then
      print_warning "Environment-specific .env.${ENV} file not found. Will use default .env"
      log_message "WARNING" "Environment-specific .env.${ENV} file not found"
    fi
  fi
  
  print_success "Deployment environment validation completed"
  log_message "INFO" "Deployment environment validation completed"
}

validate_environment

# --- Prepare Environment Configuration ---
print_header "Preparing Environment Configuration"

prepare_environment() {
  # Create deployment timestamp
  local timestamp=$(date "+%Y%m%d%H%M%S")
  local deploy_id="${ENV}-${timestamp}"
  
  # Create deployment directory
  local deploy_path="$DEPLOY_DIR/history/$deploy_id"
  mkdir -p "$deploy_path"
  
  # Create environment file
  if [ "$ENV" != "development" ] && [ -f "$PROJECT_ROOT/.env.${ENV}" ]; then
    cp "$PROJECT_ROOT/.env.${ENV}" "$deploy_path/.env"
    print_info "Using environment-specific configuration from .env.${ENV}"
    log_message "INFO" "Using environment-specific configuration from .env.${ENV}"
  elif [ -f "$PROJECT_ROOT/.env" ]; then
    cp "$PROJECT_ROOT/.env" "$deploy_path/.env"
    print_info "Using default configuration from .env"
    log_message "INFO" "Using default configuration from .env"
  else
    print_error "No environment configuration found"
    log_message "ERROR" "No environment configuration found"
    exit 1
  fi
  
  # Create symlink to current deployment
  if [ -L "$DEPLOY_DIR/current" ]; then
    # Store previous deployment for potential rollback
    local prev_deploy=$(readlink "$DEPLOY_DIR/current")
    if [ -d "$prev_deploy" ]; then
      ln -sf "$prev_deploy" "$DEPLOY_DIR/previous"
      print_info "Previous deployment saved for potential rollback"
      log_message "INFO" "Previous deployment saved for potential rollback"
    fi
  fi
  
  # Update current deployment symlink
  ln -sf "$deploy_path" "$DEPLOY_DIR/current"
  
  print_success "Environment configuration prepared"
  log_message "INFO" "Environment configuration prepared with deploy ID: $deploy_id"
  
  # Return the deploy ID
  echo "$deploy_id"
}

# Handle rollback if requested
if [ "$ROLLBACK" = true ]; then
  print_header "Performing Rollback"
  
  if [ ! -L "$DEPLOY_DIR/previous" ]; then
    print_error "No previous deployment found for rollback"
    log_message "ERROR" "No previous deployment found for rollback"
    exit 1
  fi
  
  local prev_deploy=$(readlink "$DEPLOY_DIR/previous")
  if [ ! -d "$prev_deploy" ]; then
    print_error "Previous deployment directory not found: $prev_deploy"
    log_message "ERROR" "Previous deployment directory not found: $prev_deploy"
    exit 1
  fi
  
  print_info "Rolling back to previous deployment: $(basename "$prev_deploy")"
  log_message "INFO" "Rolling back to previous deployment: $(basename "$prev_deploy")"
  
  # Swap current and previous
  ln -sf "$prev_deploy" "$DEPLOY_DIR/current"
  
  print_success "Rollback completed"
  log_message "INFO" "Rollback completed"
  
  # Skip to deployment step
  SKIP_BUILD=true
  SKIP_TESTS=true
else
  # Prepare environment for new deployment
  DEPLOY_ID=$(prepare_environment)
  print_info "Deployment ID: $DEPLOY_ID"
fi

# --- Build Services ---
print_header "Building Services"

build_services() {
  local build_status=0
  
  if [ "$SKIP_BUILD" = true ]; then
    print_info "Skipping build step as requested"
    log_message "INFO" "Skipping build step as requested"
    return 0
  fi

  print_info "Running build script..."
  log_message "INFO" "Running build script"

  local build_args=""
  if [ "$SERVICES" != "all" ]; then
    build_args="--services $SERVICES"
  fi

  "$SCRIPT_DIR/finflow-build.sh" $build_args || build_status=$?

  return $build_status
}

build_services
build_status=$?

# --- Run Tests ---
print_header "Running Tests"

run_tests() {
  local test_status=0
  
  if [ "$SKIP_TESTS" = true ]; then
    print_info "Skipping tests as requested"
    log_message "INFO" "Skipping tests as requested"
    return 0
  fi
  
  print_info "Running test runner script..."
  log_message "INFO" "Running test runner script"
  
  local test_args=""
  if [ "$SERVICES" != "all" ]; then
    test_args="--services $SERVICES"
  fi
  
  "$SCRIPT_DIR/finflow-test-runner.sh" $test_args || test_status=$?
  
  return $test_status
}

run_tests
test_status=$?

# --- Deploy Services ---
print_header "Deploying Services"

deploy_services() {
  local deploy_status=0
  
  # Determine which services to deploy
  if [ "$SERVICES" = "all" ]; then
    local backend_services=("auth-service" "payments-service" "accounting-service" "analytics-service" "credit-engine")
    local frontend_services=("web-frontend" "mobile-frontend")
  else
    IFS=',' read -ra all_services <<< "$SERVICES"
    local backend_services=()
    local frontend_services=()
    
    for service in "${all_services[@]}"; do
      if [[ "$service" == *"frontend"* ]]; then
        frontend_services+=("$service")
      else
        backend_services+=("$service")
      fi
    done
  fi
  
  # Deploy backend services
  for service in "${backend_services[@]}"; do
    print_info "Deploying $service..."
    log_message "INFO" "Deploying $service"
    
    # Example deployment logic (e.g., using Docker Compose)
    # This is a placeholder and should be adapted to the actual deployment environment
    
    # Check if Docker Compose is available
    local DOCKER_COMPOSE_CMD
    if command -v docker-compose &> /dev/null; then
      DOCKER_COMPOSE_CMD="docker-compose"
    elif command -v docker compose &> /dev/null; then
      DOCKER_COMPOSE_CMD="docker compose"
    else
      print_error "Docker Compose is not available. Cannot deploy."
      log_message "ERROR" "Docker Compose is not available. Cannot deploy."
      deploy_status=1
      continue
    fi
    
    # Use docker-compose to deploy the service
    # Assuming a docker-compose file exists in the project root or a deployment directory
    # For a real-world scenario, this would involve a more complex orchestration tool (e.g., Kubernetes, ECS)
    
    # Example: Deploying a single service with Docker Compose
    # (cd "$PROJECT_ROOT" && $DOCKER_COMPOSE_CMD up -d --no-deps "$service") || {
    #   print_error "Deployment failed for $service"
    #   log_message "ERROR" "Deployment failed for $service"
    #   deploy_status=1
    #   continue
    # }
    
    print_success "Deployment of $service simulated successfully"
    log_message "INFO" "Deployment of $service simulated successfully"
  done
  
  # Deploy frontend services
  for service in "${frontend_services[@]}"; do
    print_info "Deploying $service..."
    log_message "INFO" "Deploying $service"
    
    # Example deployment logic for frontend (e.g., to a static hosting service)
    # This is a placeholder and should be adapted to the actual deployment environment
    
    print_success "Deployment of $service simulated successfully"
    log_message "INFO" "Deployment of $service simulated successfully"
  done
  
  return $deploy_status
}

deploy_services
deploy_status=$?

# --- Summary ---
print_header "Deployment Summary"

if [ $deploy_status -eq 0 ]; then
  print_success "Deployment completed successfully!"
  log_message "INFO" "Deployment completed successfully"
else
  print_error "Deployment failed. Check logs for details."
  log_message "ERROR" "Deployment failed"
fi

exit $deploy_status
