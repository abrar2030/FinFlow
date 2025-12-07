#!/bin/bash\nset -euo pipefail
# FinFlow Code Quality Automation
# This script automates code quality checks, linting, and formatting
# Version: 1.0.0

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
LOG_DIR="$PROJECT_ROOT/logs"
REPORT_DIR="$PROJECT_ROOT/quality-reports"

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
  echo "[$timestamp] [$level] $message" >> "$LOG_DIR/quality.log"
}

# --- Command Line Arguments ---
VERBOSE=false
MODE="check"
SERVICES="all"
INSTALL_HOOKS=false
REPORT=false
VULNERABILITY_SCAN=false

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -m, --mode MODE            Mode (check, fix)"
  echo "  -s, --services SERVICES    Comma-separated list of services to check (default: all)"
  echo "  --install-hooks            Install Git pre-commit hooks"
  echo "  --report                   Generate HTML quality reports"
  echo "  --vulnerability-scan       Run dependency vulnerability scan"
  echo
  echo "Examples:"
  echo "  $0 --mode fix"
  echo "  $0 --services auth-service,payments-service"
  echo "  $0 --install-hooks --report"
  exit 0
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -m|--mode) MODE="$2"; shift 2 ;;
    -s|--services) SERVICES="$2"; shift 2 ;;
    --install-hooks) INSTALL_HOOKS=true; shift ;;
    --report) REPORT=true; shift ;;
    --vulnerability-scan) VULNERABILITY_SCAN=true; shift ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Initialization ---
print_header "FinFlow Code Quality Automation"
print_info "Starting code quality checks in $MODE mode"

# Create necessary directories
mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$REPORT_DIR"

# Initialize log file
echo "=== FinFlow Code Quality Log $(date) ===" > "$LOG_DIR/quality.log"
log_message "INFO" "Starting code quality checks in $MODE mode"

# --- Generate Configuration Files ---
print_header "Generating Configuration Files"

generate_config_files() {
  print_info "Generating configuration files..."
  log_message "INFO" "Generating configuration files"
  
  # ESLint config for TypeScript/Node.js
  cat > "$CONFIG_DIR/.eslintrc.js" << EOL
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
  cat > "$CONFIG_DIR/.prettierrc" << EOL
{
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "semi": true
}
EOL

  # ESLint config for React/Frontend
  cat > "$CONFIG_DIR/.eslintrc.react.js" << EOL
module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
  extends: [
    'plugin:react/recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:prettier/recommended',
  ],
  rules: {
    'react/prop-types': 'off',
    'react/react-in-jsx-scope': 'off',
    '@typescript-eslint/no-unused-vars': ['warn', { 'argsIgnorePattern': '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',
  },
};
EOL

  # Stylelint config
  cat > "$CONFIG_DIR/.stylelintrc.json" << EOL
{
  "extends": [
    "stylelint-config-standard",
    "stylelint-config-prettier"
  ],
  "rules": {
    "indentation": 2,
    "string-quotes": "single",
    "no-duplicate-selectors": true,
    "color-hex-case": "lower",
    "color-hex-length": "short",
    "selector-combinator-space-after": "always",
    "selector-attribute-quotes": "always",
    "declaration-block-trailing-semicolon": "always",
    "declaration-colon-space-before": "never",
    "declaration-colon-space-after": "always",
    "property-no-vendor-prefix": true,
    "value-no-vendor-prefix": true,
    "selector-no-vendor-prefix": true,
    "media-feature-name-no-vendor-prefix": true
  }
}
EOL

  # Git pre-commit hook
  mkdir -p "$CONFIG_DIR/git-hooks"
  cat > "$CONFIG_DIR/git-hooks/pre-commit" << EOL
#!/bin/bash\nset -euo pipefail
# FinFlow pre-commit hook
# Generated by finflow-quality.sh

# Get the list of staged files
STAGED_FILES=\$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.(js|jsx|ts|tsx)$')

if [[ "\$STAGED_FILES" = "" ]]; then
  exit 0
fi

echo "Running pre-commit checks on staged files..."

# Run ESLint on staged files
for FILE in \$STAGED_FILES; do
  if [[ "\$FILE" =~ \.tsx?$ ]]; then
    npx eslint --fix "\$FILE"
    if [ \$? -ne 0 ]; then
      echo "ESLint failed on \$FILE. Please fix the issues before committing."
      exit 1
    fi
  fi
done

# Run Prettier on staged files
for FILE in \$STAGED_FILES; do
  npx prettier --write "\$FILE"
  if [ \$? -ne 0 ]; then
    echo "Prettier failed on \$FILE. Please fix the issues before committing."
    exit 1
  fi
done

# Add back the modified files to staging
git add \$STAGED_FILES

exit 0
EOL

  chmod +x "$CONFIG_DIR/git-hooks/pre-commit"
  
  print_success "Configuration files generated"
  log_message "INFO" "Configuration files generated"
}

generate_config_files

# --- Install Git Hooks ---
if [ "$INSTALL_HOOKS" = true ]; then
  print_header "Installing Git Hooks"
  
  print_info "Installing pre-commit hook..."
  log_message "INFO" "Installing pre-commit hook"
  
  # Check if .git directory exists
  if [ -d "$PROJECT_ROOT/.git" ]; then
    # Create hooks directory if it doesn't exist
    mkdir -p "$PROJECT_ROOT/.git/hooks"
    
    # Copy pre-commit hook
    cp "$CONFIG_DIR/git-hooks/pre-commit" "$PROJECT_ROOT/.git/hooks/"
    chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
    
    print_success "Git pre-commit hook installed"
    log_message "INFO" "Git pre-commit hook installed"
  else
    print_warning "No .git directory found, skipping hook installation"
    log_message "WARNING" "No .git directory found, skipping hook installation"
  fi
fi

# --- Run Code Quality Checks ---
print_header "Running Code Quality Checks"

run_code_quality_checks() {
  local quality_status=0
  
  # Determine which services to check
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
  
  # Run backend service checks
  for service in "${backend_services[@]}"; do
    local service_dir="$PROJECT_ROOT/backend/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Service directory $service not found, skipping"
      log_message "WARNING" "Service directory $service not found, skipping"
      continue
    fi
    
    print_info "Checking $service..."
    log_message "INFO" "Checking $service"
    
    # Copy config files if they don't exist
    if [ ! -f "$service_dir/.eslintrc.js" ]; then
      cp "$CONFIG_DIR/.eslintrc.js" "$service_dir/"
    fi
    
    if [ ! -f "$service_dir/.prettierrc" ]; then
      cp "$CONFIG_DIR/.prettierrc" "$service_dir/"
    fi
    
    # Install dependencies if needed
    if [ ! -d "$service_dir/node_modules" ]; then
      print_info "Installing dependencies for $service..."
      (cd "$service_dir" && npm install) || {
        print_error "Failed to install dependencies for $service"
        log_message "ERROR" "Failed to install dependencies for $service"
        quality_status=1
        continue
      }
    fi
    
    # Run ESLint
    print_info "Running ESLint for $service..."
    if [ "$MODE" = "fix" ]; then
      (cd "$service_dir" && npx eslint --fix 'src/**/*.{js,ts}') || {
        print_error "ESLint failed for $service"
        log_message "ERROR" "ESLint failed for $service"
        quality_status=1
      }
    else
      (cd "$service_dir" && npx eslint 'src/**/*.{js,ts}') || {
        print_error "ESLint failed for $service"
        log_message "ERROR" "ESLint failed for $service"
        quality_status=1
      }
    fi
    
    # Run Prettier
    print_info "Running Prettier for $service..."
    if [ "$MODE" = "fix" ]; then
      (cd "$service_dir" && npx prettier --write 'src/**/*.{js,ts,json}') || {
        print_error "Prettier failed for $service"
        log_message "ERROR" "Prettier failed for $service"
        quality_status=1
      }
    else
      (cd "$service_dir" && npx prettier --check 'src/**/*.{js,ts,json}') || {
        print_error "Prettier failed for $service"
        log_message "ERROR" "Prettier failed for $service"
        quality_status=1
      }
    fi
    
    # Run TypeScript compiler checks
    print_info "Running TypeScript compiler checks for $service..."
    (cd "$service_dir" && npx tsc --noEmit) || {
      print_error "TypeScript compiler checks failed for $service"
      log_message "ERROR" "TypeScript compiler checks failed for $service"
      quality_status=1
    }
    
    # Run vulnerability scan if requested
    if [ "$VULNERABILITY_SCAN" = true ]; then
      print_info "Running vulnerability scan for $service..."
      (cd "$service_dir" && npm audit --json > "$REPORT_DIR/$service-vulnerabilities.json") || {
        print_warning "Vulnerabilities found in $service"
        log_message "WARNING" "Vulnerabilities found in $service"
      }
    fi
    
    # Generate report if requested
    if [ "$REPORT" = true ]; then
      print_info "Generating code quality report for $service..."
      mkdir -p "$REPORT_DIR/$service"
      
      # Run ESLint with HTML reporter
      (cd "$service_dir" && npx eslint -f html 'src/**/*.{js,ts}' > "$REPORT_DIR/$service/eslint-report.html") || {
        print_warning "Failed to generate ESLint HTML report for $service"
        log_message "WARNING" "Failed to generate ESLint HTML report for $service"
      }
      
      print_success "Code quality report generated for $service"
      log_message "INFO" "Code quality report generated for $service"
    fi
  done
  
  # Run frontend service checks
  for service in "${frontend_services[@]}"; do
    local service_dir="$PROJECT_ROOT/$service"
    
    if [ ! -d "$service_dir" ]; then
      print_warning "Frontend directory $service not found, skipping"
      log_message "WARNING" "Frontend directory $service not found, skipping"
      continue
    fi
    
    print_info "Checking $service..."
    log_message "INFO" "Checking $service"
    
    # Copy config files if they don't exist
    if [ ! -f "$service_dir/.eslintrc.js" ]; then
      cp "$CONFIG_DIR/.eslintrc.react.js" "$service_dir/.eslintrc.js"
    fi
    
    if [ ! -f "$service_dir/.prettierrc" ]; then
      cp "$CONFIG_DIR/.prettierrc" "$service_dir/"
    fi
    
    if [ ! -f "$service_dir/.stylelintrc.json" ]; then
      cp "$CONFIG_DIR/.stylelintrc.json" "$service_dir/"
    fi
    
    # Install dependencies if needed
    if [ ! -d "$service_dir/node_modules" ]; then
      print_info "Installing dependencies for $service..."
      (cd "$service_dir" && npm install) || {
        print_error "Failed to install dependencies for $service"
        log_message "ERROR" "Failed to install dependencies for $service"
        quality_status=1
        continue
      }
    fi
    
    # Run ESLint
    print_info "Running ESLint for $service..."
    if [ "$MODE" = "fix" ]; then
      (cd "$service_dir" && npx eslint --fix 'src/**/*.{js,jsx,ts,tsx}') || {
        print_error "ESLint failed for $service"
        log_message "ERROR" "ESLint failed for $service"
        quality_status=1
      }
    else
      (cd "$service_dir" && npx eslint 'src/**/*.{js,jsx,ts,tsx}') || {
        print_error "ESLint failed for $service"
        log_message "ERROR" "ESLint failed for $service"
        quality_status=1
      }
    fi
    
    # Run Prettier
    print_info "Running Prettier for $service..."
    if [ "$MODE" = "fix" ]; then
      (cd "$service_dir" && npx prettier --write 'src/**/*.{js,jsx,ts,tsx,json,css,scss,md}') || {
        print_error "Prettier failed for $service"
        log_message "ERROR" "Prettier failed for $service"
        quality_status=1
      }
    else
      (cd "$service_dir" && npx prettier --check 'src/**/*.{js,jsx,ts,tsx,json,css,scss,md}') || {
        print_error "Prettier failed for $service"
        log_message "ERROR" "Prettier failed for $service"
        quality_status=1
      }
    fi
    
    # Run Stylelint if available
    if grep -q "stylelint" "$service_dir/package.json" 2>/dev/null; then
      print_info "Running Stylelint for $service..."
      if [ "$MODE" = "fix" ]; then
        (cd "$service_dir" && npx stylelint --fix 'src/**/*.{css,scss}') || {
          print_error "Stylelint failed for $service"
          log_message "ERROR" "Stylelint failed for $service"
          quality_status=1
        }
      else
        (cd "$service_dir" && npx stylelint 'src/**/*.{css,scss}') || {
          print_error "Stylelint failed for $service"
          log_message "ERROR" "Stylelint failed for $service"
          quality_status=1
        }
      fi
    fi
    
    # Run TypeScript compiler checks
    print_info "Running TypeScript compiler checks for $service..."
    (cd "$service_dir" && npx tsc --noEmit) || {
      print_error "TypeScript compiler checks failed for $service"
      log_message "ERROR" "TypeScript compiler checks failed for $service"
      quality_status=1
    }
    
    # Run vulnerability scan if requested
    if [ "$VULNERABILITY_SCAN" = true ]; then
      print_info "Running vulnerability scan for $service..."
      (cd "$service_dir" && npm audit --json > "$REPORT_DIR/$service-vulnerabilities.json") || {
        print_warning "Vulnerabilities found in $service"
        log_message "WARNING" "Vulnerabilities found in $service"
      }
    fi
    
    # Generate report if requested
    if [ "$REPORT" = true ]; then
      print_info "Generating code quality report for $service..."
      mkdir -p "$REPORT_DIR/$service"
      
      # Run ESLint with HTML reporter
      (cd "$service_dir" && npx eslint -f html 'src/**/*.{js,jsx,ts,tsx}' > "$REPORT_DIR/$service/eslint-report.html") || {
        print_warning "Failed to generate ESLint HTML report for $service"
        log_message "WARNING" "Failed to generate ESLint HTML report for $service"
      }
      
      print_success "Code quality report generated for $service"
      log_message "INFO" "Code quality report generated for $service"
    fi
  done
  
  return $quality_status
}

run_code_quality_checks
quality_status=$?

# --- Generate Combined Report ---
if [ "$REPORT" = true ]; then
  print_header "Generating Combined Report"
  
  print_info "Generating combined code quality report..."
  log_message "INFO" "Generating combined code quality report"
  
  # Create combined report
  local report_file="$REPORT_DIR/combined-quality-report.html"
  
  # Create report header
  cat > "$report_file" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FinFlow Code Quality Report</title>
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
    <h1>FinFlow Code Quality Report</h1>
    <div class="summary">
      <h2>Quality Summary</h2>
      <p>Generated on: $(date)</p>
      <p>Mode: ${MODE}</p>
      <p>Services Checked: ${SERVICES}</p>
      <p>Overall Status: $([ $quality_status -eq 0 ] && echo '<span class="success">PASSED</span>' || echo '<span class="failure">FAILED</span>')</p>
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
    
    # Check if service has ESLint report
    if [ -f "$REPORT_DIR/$service/eslint-report.html" ]; then
      cat >> "$report_file" << EOL
      <h3>ESLint Results</h3>
      <p>Detailed ESLint report available at: <a href="${service}/eslint-report.html">ESLint Report</a></p>
EOL
    fi
    
    # Check if service has vulnerability report
    if [ -f "$REPORT_DIR/$service-vulnerabilities.json" ]; then
      cat >> "$report_file" << EOL
      <h3>Vulnerability Scan</h3>
      <p>Vulnerability report available at: <a href="${service}-vulnerabilities.json">Vulnerability Report</a></p>
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
  
  print_success "Combined code quality report generated at: $report_file"
  log_message "INFO" "Combined code quality report generated at: $report_file"
fi

# --- Summary ---
print_header "Code Quality Summary"

if [ $quality_status -eq 0 ]; then
  print_success "All code quality checks passed successfully!"
  log_message "INFO" "All code quality checks passed successfully"
else
  print_error "Some code quality checks failed. Check the reports for details."
  log_message "ERROR" "Some code quality checks failed"
fi

if [ "$REPORT" = true ]; then
  print_info "Code quality reports available at: $REPORT_DIR"
  print_info "Combined report: $REPORT_DIR/combined-quality-report.html"
fi

if [ "$INSTALL_HOOKS" = true ]; then
  print_info "Git pre-commit hook installed at: $PROJECT_ROOT/.git/hooks/pre-commit"
fi

exit $quality_status
