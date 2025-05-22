# FinFlow Automation Scripts

This package contains automation scripts designed to enhance the development, testing, and deployment workflow for the FinFlow project.

## Overview

These scripts address key automation opportunities identified in the FinFlow repository, focusing on:

1. Environment setup and configuration
2. Testing automation
3. Build and deployment pipeline
4. Code quality and linting
5. Monitoring and alerting
6. Documentation generation
7. Database management
8. Cross-service development workflow

## Installation

1. Extract this zip file to the root directory of your FinFlow project
2. Make the scripts executable:
   ```
   chmod +x *.sh
   ```

## Scripts Included

### 1. `finflow-setup.sh`
Comprehensive environment setup script that automates the entire setup process.

**Usage:**
```
./finflow-setup.sh [OPTIONS]

Options:
  -h, --help                 Show this help message
  -v, --verbose              Enable verbose output
  -s, --skip-dependencies    Skip dependency installation
  -e, --environment ENV      Set environment (development, staging, production)
  --services SERVICES        Comma-separated list of services to set up (default: all)
```

### 2. `finflow-test-runner.sh`
Unified test runner for executing all types of tests across services.

**Usage:**
```
./finflow-test-runner.sh [OPTIONS]

Options:
  -h, --help                 Show this help message
  -v, --verbose              Enable verbose output
  -t, --type TYPE            Test type to run (unit, integration, e2e, all)
  -s, --services SERVICES    Comma-separated list of services to test (default: all)
  -r, --report FORMAT        Report format (html, json, junit)
  -w, --watch                Run tests in watch mode
  -c, --coverage             Generate test coverage reports
```

### 3. `finflow-deploy.sh`
Enhanced deployment script with environment-specific configuration and verification.

**Usage:**
```
./finflow-deploy.sh [OPTIONS]

Options:
  -h, --help                 Show this help message
  -v, --verbose              Enable verbose output
  -e, --environment ENV      Set environment (development, staging, production)
  -s, --services SERVICES    Comma-separated list of services to deploy (default: all)
  --skip-build               Skip build step
  --skip-tests               Skip tests
  --rollback                 Rollback to previous version
  --blue-green               Use blue-green deployment strategy
```

### 4. `finflow-quality.sh`
Advanced code quality automation with pre-commit hooks and reporting.

**Usage:**
```
./finflow-quality.sh [OPTIONS]

Options:
  -h, --help                 Show this help message
  -v, --verbose              Enable verbose output
  -m, --mode MODE            Mode (check, fix)
  -s, --services SERVICES    Comma-separated list of services to check (default: all)
  --install-hooks            Install Git pre-commit hooks
  --report                   Generate HTML quality reports
  --vulnerability-scan       Run dependency vulnerability scan
```

### 5. `finflow-monitor.sh`
Monitoring automation for dashboard setup and alert configuration.

**Usage:**
```
./finflow-monitor.sh [OPTIONS]

Options:
  -h, --help                 Show this help message
  -v, --verbose              Enable verbose output
  -a, --action ACTION        Action to perform (setup, start, stop, status)
  -s, --services SERVICES    Comma-separated list of services to monitor (default: all)
  --dashboard-only           Only set up dashboards (skip Prometheus/Grafana setup)
  --alerts-only              Only set up alerts (skip Prometheus/Grafana setup)
  --grafana-port PORT        Grafana port (default: 3000)
  --prometheus-port PORT     Prometheus port (default: 9090)
```

### 6. `finflow-docs.sh`
Documentation generation automation for API docs and changelogs.

**Usage:**
```
./finflow-docs.sh [OPTIONS]

Options:
  -h, --help                 Show this help message
  -v, --verbose              Enable verbose output
  -a, --action ACTION        Action to perform (generate, clean)
  -s, --services SERVICES    Comma-separated list of services to document (default: all)
  --no-api-docs              Skip API documentation generation
  --no-changelog             Skip changelog generation
  --update-readme            Update README based on codebase changes
```

### 7. `finflow-db.sh`
Database management automation for migrations, seeding, and maintenance.

**Usage:**
```
./finflow-db.sh [OPTIONS]

Options:
  -h, --help                 Show this help message
  -v, --verbose              Enable verbose output
  -a, --action ACTION        Action to perform (migrate, seed, backup, restore, health)
  -e, --environment ENV      Set environment (development, staging, production)
  -t, --type TYPE            Database type (postgres, mongodb, all)
  -b, --backup-name NAME     Backup name for restore action
```

### 8. `finflow-dev.sh`
Development workflow automation for cross-service coordination.

**Usage:**
```
./finflow-dev.sh [OPTIONS]

Options:
  -h, --help                 Show this help message
  -v, --verbose              Enable verbose output
  -a, --action ACTION        Action to perform (start, stop, restart, status)
  -s, --services SERVICES    Comma-separated list of services to manage (default: all)
  --no-hot-reload            Disable hot reloading
  --debug                    Enable debug mode
  --port-offset OFFSET       Port offset for services (default: 0)
```

## Requirements

- Bash 4.0+
- Node.js 16+
- Docker and Docker Compose (for some features)
- Git

## Automation Opportunities Addressed

These scripts address the following automation opportunities identified in the FinFlow repository:

1. **Environment Setup and Configuration**
   - One-command environment setup
   - Automatic dependency detection and installation
   - Environment-specific configuration

2. **Testing Automation**
   - Unified test runner for all services
   - Comprehensive test reports
   - Selective test execution

3. **Build and Deployment Pipeline**
   - One-command build and deployment
   - Environment-specific configuration
   - Automated rollback capabilities
   - Blue/green deployment support

4. **Code Quality and Linting**
   - Git pre-commit hooks
   - Automated code quality reports
   - Dependency vulnerability scanning

5. **Monitoring and Alerting**
   - Automated dashboard setup
   - Predefined alert configurations
   - Performance benchmark testing

6. **Documentation Generation**
   - API documentation generation
   - Changelog generation from commits
   - README updates

7. **Database Management**
   - Automated schema migration
   - Data seeding for development and testing
   - Backup and restore procedures

8. **Cross-Service Development Workflow**
   - Service dependency management
   - Unified service startup
   - Hot-reloading across services

## Contributing

Feel free to enhance these scripts or add new ones as needed. Please maintain the existing code style and documentation standards.
