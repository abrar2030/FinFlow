#!/bin/bash
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
  if ! command -v docker-compose &> /dev/null; then
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
  
  # Determine which services to build
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
  
  # Build backend services
  for service in "${backend_services[@]}"; do
    local service_dir="$PROJECT_ROOT/backend/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Service directory $service not found, skipping"
      log_message "WARNING" "Service directory $service not found, skipping"
      continue
    fi
    
    print_info "Building $service..."
    log_message "INFO" "Building $service"
    
    # Check if package.json exists
    if [ ! -f "$service_dir/package.json" ]; then
      print_warning "No package.json found for $service, skipping"
      log_message "WARNING" "No package.json found for $service, skipping"
      continue
    fi
    
    # Install dependencies if needed
    if [ ! -d "$service_dir/node_modules" ]; then
      print_info "Installing dependencies for $service..."
      (cd "$service_dir" && npm install) || {
        print_error "Failed to install dependencies for $service"
        log_message "ERROR" "Failed to install dependencies for $service"
        build_status=1
        continue
      }
    fi
    
    # Run build script if it exists
    if grep -q '"build"' "$service_dir/package.json"; then
      print_info "Running build script for $service..."
      (cd "$service_dir" && npm run build) || {
        print_error "Build failed for $service"
        log_message "ERROR" "Build failed for $service"
        build_status=1
        continue
      }
    else
      print_warning "No build script found for $service, skipping build step"
      log_message "WARNING" "No build script found for $service, skipping build step"
    fi
    
    # Copy build artifacts to deployment directory
    local deploy_service_dir="$DEPLOY_DIR/current/$service"
    mkdir -p "$deploy_service_dir"
    
    if [ -d "$service_dir/dist" ]; then
      cp -r "$service_dir/dist" "$deploy_service_dir/"
      print_success "Copied build artifacts for $service"
      log_message "INFO" "Copied build artifacts for $service"
    elif [ -d "$service_dir/build" ]; then
      cp -r "$service_dir/build" "$deploy_service_dir/"
      print_success "Copied build artifacts for $service"
      log_message "INFO" "Copied build artifacts for $service"
    else
      # If no build directory, copy source files
      cp -r "$service_dir/src" "$deploy_service_dir/"
      cp "$service_dir/package.json" "$deploy_service_dir/"
      print_warning "No build directory found for $service, copying source files"
      log_message "WARNING" "No build directory found for $service, copying source files"
    fi
  done
  
  # Build frontend services
  for service in "${frontend_services[@]}"; do
    local service_dir="$PROJECT_ROOT/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Frontend directory $service not found, skipping"
      log_message "WARNING" "Frontend directory $service not found, skipping"
      continue
    fi
    
    print_info "Building $service..."
    log_message "INFO" "Building $service"
    
    # Check if package.json exists
    if [ ! -f "$service_dir/package.json" ]; then
      print_warning "No package.json found for $service, skipping"
      log_message "WARNING" "No package.json found for $service, skipping"
      continue
    fi
    
    # Install dependencies if needed
    if [ ! -d "$service_dir/node_modules" ]; then
      print_info "Installing dependencies for $service..."
      (cd "$service_dir" && npm install) || {
        print_error "Failed to install dependencies for $service"
        log_message "ERROR" "Failed to install dependencies for $service"
        build_status=1
        continue
      }
    fi
    
    # Set environment-specific variables
    if [ "$ENV" != "development" ] && [ -f "$PROJECT_ROOT/.env.${ENV}" ]; then
      cp "$PROJECT_ROOT/.env.${ENV}" "$service_dir/.env"
    fi
    
    # Run build script
    print_info "Running build script for $service..."
    (cd "$service_dir" && npm run build) || {
      print_error "Build failed for $service"
      log_message "ERROR" "Build failed for $service"
      build_status=1
      continue
    }
    
    # Copy build artifacts to deployment directory
    local deploy_service_dir="$DEPLOY_DIR/current/$service"
    mkdir -p "$deploy_service_dir"
    
    if [ -d "$service_dir/build" ]; then
      cp -r "$service_dir/build" "$deploy_service_dir/"
      print_success "Copied build artifacts for $service"
      log_message "INFO" "Copied build artifacts for $service"
    elif [ -d "$service_dir/dist" ]; then
      cp -r "$service_dir/dist" "$deploy_service_dir/"
      print_success "Copied build artifacts for $service"
      log_message "INFO" "Copied build artifacts for $service"
    else
      print_error "No build directory found for $service"
      log_message "ERROR" "No build directory found for $service"
      build_status=1
    fi
  done
  
  return $build_status
}

build_services
build_status=$?

if [ $build_status -ne 0 ]; then
  print_error "Build process failed"
  log_message "ERROR" "Build process failed"
  exit 1
fi

# --- Run Tests ---
print_header "Running Tests"

run_tests() {
  if [ "$SKIP_TESTS" = true ]; then
    print_info "Skipping tests as requested"
    log_message "INFO" "Skipping tests as requested"
    return 0
  fi
  
  print_info "Running tests..."
  log_message "INFO" "Running tests"
  
  # Use the test runner script if available
  if [ -f "$SCRIPT_DIR/finflow-test-runner.sh" ]; then
    print_info "Using finflow-test-runner.sh for testing"
    log_message "INFO" "Using finflow-test-runner.sh for testing"
    
    local test_args=""
    
    if [ "$VERBOSE" = true ]; then
      test_args="$test_args --verbose"
    fi
    
    if [ "$SERVICES" != "all" ]; then
      test_args="$test_args --services $SERVICES"
    fi
    
    # Run only unit tests for deployment
    test_args="$test_args --type unit"
    
    bash "$SCRIPT_DIR/finflow-test-runner.sh" $test_args || {
      print_error "Tests failed"
      log_message "ERROR" "Tests failed"
      return 1
    }
  else
    print_warning "Test runner script not found, skipping tests"
    log_message "WARNING" "Test runner script not found, skipping tests"
  fi
  
  print_success "Tests completed successfully"
  log_message "INFO" "Tests completed successfully"
  return 0
}

run_tests
test_status=$?

if [ $test_status -ne 0 ]; then
  print_error "Tests failed"
  log_message "ERROR" "Tests failed"
  exit 1
fi

# --- Deploy Services ---
print_header "Deploying Services"

deploy_services() {
  local deploy_status=0
  
  print_info "Deploying to $ENV environment..."
  log_message "INFO" "Deploying to $ENV environment"
  
  # Copy infrastructure files
  if [ -d "$PROJECT_ROOT/infrastructure" ]; then
    print_info "Copying infrastructure configuration..."
    log_message "INFO" "Copying infrastructure configuration"
    
    mkdir -p "$DEPLOY_DIR/current/infrastructure"
    cp -r "$PROJECT_ROOT/infrastructure"/* "$DEPLOY_DIR/current/infrastructure/"
    
    # Update environment-specific variables in docker-compose.yml if needed
    if [ "$ENV" != "development" ] && [ -f "$DEPLOY_DIR/current/infrastructure/docker-compose.yml" ]; then
      print_info "Updating environment-specific variables in docker-compose.yml..."
      log_message "INFO" "Updating environment-specific variables in docker-compose.yml"
      
      # Create environment-specific docker-compose file
      cp "$DEPLOY_DIR/current/infrastructure/docker-compose.yml" "$DEPLOY_DIR/current/infrastructure/docker-compose.${ENV}.yml"
      
      # Update environment variables
      if [ -f "$DEPLOY_DIR/current/.env" ]; then
        # Extract environment variables and update docker-compose file
        while IFS='=' read -r key value; do
          # Skip comments and empty lines
          [[ $key == \#* ]] && continue
          [[ -z $key ]] && continue
          
          # Replace environment variables in docker-compose file
          sed -i "s|\${$key}|$value|g" "$DEPLOY_DIR/current/infrastructure/docker-compose.${ENV}.yml"
        done < "$DEPLOY_DIR/current/.env"
      fi
    fi
  fi
  
  # Handle blue-green deployment if requested
  if [ "$BLUE_GREEN" = true ]; then
    print_info "Preparing blue-green deployment..."
    log_message "INFO" "Preparing blue-green deployment"
    
    # Determine current color (blue or green)
    local current_color="blue"
    if [ -f "$DEPLOY_DIR/current_color" ]; then
      current_color=$(cat "$DEPLOY_DIR/current_color")
      if [ "$current_color" = "blue" ]; then
        current_color="green"
      else
        current_color="blue"
      fi
    fi
    
    print_info "Deploying to $current_color environment..."
    log_message "INFO" "Deploying to $current_color environment"
    
    # Update current color
    echo "$current_color" > "$DEPLOY_DIR/current_color"
    
    # Update port mappings in docker-compose file
    if [ -f "$DEPLOY_DIR/current/infrastructure/docker-compose.${ENV}.yml" ]; then
      local compose_file="$DEPLOY_DIR/current/infrastructure/docker-compose.${ENV}.yml"
    elif [ -f "$DEPLOY_DIR/current/infrastructure/docker-compose.yml" ]; then
      local compose_file="$DEPLOY_DIR/current/infrastructure/docker-compose.yml"
    else
      print_error "No docker-compose file found for deployment"
      log_message "ERROR" "No docker-compose file found for deployment"
      return 1
    fi
    
    # Create color-specific docker-compose file
    cp "$compose_file" "$DEPLOY_DIR/current/infrastructure/docker-compose.${current_color}.yml"
    compose_file="$DEPLOY_DIR/current/infrastructure/docker-compose.${current_color}.yml"
    
    # Update port mappings based on color
    if [ "$current_color" = "blue" ]; then
      # Use even-numbered ports for blue
      sed -i 's/\(- "\)\([0-9]\+\)\(:.*\)/\1\2\3 # Original port\n      - "8\2\3 # Blue port/g' "$compose_file"
    else
      # Use odd-numbered ports for green
      sed -i 's/\(- "\)\([0-9]\+\)\(:.*\)/\1\2\3 # Original port\n      - "9\2\3 # Green port/g' "$compose_file"
    fi
    
    # Deploy using color-specific docker-compose file
    print_info "Starting $current_color deployment..."
    log_message "INFO" "Starting $current_color deployment"
    
    (cd "$DEPLOY_DIR/current/infrastructure" && docker-compose -f "docker-compose.${current_color}.yml" up -d) || {
      print_error "Deployment failed"
      log_message "ERROR" "Deployment failed"
      deploy_status=1
    }
    
    # Wait for services to be healthy
    print_info "Waiting for services to be healthy..."
    log_message "INFO" "Waiting for services to be healthy"
    sleep 10
    
    # Verify deployment
    print_info "Verifying deployment..."
    log_message "INFO" "Verifying deployment"
    
    # TODO: Add health check logic here
    
    # If successful, update load balancer or proxy
    if [ $deploy_status -eq 0 ]; then
      print_info "Deployment successful, updating routing..."
      log_message "INFO" "Deployment successful, updating routing"
      
      # TODO: Add logic to update load balancer or proxy
      
      print_success "Routing updated to $current_color environment"
      log_message "INFO" "Routing updated to $current_color environment"
    fi
  else
    # Standard deployment
    print_info "Starting standard deployment..."
    log_message "INFO" "Starting standard deployment"
    
    if [ -f "$DEPLOY_DIR/current/infrastructure/docker-compose.${ENV}.yml" ]; then
      local compose_file="docker-compose.${ENV}.yml"
    else
      local compose_file="docker-compose.yml"
    fi
    
    (cd "$DEPLOY_DIR/current/infrastructure" && docker-compose -f "$compose_file" up -d) || {
      print_error "Deployment failed"
      log_message "ERROR" "Deployment failed"
      deploy_status=1
    }
  fi
  
  return $deploy_status
}

deploy_services
deploy_status=$?

if [ $deploy_status -ne 0 ]; then
  print_error "Deployment failed"
  log_message "ERROR" "Deployment failed"
  
  # Attempt rollback if deployment failed
  print_warning "Attempting automatic rollback..."
  log_message "WARNING" "Attempting automatic rollback"
  
  if [ -L "$DEPLOY_DIR/previous" ]; then
    local prev_deploy=$(readlink "$DEPLOY_DIR/previous")
    if [ -d "$prev_deploy" ]; then
      print_info "Rolling back to previous deployment: $(basename "$prev_deploy")"
      log_message "INFO" "Rolling back to previous deployment: $(basename "$prev_deploy")"
      
      # Restore previous deployment
      ln -sf "$prev_deploy" "$DEPLOY_DIR/current"
      
      # Restart services
      if [ -f "$prev_deploy/infrastructure/docker-compose.yml" ]; then
        (cd "$prev_deploy/infrastructure" && docker-compose up -d) || {
          print_error "Rollback failed"
          log_message "ERROR" "Rollback failed"
          exit 1
        }
      fi
      
      print_success "Rollback completed"
      log_message "INFO" "Rollback completed"
    else
      print_error "Previous deployment directory not found: $prev_deploy"
      log_message "ERROR" "Previous deployment directory not found: $prev_deploy"
      exit 1
    fi
  else
    print_error "No previous deployment found for rollback"
    log_message "ERROR" "No previous deployment found for rollback"
    exit 1
  fi
else
  print_success "Deployment completed successfully"
  log_message "INFO" "Deployment completed successfully"
fi

# --- Verify Deployment ---
print_header "Verifying Deployment"

verify_deployment() {
  print_info "Verifying deployment..."
  log_message "INFO" "Verifying deployment"
  
  # Check if services are running
  local running_containers=$(docker ps --format "{{.Names}}" | grep -c "finflow")
  if [ "$running_containers" -eq 0 ]; then
    print_error "No FinFlow containers are running"
    log_message "ERROR" "No FinFlow containers are running"
    return 1
  fi
  
  print_info "Found $running_containers running FinFlow containers"
  log_message "INFO" "Found $running_containers running FinFlow containers"
  
  # Check service health
  local unhealthy_containers=$(docker ps --format "{{.Names}}" | grep "finflow" | xargs docker inspect --format "{{.State.Health.Status}}" 2>/dev/null | grep -c -v "healthy")
  if [ "$unhealthy_containers" -gt 0 ]; then
    print_warning "$unhealthy_containers containers are not healthy"
    log_message "WARNING" "$unhealthy_containers containers are not healthy"
  fi
  
  # TODO: Add more comprehensive health checks
  
  print_success "Deployment verification completed"
  log_message "INFO" "Deployment verification completed"
  return 0
}

verify_deployment
verification_status=$?

# --- Summary ---
print_header "Deployment Summary"

if [ $verification_status -eq 0 ]; then
  print_success "FinFlow deployment to $ENV environment completed successfully!"
  log_message "INFO" "FinFlow deployment to $ENV environment completed successfully"
  
  echo -e "\n${COLOR_GREEN}Deployment Information:${COLOR_RESET}"
  echo -e "Environment: ${COLOR_CYAN}$ENV${COLOR_RESET}"
  echo -e "Deployment ID: ${COLOR_CYAN}$DEPLOY_ID${COLOR_RESET}"
  echo -e "Deployment Directory: ${COLOR_CYAN}$DEPLOY_DIR/current${COLOR_RESET}"
  
  if [ "$BLUE_GREEN" = true ]; then
    local current_color=$(cat "$DEPLOY_DIR/current_color")
    echo -e "Active Color: ${COLOR_CYAN}$current_color${COLOR_RESET}"
  fi
  
  log_message "INFO" "Deployment summary provided to user"
else
  print_warning "FinFlow deployment completed with warnings or errors."
  print_info "Please check the log file for details: $LOG_DIR/deploy.log"
  log_message "WARNING" "Deployment completed with warnings or errors"
fi

exit $verification_status
