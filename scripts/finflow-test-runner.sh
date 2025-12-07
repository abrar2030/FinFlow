#!/bin/bash

set -euo pipefail

# FinFlow Unified Test Runner
# This script automates running all types of tests across services
# Version: 1.0.0

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_ROOT/test-reports"
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
  echo "[$timestamp] [$level] $message" >> "$LOG_DIR/tests.log"
}

# --- Command Line Arguments ---
VERBOSE=false
TEST_TYPE="all"
SERVICES="all"
REPORT_FORMAT="html"
WATCH_MODE=false
COVERAGE=false

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -t, --type TYPE            Test type to run (unit, integration, e2e, all)"
  echo "  -s, --services SERVICES    Comma-separated list of services to test (default: all)"
  echo "  -r, --report FORMAT        Report format (html, json, junit)"
  echo "  -w, --watch                Run tests in watch mode"
  echo "  -c, --coverage             Generate test coverage reports"
  echo
  echo "Examples:"
  echo "  $0 --type unit"
  echo "  $0 --services auth-service,payments-service"
  echo "  $0 --coverage --report html"
  exit 0
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -t|--type) TEST_TYPE="$2"; shift 2 ;;
    -s|--services) SERVICES="$2"; shift 2 ;;
    -r|--report) REPORT_FORMAT="$2"; shift 2 ;;
    -w|--watch) WATCH_MODE=true; shift ;;
    -c|--coverage) COVERAGE=true; shift ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Initialization ---
print_header "FinFlow Test Runner"
print_info "Starting test runner for type: $TEST_TYPE"

# Create necessary directories
mkdir -p "$REPORT_DIR" "$LOG_DIR"

# Initialize log file
echo "=== FinFlow Test Log $(date) ===" > "$LOG_DIR/tests.log"
log_message "INFO" "Starting tests of type: $TEST_TYPE"

# --- Validate Test Environment ---
print_header "Validating Test Environment"

check_test_environment() {
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
  
  # Check if Jest is available
  if ! npm list -g jest &> /dev/null; then
    print_warning "Jest is not installed globally. Will use local installations."
    log_message "WARNING" "Jest is not installed globally. Will use local installations."
  fi
  
  # Check if Docker is running (for integration tests)
  if [[ "$TEST_TYPE" == "integration" || "$TEST_TYPE" == "all" ]]; then
    if ! docker info &> /dev/null; then
      print_warning "Docker is not running. Integration tests may fail."
      log_message "WARNING" "Docker is not running. Integration tests may fail."
    fi
  fi
  
  print_success "Test environment validation completed"
  log_message "INFO" "Test environment validation completed"
}

check_test_environment

# --- Run Tests ---
print_header "Running Tests"

run_tests() {
  local test_status=0
  
  # Determine which services to test
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
  
  # Run backend service tests
  for service in "${backend_services[@]}"; do
    local service_dir="$PROJECT_ROOT/backend/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Service directory $service not found, skipping"
      log_message "WARNING" "Service directory $service not found, skipping"
      continue
    fi
    
    print_info "Running tests for $service..."
    log_message "INFO" "Running tests for $service"
    
    # Determine test command based on test type
    local test_cmd="npm test"
    local test_args=""
    
    if [ "$VERBOSE" = true ]; then
      test_args="$test_args --verbose"
    fi
    
    if [ "$WATCH_MODE" = true ]; then
      test_args="$test_args --watch"
    fi
    
    if [ "$COVERAGE" = true ]; then
      test_args="$test_args --coverage"
    fi
    
    case "$TEST_TYPE" in
      unit)
        test_cmd="npm run test:unit"
        ;;
      integration)
        test_cmd="npm run test:integration"
        ;;
      e2e)
        test_cmd="npm run test:e2e"
        ;;
      all)
        test_cmd="npm test"
        ;;
      *)
        print_error "Unknown test type: $TEST_TYPE"
        log_message "ERROR" "Unknown test type: $TEST_TYPE"
        return 1
        ;;
    esac
    
    # Add report format if specified
    if [ "$REPORT_FORMAT" != "html" ]; then
      test_args="$test_args --reporters=jest-$REPORT_FORMAT-reporter"
    fi
    
    # Create service-specific report directory
    mkdir -p "$REPORT_DIR/$service"
    
    # Run the tests
    (cd "$service_dir" && $test_cmd $test_args --outputFile="$REPORT_DIR/$service/results.$REPORT_FORMAT") || {
      print_error "Tests failed for $service"
      log_message "ERROR" "Tests failed for $service"
      test_status=1
    }
    
    # Check for coverage reports and copy them
    if [ "$COVERAGE" = true ] && [ -d "$service_dir/coverage" ]; then
      cp -r "$service_dir/coverage" "$REPORT_DIR/$service/"
      print_success "Copied coverage reports for $service"
      log_message "INFO" "Copied coverage reports for $service"
    fi
  done
  
  # Run frontend tests
  for service in "${frontend_services[@]}"; do
    local service_dir="$PROJECT_ROOT/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Frontend directory $service not found, skipping"
      log_message "WARNING" "Frontend directory $service not found, skipping"
      continue
    fi
    
    print_info "Running tests for $service..."
    log_message "INFO" "Running tests for $service"
    
    # Determine test command based on test type
    local test_cmd="npm test"
    local test_args="-- --passWithNoTests"
    
    if [ "$VERBOSE" = true ]; then
      test_args="$test_args --verbose"
    fi
    
    if [ "$WATCH_MODE" = true ]; then
      test_args="$test_args --watch"
    else
      test_args="$test_args --watchAll=false"
    fi
    
    if [ "$COVERAGE" = true ]; then
      test_args="$test_args --coverage"
    fi
    
    case "$TEST_TYPE" in
      unit)
        test_cmd="npm test"
        ;;
      e2e)
        if [ -f "$service_dir/package.json" ] && grep -q "test:e2e" "$service_dir/package.json"; then
          test_cmd="npm run test:e2e"
        else
          print_warning "E2E tests not configured for $service, skipping"
          log_message "WARNING" "E2E tests not configured for $service, skipping"
          continue
        fi
        ;;
      all)
        test_cmd="npm test"
        ;;
      integration)
        print_warning "Integration tests not typically applicable for frontend, running unit tests instead"
        log_message "WARNING" "Integration tests not typically applicable for frontend, running unit tests instead"
        test_cmd="npm test"
        ;;
      *)
        print_error "Unknown test type: $TEST_TYPE"
        log_message "ERROR" "Unknown test type: $TEST_TYPE"
        return 1
        ;;
    esac
    
    # Create service-specific report directory
    mkdir -p "$REPORT_DIR/$service"
    
    # Run the tests
    (cd "$service_dir" && $test_cmd $test_args) || {
      print_error "Tests failed for $service"
      log_message "ERROR" "Tests failed for $service"
      test_status=1
    }
    
    # Check for coverage reports and copy them
    if [ "$COVERAGE" = true ] && [ -d "$service_dir/coverage" ]; then
      cp -r "$service_dir/coverage" "$REPORT_DIR/$service/"
      print_success "Copied coverage reports for $service"
      log_message "INFO" "Copied coverage reports for $service"
    fi
  done
  
  # Run E2E tests if specified
  if [[ "$TEST_TYPE" == "e2e" || "$TEST_TYPE" == "all" ]] && [ -d "$PROJECT_ROOT/e2e" ]; then
    print_info "Running project-wide E2E tests..."
    log_message "INFO" "Running project-wide E2E tests"
    
    # Check if there's a package.json in the e2e directory
    if [ -f "$PROJECT_ROOT/e2e/package.json" ]; then
      # Install dependencies if needed
      if [ ! -d "$PROJECT_ROOT/e2e/node_modules" ]; then
        print_info "Installing E2E test dependencies..."
        (cd "$PROJECT_ROOT/e2e" && npm install) || {
          print_error "Failed to install E2E test dependencies"
          log_message "ERROR" "Failed to install E2E test dependencies"
          test_status=1
        }
      fi
      
      # Run the tests
      (cd "$PROJECT_ROOT/e2e" && npm test) || {
        print_error "E2E tests failed"
        log_message "ERROR" "E2E tests failed"
        test_status=1
      }
    else
      # If no package.json, try to run the tests directly
      print_info "No package.json found in e2e directory, running tests directly..."
      
      # Check if there are TypeScript files
      if ls "$PROJECT_ROOT/e2e"/*.spec.ts &> /dev/null; then
        # Run with ts-node
        if command -v npx &> /dev/null; then
          (cd "$PROJECT_ROOT" && npx jest e2e/) || {
            print_error "E2E tests failed"
            log_message "ERROR" "E2E tests failed"
            test_status=1
          }
        else
          print_error "npx not found, cannot run E2E tests directly"
          log_message "ERROR" "npx not found, cannot run E2E tests directly"
          test_status=1
        fi
      else
        print_warning "No test files found in e2e directory"
        log_message "WARNING" "No test files found in e2e directory"
      fi
    fi
  fi
  
  return $test_status
}

run_tests
test_status=$?

# --- Generate Combined Report ---
print_header "Generating Test Report"

generate_combined_report() {
  local report_file="$REPORT_DIR/combined-report.html"
  
  print_info "Generating combined test report..."
  log_message "INFO" "Generating combined test report"
  
  # Create report header
  cat > "$report_file" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FinFlow Test Report</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      margin: 0;
      padding: 20px;
      color: #333;
    }
    h1, h2, h3 {
      color: #0066cc;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    .summary {
      background-color: #f5f5f5;
      padding: 15px;
      border-radius: 5px;
      margin-bottom: 20px;
    }
    .service {
      margin-bottom: 30px;
      border: 1px solid #ddd;
      border-radius: 5px;
      padding: 15px;
    }
    .success {
      color: #2ecc71;
    }
    .failure {
      color: #e74c3c;
    }
    .warning {
      color: #f39c12;
    }
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th, td {
      padding: 8px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    th {
      background-color: #f2f2f2;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>FinFlow Test Report</h1>
    <div class="summary">
      <h2>Test Summary</h2>
      <p>Generated on: $(date)</p>
      <p>Test Type: ${TEST_TYPE}</p>
      <p>Services Tested: ${SERVICES}</p>
      <p>Overall Status: $([ $test_status -eq 0 ] && echo '<span class="success">PASSED</span>' || echo '<span class="failure">FAILED</span>')</p>
    </div>
EOL
  
  # Add service-specific results
  if [ "$SERVICES" = "all" ]; then
    local all_services=("auth-service" "payments-service" "accounting-service" "analytics-service" "credit-engine" "web-frontend" "mobile-frontend")
  else
    IFS=',' read -ra all_services <<< "$SERVICES"
  fi
  
  for service in "${all_services[@]}"; do
    local service_dir=""
    if [[ "$service" == *"frontend"* ]]; then
      service_dir="$PROJECT_ROOT/$service"
    else
      service_dir="$PROJECT_ROOT/backend/$service"
    fi
    
    if [ ! -d "$service_dir" ]; then
      continue
    fi
    
    cat >> "$report_file" << EOL
    <div class="service">
      <h2>${service}</h2>
EOL
    
    # Check if service has test results
    if [ -d "$REPORT_DIR/$service" ]; then
      # Add coverage information if available
      if [ -f "$REPORT_DIR/$service/coverage/lcov-report/index.html" ]; then
        # Extract coverage percentage
        local coverage_file="$REPORT_DIR/$service/coverage/lcov-report/index.html"
        local coverage_pct=$(grep -o '[0-9.]\+%' "$coverage_file" | head -1)
        
        cat >> "$report_file" << EOL
      <h3>Coverage: ${coverage_pct}</h3>
      <p>Detailed coverage report available at: <a href="${service}/coverage/lcov-report/index.html">Coverage Report</a></p>
EOL
      fi
      
      # Add test results if available
      if [ -f "$REPORT_DIR/$service/results.$REPORT_FORMAT" ]; then
        cat >> "$report_file" << EOL
      <h3>Test Results</h3>
      <p>Detailed test results available at: <a href="${service}/results.${REPORT_FORMAT}">Test Results</a></p>
EOL
      fi
    else
      cat >> "$report_file" << EOL
      <p class="warning">No test results available for this service</p>
EOL
    fi
    
    cat >> "$report_file" << EOL
    </div>
EOL
  done
  
  # Close the HTML document
  cat >> "$report_file" << EOL
  </div>
</body>
</html>
EOL
  
  print_success "Combined test report generated at: $report_file"
  log_message "INFO" "Combined test report generated at: $report_file"
}

if [ "$REPORT_FORMAT" = "html" ]; then
  generate_combined_report
fi

# --- Summary ---
print_header "Test Summary"

if [ $test_status -eq 0 ]; then
  print_success "All tests passed successfully!"
  log_message "INFO" "All tests passed successfully"
else
  print_error "Some tests failed. Check the reports for details."
  log_message "ERROR" "Some tests failed"
fi

print_info "Test reports available at: $REPORT_DIR"
if [ "$REPORT_FORMAT" = "html" ]; then
  print_info "Combined report: $REPORT_DIR/combined-report.html"
fi

exit $test_status
