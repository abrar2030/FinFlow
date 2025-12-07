#!/bin/bash\nset -euo pipefail
# FinFlow Documentation Generation Automation
# This script automates the generation of API documentation, changelogs, and other docs
# Version: 1.0.0

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
LOG_DIR="$PROJECT_ROOT/logs"
DOCS_DIR="$PROJECT_ROOT/docs"

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
  echo "[$timestamp] [$level] $message" >> "$LOG_DIR/docs.log"
}

# --- Command Line Arguments ---
VERBOSE=false
ACTION="generate"
SERVICES="all"
API_DOCS=true
CHANGELOG=true
README_UPDATE=false

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -a, --action ACTION        Action to perform (generate, clean)"
  echo "  -s, --services SERVICES    Comma-separated list of services to document (default: all)"
  echo "  --no-api-docs              Skip API documentation generation"
  echo "  --no-changelog             Skip changelog generation"
  echo "  --update-readme            Update README based on codebase changes"
  echo
  echo "Examples:"
  echo "  $0 --action generate"
  echo "  $0 --services auth-service,payments-service"
  echo "  $0 --no-changelog"
  exit 0
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -a|--action) ACTION="$2"; shift 2 ;;
    -s|--services) SERVICES="$2"; shift 2 ;;
    --no-api-docs) API_DOCS=false; shift ;;
    --no-changelog) CHANGELOG=false; shift ;;
    --update-readme) README_UPDATE=true; shift ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Initialization ---
print_header "FinFlow Documentation Automation"
print_info "Starting documentation automation with action: $ACTION"

# Create necessary directories
mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$DOCS_DIR"

# Initialize log file
echo "=== FinFlow Documentation Log $(date) ===" > "$LOG_DIR/docs.log"
log_message "INFO" "Starting documentation automation with action: $ACTION"

# --- Check Prerequisites ---
print_header "Checking Prerequisites"

check_prerequisites() {
  # Check if Node.js is installed
  if ! command -v node &> /dev/null; then
    print_error "Node.js is required but not installed."
    log_message "ERROR" "Node.js is required but not installed"
    exit 1
  fi
  
  # Check if npm is installed
  if ! command -v npm &> /dev/null; then
    print_error "npm is required but not installed."
    log_message "ERROR" "npm is required but not installed"
    exit 1
  fi
  
  # Check if Git is installed
  if ! command -v git &> /dev/null; then
    print_error "Git is required but not installed."
    log_message "ERROR" "Git is required but not installed"
    exit 1
  fi
  
  # Check for API documentation tool (e.g., TypeDoc)
  if [ "$API_DOCS" = true ]; then
    if ! npm list -g typedoc &> /dev/null; then
      print_warning "TypeDoc is not installed globally. Will use local installations."
      log_message "WARNING" "TypeDoc is not installed globally. Will use local installations."
    fi
  fi
  
  # Check for changelog tool (e.g., conventional-changelog-cli)
  if [ "$CHANGELOG" = true ]; then
    if ! npm list -g conventional-changelog-cli &> /dev/null; then
      print_warning "conventional-changelog-cli is not installed globally. Will use local installations."
      log_message "WARNING" "conventional-changelog-cli is not installed globally. Will use local installations."
    fi
  fi
  
  print_success "All prerequisites are met"
  log_message "INFO" "All prerequisites are met"
}

check_prerequisites

# --- Generate API Documentation ---
if [ "$API_DOCS" = true ] && [ "$ACTION" = "generate" ]; then
  print_header "Generating API Documentation"
  
  generate_api_docs() {
    local api_docs_status=0
    
    # Determine which services to document
    if [ "$SERVICES" = "all" ]; then
      local backend_services=("auth-service" "payments-service" "accounting-service" "analytics-service" "credit-engine")
    else
      IFS="," read -ra backend_services <<< "$SERVICES"
    fi
    
    # Generate API docs for backend services
    for service in "${backend_services[@]}"; do
      local service_dir="$PROJECT_ROOT/backend/$service"
      
      if [ ! -d "$service_dir" ]; then
        print_warning "Service directory $service not found, skipping"
        log_message "WARNING" "Service directory $service not found, skipping"
        continue
      fi
      
      print_info "Generating API docs for $service..."
      log_message "INFO" "Generating API docs for $service"
      
      # Check if TypeDoc is installed locally
      if ! (cd "$service_dir" && npm list typedoc &> /dev/null); then
        print_info "Installing TypeDoc for $service..."
        (cd "$service_dir" && npm install --save-dev typedoc) || {
          print_error "Failed to install TypeDoc for $service"
          log_message "ERROR" "Failed to install TypeDoc for $service"
          api_docs_status=1
          continue
        }
      fi
      
      # Check if tsconfig.json exists
      if [ ! -f "$service_dir/tsconfig.json" ]; then
        print_warning "No tsconfig.json found for $service, skipping API docs generation"
        log_message "WARNING" "No tsconfig.json found for $service, skipping API docs generation"
        continue
      fi
      
      # Generate API docs
      local output_dir="$DOCS_DIR/api/$service"
      mkdir -p "$output_dir"
      
      (cd "$service_dir" && npx typedoc --out "$output_dir" src) || {
        print_error "Failed to generate API docs for $service"
        log_message "ERROR" "Failed to generate API docs for $service"
        api_docs_status=1
      }
      
      print_success "API docs generated for $service at $output_dir"
      log_message "INFO" "API docs generated for $service at $output_dir"
    done
    
    return $api_docs_status
  }
  
  generate_api_docs
  api_docs_status=$?
  
  if [ $api_docs_status -ne 0 ]; then
    print_error "API documentation generation failed"
    log_message "ERROR" "API documentation generation failed"
  fi
fi

# --- Generate Changelog ---
if [ "$CHANGELOG" = true ] && [ "$ACTION" = "generate" ]; then
  print_header "Generating Changelog"
  
  generate_changelog() {
    print_info "Generating changelog..."
    log_message "INFO" "Generating changelog"
    
    # Check if conventional-changelog-cli is installed locally
    if ! (cd "$PROJECT_ROOT" && npm list conventional-changelog-cli &> /dev/null); then
      print_info "Installing conventional-changelog-cli..."
      (cd "$PROJECT_ROOT" && npm install --save-dev conventional-changelog-cli) || {
        print_error "Failed to install conventional-changelog-cli"
        log_message "ERROR" "Failed to install conventional-changelog-cli"
        return 1
      }
    fi
    
    # Generate changelog
    local changelog_file="$DOCS_DIR/CHANGELOG.md"
    (cd "$PROJECT_ROOT" && npx conventional-changelog -p angular -i "$changelog_file" -s -r 0) || {
      print_error "Failed to generate changelog"
      log_message "ERROR" "Failed to generate changelog"
      return 1
    }
    
    print_success "Changelog generated at $changelog_file"
    log_message "INFO" "Changelog generated at $changelog_file"
    return 0
  }
  
  generate_changelog
  changelog_status=$?
  
  if [ $changelog_status -ne 0 ]; then
    print_error "Changelog generation failed"
    log_message "ERROR" "Changelog generation failed"
  fi
fi

# --- Update README ---
if [ "$README_UPDATE" = true ] && [ "$ACTION" = "generate" ]; then
  print_header "Updating README"
  
  update_readme() {
    print_info "Updating README..."
    log_message "INFO" "Updating README"
    
    # TODO: Implement logic to update README based on codebase changes
    # This could involve parsing package.json files, checking dependencies,
    # analyzing code structure, etc.
    
    print_warning "README update functionality is not yet implemented"
    log_message "WARNING" "README update functionality is not yet implemented"
    return 0
  }
  
  update_readme
  readme_status=$?
  
  if [ $readme_status -ne 0 ]; then
    print_error "README update failed"
    log_message "ERROR" "README update failed"
  fi
fi

# --- Clean Documentation ---
if [ "$ACTION" = "clean" ]; then
  print_header "Cleaning Documentation"
  
  clean_docs() {
    print_info "Cleaning generated documentation..."
    log_message "INFO" "Cleaning generated documentation"
    
    # Clean API docs
    if [ -d "$DOCS_DIR/api" ]; then
      rm -rf "$DOCS_DIR/api"
      print_success "Cleaned API documentation"
      log_message "INFO" "Cleaned API documentation"
    fi
    
    # Clean changelog
    if [ -f "$DOCS_DIR/CHANGELOG.md" ]; then
      rm "$DOCS_DIR/CHANGELOG.md"
      print_success "Cleaned changelog"
      log_message "INFO" "Cleaned changelog"
    fi
    
    print_success "Documentation cleaning completed"
    log_message "INFO" "Documentation cleaning completed"
    return 0
  }
  
  clean_docs
  clean_status=$?
  
  if [ $clean_status -ne 0 ]; then
    print_error "Documentation cleaning failed"
    log_message "ERROR" "Documentation cleaning failed"
  fi
fi

# --- Summary ---
print_header "Documentation Summary"

if [ "$ACTION" = "generate" ]; then
  if [ $api_docs_status -eq 0 ] && [ $changelog_status -eq 0 ] && [ $readme_status -eq 0 ]; then
    print_success "Documentation generation completed successfully!"
    log_message "INFO" "Documentation generation completed successfully"
  else
    print_warning "Documentation generation completed with warnings or errors."
    log_message "WARNING" "Documentation generation completed with warnings or errors"
  fi
  
  echo -e "\n${COLOR_GREEN}Generated Documentation:${COLOR_RESET}"
  if [ "$API_DOCS" = true ]; then
    echo -e "API Documentation: ${COLOR_CYAN}$DOCS_DIR/api${COLOR_RESET}"
  fi
  if [ "$CHANGELOG" = true ]; then
    echo -e "Changelog: ${COLOR_CYAN}$DOCS_DIR/CHANGELOG.md${COLOR_RESET}"
  fi
  
  log_message "INFO" "Documentation summary provided to user"
elif [ "$ACTION" = "clean" ]; then
  if [ $clean_status -eq 0 ]; then
    print_success "Documentation cleaning completed successfully!"
    log_message "INFO" "Documentation cleaning completed successfully"
  else
    print_error "Documentation cleaning failed"
    log_message "ERROR" "Documentation cleaning failed"
  fi
fi

exit 0
