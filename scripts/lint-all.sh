#!/bin/bash

set -euo pipefail

# FinFlow Project - Comprehensive Code Quality Script
# Version 1.0 - Complete Linting and Formatting Solution

# --- Configuration ---
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/web-frontend"
CONFIG_DIR="$PROJECT_ROOT/config"
NODE_VERSION="16"

# Create necessary directories
mkdir -p "$CONFIG_DIR"

# --- Colors & Helpers ---
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"

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
  echo -e "${COLOR_YELLOW}[INFO] $1${COLOR_RESET}"
}

# --- Initialization ---
MODE="check"
OVERALL_STATUS=0
BACKEND_STATUS=0
FRONTEND_STATUS=0

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --fix) MODE="fix"; shift ;;
    -h|--help)
      echo "Usage: $0 [--fix]"
      echo "  --fix Apply automatic fixes"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

print_info "Running in ${MODE^^} mode"

# --- Prerequisite Checks ---
print_header "System Prerequisite Checks"

check_node() {
  if ! command -v node &>/dev/null; then
    print_error "Node.js not found. Install from: https://nodejs.org"
    return 1
  fi
  
  local node_version=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
  if [[ $node_version -lt $NODE_VERSION ]]; then
    print_error "Node.js version $NODE_VERSION+ required. Found: v$node_version"
    return 1
  fi
  
  return 0
}

check_npm() {
  if ! command -v npm &>/dev/null; then
    print_error "npm not found. Install Node.js from: https://nodejs.org"
    return 1
  fi
  return 0
}

check_node || OVERALL_STATUS=1
check_npm || OVERALL_STATUS=1

if [ $OVERALL_STATUS -ne 0 ]; then
  print_error "Critical prerequisites missing. Aborting."
  exit 1
fi

# --- Generate Configuration Files ---
print_header "Generating Configuration Files"

# ESLint config for TypeScript/Node.js
cat > "$CONFIG_DIR/.eslintrc.js" <<EOL
module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: 'tsconfig.json',
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint/eslint-plugin'],
  extends: [
    'plugin:@typescript-eslint/recommended',
    'plugin:prettier/recommended',
  ],
  root: true,
  env: {
    node: true,
    jest: true,
  },
  ignorePatterns: ['.eslintrc.js'],
  rules: {
    '@typescript-eslint/interface-name-prefix': 'off',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-unused-vars': ['warn', { 'argsIgnorePattern': '^_' }],
  },
};
EOL

# Prettier config
cat > "$CONFIG_DIR/.prettierrc" <<EOL
{
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "semi": true
}
EOL

print_success "Configuration files generated"

# --- Backend Services Linting ---
print_header "Backend Services Linting"

run_backend_linting() {
  local status=0
  local services=("auth-service" "payments-service" "accounting-service" "analytics-service" "credit-engine")
  
  for service in "${services[@]}"; do
    local service_dir="$BACKEND_DIR/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Service directory $service not found, skipping"
      continue
    fi
    
    print_info "Linting $service..."
    cd "$service_dir" || continue
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
      print_info "Installing dependencies for $service..."
      npm install || {
        print_error "Failed to install dependencies for $service"
        status=1
        continue
      }
    fi
    
    # Copy config files if they don't exist
    if [ ! -f ".eslintrc.js" ]; then
      cp "$CONFIG_DIR/.eslintrc.js" .
    fi
    
    if [ ! -f ".prettierrc" ]; then
      cp "$CONFIG_DIR/.prettierrc" .
    fi
    
    # Run ESLint
    if [ "$MODE" == "fix" ]; then
      print_info "Running ESLint with auto-fix for $service..."
      npx eslint --fix 'src/**/*.{js,ts}' || status=1
    else
      print_info "Running ESLint for $service..."
      npx eslint 'src/**/*.{js,ts}' || status=1
    fi
    
    # Run Prettier
    if [ "$MODE" == "fix" ]; then
      print_info "Running Prettier with auto-fix for $service..."
      npx prettier --write 'src/**/*.{js,ts,json}' || status=1
    else
      print_info "Running Prettier check for $service..."
      npx prettier --check 'src/**/*.{js,ts,json}' || status=1
    fi
    
    # Check for TypeScript errors
    print_info "Running TypeScript compiler checks for $service..."
    npx tsc --noEmit || status=1
    
    if [ $status -eq 0 ]; then
      print_success "$service linting completed successfully"
    else
      print_error "$service has linting issues"
    fi
  done
  
  return $status
}

if [ -d "$BACKEND_DIR" ]; then
  run_backend_linting || BACKEND_STATUS=1
else
  print_warning "Backend directory not found"
  BACKEND_STATUS=2
fi

[ $BACKEND_STATUS -ne 0 ] && OVERALL_STATUS=1

# --- Frontend Linting ---
print_header "Frontend Linting"

run_frontend_linting() {
  local status=0
  
  if [ ! -d "$FRONTEND_DIR" ]; then
    print_warning "Frontend directory not found"
    return 2
  fi
  
  cd "$FRONTEND_DIR" || return 1
  
  # Install dependencies if needed
  if [ ! -d "node_modules" ]; then
    print_info "Installing dependencies for frontend..."
    npm install || {
      print_error "Failed to install dependencies for frontend"
      return 1
    }
  fi
  
  # Run ESLint
  if [ "$MODE" == "fix" ]; then
    print_info "Running ESLint with auto-fix for frontend..."
    npx eslint --fix 'src/**/*.{js,jsx,ts,tsx}' || status=1
  else
    print_info "Running ESLint for frontend..."
    npx eslint 'src/**/*.{js,jsx,ts,tsx}' || status=1
  fi
  
  # Run Prettier
  if [ "$MODE" == "fix" ]; then
    print_info "Running Prettier with auto-fix for frontend..."
    npx prettier --write 'src/**/*.{js,jsx,ts,tsx,json,css,scss,md}' || status=1
  else
    print_info "Running Prettier check for frontend..."
    npx prettier --check 'src/**/*.{js,jsx,ts,tsx,json,css,scss,md}' || status=1
  fi
  
  # Check for TypeScript errors
  print_info "Running TypeScript compiler checks for frontend..."
  npx tsc --noEmit || status=1
  
  # Run stylelint if available
  if grep -q "stylelint" package.json; then
    if [ "$MODE" == "fix" ]; then
      print_info "Running stylelint with auto-fix for frontend..."
      npx stylelint --fix 'src/**/*.{css,scss}' || status=1
    else
      print_info "Running stylelint for frontend..."
      npx stylelint 'src/**/*.{css,scss}' || status=1
    fi
  fi
  
  if [ $status -eq 0 ]; then
    print_success "Frontend linting completed successfully"
  else
    print_error "Frontend has linting issues"
  fi
  
  return $status
}

if [ -d "$FRONTEND_DIR" ]; then
  run_frontend_linting || FRONTEND_STATUS=1
else
  print_warning "Frontend directory not found"
  FRONTEND_STATUS=2
fi

[ $FRONTEND_STATUS -ne 0 ] && OVERALL_STATUS=1

# --- Infrastructure Linting ---
print_header "Infrastructure Linting"

# Check for Docker Compose files
if [ -f "docker-compose.yml" ]; then
  print_info "Validating docker-compose.yml..."
  docker-compose config -q || OVERALL_STATUS=1
fi

# Check for Kubernetes manifests
if [ -d "kubernetes" ]; then
  print_info "Checking for kubeval..."
  if command -v kubeval &>/dev/null; then
    print_info "Validating Kubernetes manifests..."
    kubeval kubernetes/*.yaml || OVERALL_STATUS=1
  else
    print_warning "kubeval not found. Skipping Kubernetes manifest validation."
  fi
fi

# --- Final Report ---
print_header "Validation Summary"

report_status() {
  case $1 in
    0) echo -e "${COLOR_GREEN}PASS${COLOR_RESET}" ;;
    1) echo -e "${COLOR_RED}FAIL${COLOR_RESET}" ;;
    2) echo -e "${COLOR_YELLOW}SKIP${COLOR_RESET}" ;;
    *) echo -e "${COLOR_RED}UNKNOWN${COLOR_RESET}" ;;
  esac
}

echo -e "Backend Services: $(report_status $BACKEND_STATUS)"
echo -e "Frontend: $(report_status $FRONTEND_STATUS)"

if [ $OVERALL_STATUS -eq 0 ]; then
  print_success "All checks passed successfully!"
else
  print_error "Some checks failed. Please fix the issues and try again."
fi

exit $OVERALL_STATUS
