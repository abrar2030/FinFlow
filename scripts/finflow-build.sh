#!/bin/bash
set -euo pipefail

# FinFlow Unified Build Script
# This script automates the build process for all services
# Version: 1.0.0

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"

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
  echo "[$timestamp] [$level] $message" >> "$LOG_DIR/build.log"
}

# --- Command Line Arguments ---
VERBOSE=false
SERVICES="all"

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -s, --services SERVICES    Comma-separated list of services to build (default: all)"
  echo
  echo "Examples:"
  echo "  $0"
  echo "  $0 --services web-frontend,auth-service"
  exit 0
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -s|--services) SERVICES="$2"; shift 2 ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Initialization ---
print_header "FinFlow Unified Build"
print_info "Starting build process for services: $SERVICES"

# Create necessary directories
mkdir -p "$LOG_DIR"

# Initialize log file
echo "=== FinFlow Build Log $(date) ===" > "$LOG_DIR/build.log"
log_message "INFO" "Starting build process for services: $SERVICES"

# --- Build Services ---
build_services() {
  local build_status=0
  
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
      print_warning "No 'build' script found in package.json for $service, skipping build step"
      log_message "WARNING" "No 'build' script found in package.json for $service, skipping build step"
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
    
    # Run build script
    if grep -q '"build"' "$service_dir/package.json"; then
      print_info "Running build script for $service..."
      (cd "$service_dir" && npm run build) || {
        print_error "Build failed for $service"
        log_message "ERROR" "Build failed for $service"
        build_status=1
        continue
      }
    else
      print_warning "No 'build' script found in package.json for $service, skipping build step"
      log_message "WARNING" "No 'build' script found in package.json for $service, skipping build step"
    fi
  done
  
  return $build_status
}

build_services
build_status=$?

# --- Summary ---
print_header "Build Summary"

if [ $build_status -eq 0 ]; then
  print_success "All requested services built successfully!"
  log_message "INFO" "All requested services built successfully"
else
  print_error "One or more service builds failed. Check logs for details."
  log_message "ERROR" "One or more service builds failed"
fi

exit $build_status
