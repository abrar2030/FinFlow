#!/bin/bash\nset -euo pipefail
# FinFlow Comprehensive Environment Setup Script
# This script automates the complete setup process for the FinFlow platform
# Version: 1.0.0

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
LOG_DIR="$PROJECT_ROOT/logs"
DATA_DIR="$PROJECT_ROOT/data"

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
  echo "[$timestamp] [$level] $message" >> "$LOG_DIR/setup.log"
}

# --- Command Line Arguments ---
VERBOSE=false
SKIP_DEPS=false
ENV="development"
SERVICES="all"

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -s, --skip-dependencies    Skip dependency installation"
  echo "  -e, --environment ENV      Set environment (development, staging, production)"
  echo "  --services SERVICES        Comma-separated list of services to set up (default: all)"
  echo
  echo "Examples:"
  echo "  $0 --verbose"
  echo "  $0 --environment production"
  echo "  $0 --services auth-service,payments-service"
  exit 0
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -s|--skip-dependencies) SKIP_DEPS=true; shift ;;
    -e|--environment) ENV="$2"; shift 2 ;;
    --services) SERVICES="$2"; shift 2 ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Initialization ---
print_header "FinFlow Environment Setup"
print_info "Starting setup process in $ENV environment"

# Create necessary directories
mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$DATA_DIR"
mkdir -p "$DATA_DIR/mongodb" "$DATA_DIR/postgres" "$DATA_DIR/kafka"

# Initialize log file
echo "=== FinFlow Setup Log $(date) ===" > "$LOG_DIR/setup.log"
log_message "INFO" "Starting setup in $ENV environment"

# --- Prerequisite Checks ---
print_header "System Prerequisite Checks"

check_command() {
  if ! command -v $1 &> /dev/null; then
    print_error "$1 is required but not installed."
    log_message "ERROR" "$1 is required but not installed"
    if [ "$SKIP_DEPS" = false ]; then
      print_info "Attempting to install $1..."
      install_dependency "$1"
    else
      print_warning "Skipping installation as --skip-dependencies was specified"
      return 1
    fi
  else
    print_success "$1 is installed"
    log_message "INFO" "$1 is installed"
    return 0
  fi
}

install_dependency() {
  local dep="$1"
  case "$dep" in
    node)
      if command -v apt-get &> /dev/null; then
        print_info "Installing Node.js via apt..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
      elif command -v brew &> /dev/null; then
        print_info "Installing Node.js via Homebrew..."
        brew install node@16
      else
        print_error "Could not determine package manager. Please install Node.js manually."
        return 1
      fi
      ;;
    docker)
      if command -v apt-get &> /dev/null; then
        print_info "Installing Docker via apt..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
      elif command -v brew &> /dev/null; then
        print_info "Installing Docker via Homebrew..."
        brew install --cask docker
      else
        print_error "Could not determine package manager. Please install Docker manually."
        return 1
      fi
      ;;
    docker-compose)\n      # Check for both legacy and modern docker compose
      if command -v apt-get &> /dev/null; then
        print_info "Installing Docker Compose via apt..."
        # Modern Docker Compose is installed with Docker Desktop or via package manager\n    # Legacy installation is complex and often requires manual steps, so we'll simplify\n    print_warning "Manual installation of legacy docker-compose is complex. Please ensure 'docker compose' or 'docker-compose' is available."\n    return 1
        sudo chmod +x /usr/local/bin/docker-compose
      elif command -v brew &> /dev/null; then
        print_info "Installing Docker Compose via Homebrew..."
        brew install docker-compose
      else
        print_error "Could not determine package manager. Please install Docker Compose manually."
        return 1
      fi
      ;;
    *)
      print_error "Don't know how to install $dep"
      return 1
      ;;
  esac
  
  if command -v $dep &> /dev/null; then
    print_success "$dep was installed successfully"
    log_message "INFO" "$dep was installed successfully"
    return 0
  else
    print_error "Failed to install $dep"
    log_message "ERROR" "Failed to install $dep"
    return 1
  fi
}

# Check for required tools
check_command node || exit 1
check_command npm || exit 1
check_command docker || exit 1
check_command docker-compose || (\n    # Check for modern docker compose command if docker-compose is not found\n    if ! command -v docker compose &> /dev/null; then\n        print_error "Neither docker-compose nor 'docker compose' is installed."\n        log_message "ERROR" "Neither docker-compose nor 'docker compose' is installed."\n        exit 1\n    fi\n)

# Check Node.js version
NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
if [[ $NODE_VERSION -lt 16 ]]; then
  print_error "Node.js version 16+ required. Found: v$NODE_VERSION"
  log_message "ERROR" "Node.js version 16+ required. Found: v$NODE_VERSION"
  exit 1
fi

# --- Environment Variables Setup ---
print_header "Environment Variables Setup"

setup_env_file() {
  local env_file="$PROJECT_ROOT/.env"
  
  if [ -f "$env_file" ]; then
    print_warning ".env file already exists. Checking for missing variables..."
    log_message "WARNING" ".env file already exists. Checking for missing variables..."
  else
    print_info "Creating new .env file..."
    log_message "INFO" "Creating new .env file"
    
    # Create base .env file
    cat > "$env_file" << EOL
# FinFlow Environment Variables
# Generated by finflow-setup.sh on $(date)
NODE_ENV=${ENV}

# Auth Service
AUTH_PORT=3001
JWT_SECRET=$(openssl rand -hex 32)
JWT_EXPIRY=24h

# Payments Service
PAYMENTS_PORT=3002
STRIPE_API_KEY=your_stripe_api_key

# Accounting Service
ACCOUNTING_PORT=3003

# Analytics Service
ANALYTICS_PORT=3004

# Credit Engine
CREDIT_ENGINE_PORT=3005

# Database
POSTGRES_USER=finflow
POSTGRES_PASSWORD=$(openssl rand -hex 16)
POSTGRES_DB=finflow
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# MongoDB
MONGODB_URI=mongodb://localhost:27017/finflow

# Kafka
KAFKA_BROKER=localhost:9092
KAFKA_ZOOKEEPER=localhost:2181
EOL
    print_success "Created default .env file"
    log_message "INFO" "Created default .env file"
  fi
  
  # Check for environment-specific overrides
  if [ "$ENV" != "development" ]; then
    local env_override="$PROJECT_ROOT/.env.${ENV}"
    if [ ! -f "$env_override" ]; then
      print_info "Creating environment-specific .env.${ENV} file..."
      log_message "INFO" "Creating environment-specific .env.${ENV} file"
      
      # Create environment-specific overrides
      cat > "$env_override" << EOL
# FinFlow ${ENV} Environment Variables
# Generated by finflow-setup.sh on $(date)
NODE_ENV=${ENV}

# Add environment-specific overrides here
EOL
      print_success "Created .env.${ENV} file"
      log_message "INFO" "Created .env.${ENV} file"
    else
      print_warning ".env.${ENV} file already exists. Skipping creation."
      log_message "WARNING" ".env.${ENV} file already exists. Skipping creation."
    fi
  fi
}

setup_env_file

# --- Backend Services Setup ---
print_header "Backend Services Setup"

setup_backend_services() {
  if [ "$SERVICES" = "all" ]; then
    local services=("auth-service" "payments-service" "accounting-service" "analytics-service" "credit-engine")
  else
    IFS=',' read -ra services <<< "$SERVICES"
  fi
  
  for service in "${services[@]}"; do
    local service_dir="$PROJECT_ROOT/backend/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Service directory $service not found, skipping"
      log_message "WARNING" "Service directory $service not found, skipping"
      continue
    fi
    
    print_info "Setting up $service..."
    log_message "INFO" "Setting up $service"
    
    # Install dependencies
    (cd "$service_dir" && npm install) || {
      print_error "Failed to install dependencies for $service"
      log_message "ERROR" "Failed to install dependencies for $service"
      continue
    }
    
    # Create service-specific .env file if it doesn't exist
    if [ ! -f "$service_dir/.env" ]; then
      print_info "Creating service-specific .env file for $service..."
      log_message "INFO" "Creating service-specific .env file for $service"
      
      # Link to root .env file
      ln -s "$PROJECT_ROOT/.env" "$service_dir/.env"
      print_success "Linked .env file for $service"
      log_message "INFO" "Linked .env file for $service"
    fi
    
    print_success "Successfully set up $service"
    log_message "INFO" "Successfully set up $service"
  done
}

setup_backend_services

# --- Frontend Setup ---
print_header "Frontend Setup"

setup_frontend() {
  local frontend_dir="$PROJECT_ROOT/web-frontend"
  
  if [ ! -d "$frontend_dir" ]; then
    print_warning "Frontend directory not found, skipping"
    log_message "WARNING" "Frontend directory not found, skipping"
    return
  fi
  
  print_info "Setting up frontend..."
  log_message "INFO" "Setting up frontend"
  
  # Install dependencies
  (cd "$frontend_dir" && npm install) || {
    print_error "Failed to install dependencies for frontend"
    log_message "ERROR" "Failed to install dependencies for frontend"
    return
  }
  
  # Create frontend .env file if it doesn't exist
  if [ ! -f "$frontend_dir/.env" ]; then
    print_info "Creating frontend .env file..."
    log_message "INFO" "Creating frontend .env file"
    
    # Create frontend-specific env file
    cat > "$frontend_dir/.env" << EOL
# FinFlow Frontend Environment Variables
# Generated by finflow-setup.sh on $(date)
REACT_APP_API_URL=http://localhost:8080
REACT_APP_AUTH_URL=http://localhost:3001
REACT_APP_ENV=${ENV}
EOL
    print_success "Created frontend .env file"
    log_message "INFO" "Created frontend .env file"
  fi
  
  print_success "Successfully set up frontend"
  log_message "INFO" "Successfully set up frontend"
}

setup_frontend

# --- Mobile Frontend Setup ---
print_header "Mobile Frontend Setup"

setup_mobile_frontend() {
  local mobile_dir="$PROJECT_ROOT/mobile-frontend"
  
  if [ ! -d "$mobile_dir" ]; then
    print_warning "Mobile frontend directory not found, skipping"
    log_message "WARNING" "Mobile frontend directory not found, skipping"
    return
  fi
  
  print_info "Setting up mobile frontend..."
  log_message "INFO" "Setting up mobile frontend"
  
  # Install dependencies
  (cd "$mobile_dir" && npm install) || {
    print_error "Failed to install dependencies for mobile frontend"
    log_message "ERROR" "Failed to install dependencies for mobile frontend"
    return
  }
  
  # Create mobile .env file if it doesn't exist
  if [ ! -f "$mobile_dir/.env" ]; then
    print_info "Creating mobile .env file..."
    log_message "INFO" "Creating mobile .env file"
    
    # Create mobile-specific env file
    cat > "$mobile_dir/.env" << EOL
# FinFlow Mobile Environment Variables
# Generated by finflow-setup.sh on $(date)
API_URL=http://localhost:8080
AUTH_URL=http://localhost:3001
ENV=${ENV}
EOL
    print_success "Created mobile .env file"
    log_message "INFO" "Created mobile .env file"
  fi
  
  print_success "Successfully set up mobile frontend"
  log_message "INFO" "Successfully set up mobile frontend"
}

setup_mobile_frontend

# --- Infrastructure Setup ---
print_header "Infrastructure Setup"

setup_infrastructure() {
  local infra_dir="$PROJECT_ROOT/infrastructure"
  
  if [ ! -d "$infra_dir" ]; then
    print_warning "Infrastructure directory not found, skipping"
    log_message "WARNING" "Infrastructure directory not found, skipping"
    return
  fi
  
  print_info "Setting up infrastructure..."
  log_message "INFO" "Setting up infrastructure"
  
  # Check if docker-compose.yml exists
  if [ ! -f "$infra_dir/docker-compose.yml" ]; then
    print_error "docker-compose.yml not found in infrastructure directory"
    log_message "ERROR" "docker-compose.yml not found in infrastructure directory"
    return
  fi
  
  # Pull Docker images
  print_info "Pulling Docker images..."
  log_message "INFO" "Pulling Docker images"
  (cd "$infra_dir" && docker-compose pull) || {
    print_error "Failed to pull Docker images"
    log_message "ERROR" "Failed to pull Docker images"
    return
  }
  
  print_success "Successfully set up infrastructure"
  log_message "INFO" "Successfully set up infrastructure"
}

setup_infrastructure

# --- Monitoring Setup ---
print_header "Monitoring Setup"

setup_monitoring() {
  local monitoring_dir="$PROJECT_ROOT/monitoring"
  
  if [ ! -d "$monitoring_dir" ]; then
    print_warning "Monitoring directory not found, skipping"
    log_message "WARNING" "Monitoring directory not found, skipping"
    return
  fi
  
  print_info "Setting up monitoring..."
  log_message "INFO" "Setting up monitoring"
  
  # Check if prometheus.yml exists
  if [ ! -f "$monitoring_dir/prometheus.yml" ]; then
    print_error "prometheus.yml not found in monitoring directory"
    log_message "ERROR" "prometheus.yml not found in monitoring directory"
    return
  }
  
  print_success "Successfully set up monitoring"
  log_message "INFO" "Successfully set up monitoring"
}

setup_monitoring

# --- Final Verification ---
print_header "Verification"

verify_setup() {
  local status=0
  
  # Check if .env file exists
  if [ ! -f "$PROJECT_ROOT/.env" ]; then
    print_error ".env file not found"
    log_message "ERROR" ".env file not found"
    status=1
  else
    print_success ".env file exists"
    log_message "INFO" ".env file exists"
  fi
  
  # Check if backend services are set up
  if [ "$SERVICES" = "all" ]; then
    local services=("auth-service" "payments-service" "accounting-service" "analytics-service" "credit-engine")
  else
    IFS=',' read -ra services <<< "$SERVICES"
  fi
  
  for service in "${services[@]}"; do
    local service_dir="$PROJECT_ROOT/backend/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Service directory $service not found"
      log_message "WARNING" "Service directory $service not found"
      continue
    fi
    
    if [ ! -d "$service_dir/node_modules" ]; then
      print_error "Dependencies not installed for $service"
      log_message "ERROR" "Dependencies not installed for $service"
      status=1
    else
      print_success "Dependencies installed for $service"
      log_message "INFO" "Dependencies installed for $service"
    fi
  done
  
  # Check if infrastructure is set up
  local infra_dir="$PROJECT_ROOT/infrastructure"
  if [ -d "$infra_dir" ] && [ -f "$infra_dir/docker-compose.yml" ]; then
    print_success "Infrastructure is set up"
    log_message "INFO" "Infrastructure is set up"
  else
    print_warning "Infrastructure may not be properly set up"
    log_message "WARNING" "Infrastructure may not be properly set up"
  fi
  
  return $status
}

verify_setup
verification_status=$?

# --- Summary ---
print_header "Setup Summary"

if [ $verification_status -eq 0 ]; then
  print_success "FinFlow environment setup completed successfully!"
  log_message "INFO" "FinFlow environment setup completed successfully"
  
  echo -e "\n${COLOR_GREEN}Next Steps:${COLOR_RESET}"
  echo -e "1. Start the infrastructure: ${COLOR_CYAN}cd $PROJECT_ROOT/infrastructure && docker-compose up -d${COLOR_RESET}"
  echo -e "2. Start the backend services: ${COLOR_CYAN}cd $PROJECT_ROOT/backend/[service] && npm run start:dev${COLOR_RESET}"
  echo -e "3. Start the frontend: ${COLOR_CYAN}cd $PROJECT_ROOT/web-frontend && npm start${COLOR_RESET}"
  
  log_message "INFO" "Setup completed with next steps provided to user"
else
  print_warning "FinFlow environment setup completed with warnings or errors."
  print_info "Please check the log file for details: $LOG_DIR/setup.log"
  log_message "WARNING" "Setup completed with warnings or errors"
fi

exit $verification_status
