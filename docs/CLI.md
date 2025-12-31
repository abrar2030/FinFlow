# CLI Reference

Complete reference for FinFlow command-line tools and automation scripts.

---

## Table of Contents

- [Overview](#overview)
- [Installation Scripts](#installation-scripts)
- [Development Scripts](#development-scripts)
- [Testing Scripts](#testing-scripts)
- [Database Management](#database-management)
- [Deployment Scripts](#deployment-scripts)
- [Quality & Linting](#quality--linting)
- [Monitoring Scripts](#monitoring-scripts)
- [Documentation Scripts](#documentation-scripts)

---

## Overview

FinFlow provides comprehensive CLI scripts located in the `scripts/` directory. All scripts support `--help` flag for detailed usage information.

### Quick Reference

| Script                   | Purpose                   | Common Usage                                |
| ------------------------ | ------------------------- | ------------------------------------------- |
| `finflow-setup.sh`       | Initial environment setup | `./finflow-setup.sh`                        |
| `finflow-dev.sh`         | Development workflow      | `./finflow-dev.sh --action start`           |
| `finflow-test-runner.sh` | Run tests                 | `./finflow-test-runner.sh --type all`       |
| `finflow-db.sh`          | Database management       | `./finflow-db.sh --action migrate`          |
| `finflow-deploy.sh`      | Deployment                | `./finflow-deploy.sh --environment staging` |
| `finflow-quality.sh`     | Code quality checks       | `./finflow-quality.sh --mode check`         |
| `finflow-monitor.sh`     | Monitoring setup          | `./finflow-monitor.sh --action setup`       |
| `finflow-docs.sh`        | Generate documentation    | `./finflow-docs.sh --action generate`       |

---

## Installation Scripts

### finflow-setup.sh

Complete environment setup automation.

**Command:**

```bash
./scripts/finflow-setup.sh [OPTIONS]
```

**Options:**

| Option                    | Arguments    | Description                                      | Example                                    |
| ------------------------- | ------------ | ------------------------------------------------ | ------------------------------------------ |
| `-h, --help`              | -            | Show help message                                | `--help`                                   |
| `-v, --verbose`           | -            | Enable verbose output                            | `--verbose`                                |
| `-s, --skip-dependencies` | -            | Skip dependency installation                     | `--skip-dependencies`                      |
| `-e, --environment`       | ENV          | Set environment (development/staging/production) | `--environment development`                |
| `--services`              | SERVICE_LIST | Comma-separated services to setup                | `--services auth-service,payments-service` |

**Examples:**

```bash
# Full setup for development
./scripts/finflow-setup.sh --environment development

# Setup specific services only
./scripts/finflow-setup.sh --services auth-service,payments-service

# Skip dependency installation (already installed)
./scripts/finflow-setup.sh --skip-dependencies

# Verbose mode for debugging
./scripts/finflow-setup.sh --verbose
```

**What it does:**

1. Checks system prerequisites
2. Installs Node.js dependencies for all services
3. Installs Python dependencies
4. Sets up environment variables
5. Initializes databases
6. Configures Kafka topics

---

## Development Scripts

### finflow-dev.sh

Manage development environment and service lifecycle.

**Command:**

```bash
./scripts/finflow-dev.sh [OPTIONS]
```

**Options:**

| Option            | Arguments    | Description                                   | Example                                    |
| ----------------- | ------------ | --------------------------------------------- | ------------------------------------------ |
| `-h, --help`      | -            | Show help message                             | `--help`                                   |
| `-v, --verbose`   | -            | Enable verbose output                         | `--verbose`                                |
| `-a, --action`    | ACTION       | Action to perform (start/stop/restart/status) | `--action start`                           |
| `-s, --services`  | SERVICE_LIST | Comma-separated services                      | `--services auth-service,payments-service` |
| `--no-hot-reload` | -            | Disable hot reloading                         | `--no-hot-reload`                          |
| `--debug`         | -            | Enable debug mode                             | `--debug`                                  |
| `--port-offset`   | OFFSET       | Port offset for services                      | `--port-offset 100`                        |

**Examples:**

```bash
# Start all services in development mode
./scripts/finflow-dev.sh --action start

# Start specific services
./scripts/finflow-dev.sh --action start --services auth-service,payments-service

# Start with debug logging
./scripts/finflow-dev.sh --action start --debug

# Check service status
./scripts/finflow-dev.sh --action status

# Restart services
./scripts/finflow-dev.sh --action restart

# Stop all services
./scripts/finflow-dev.sh --action stop

# Start with custom port offset
./scripts/finflow-dev.sh --action start --port-offset 1000
```

---

## Testing Scripts

### finflow-test-runner.sh

Unified test runner for all services.

**Command:**

```bash
./scripts/finflow-test-runner.sh [OPTIONS]
```

**Options:**

| Option           | Arguments    | Description                          | Example                   |
| ---------------- | ------------ | ------------------------------------ | ------------------------- |
| `-h, --help`     | -            | Show help message                    | `--help`                  |
| `-v, --verbose`  | -            | Enable verbose output                | `--verbose`               |
| `-t, --type`     | TYPE         | Test type (unit/integration/e2e/all) | `--type unit`             |
| `-s, --services` | SERVICE_LIST | Services to test                     | `--services auth-service` |
| `-r, --report`   | FORMAT       | Report format (html/json/junit)      | `--report html`           |
| `-w, --watch`    | -            | Run tests in watch mode              | `--watch`                 |
| `-c, --coverage` | -            | Generate coverage reports            | `--coverage`              |

**Examples:**

```bash
# Run all tests
./scripts/finflow-test-runner.sh --type all

# Run unit tests only
./scripts/finflow-test-runner.sh --type unit

# Run tests for specific service
./scripts/finflow-test-runner.sh --services auth-service

# Run with coverage report
./scripts/finflow-test-runner.sh --coverage --report html

# Run integration tests
./scripts/finflow-test-runner.sh --type integration

# Run end-to-end tests
./scripts/finflow-test-runner.sh --type e2e

# Watch mode for development
./scripts/finflow-test-runner.sh --type unit --watch
```

**Test Types:**

| Type          | Description       | Scope                             |
| ------------- | ----------------- | --------------------------------- |
| `unit`        | Unit tests        | Individual functions and classes  |
| `integration` | Integration tests | Service interactions and database |
| `e2e`         | End-to-end tests  | Full user workflows               |
| `all`         | All test types    | Complete test suite               |

---

## Database Management

### finflow-db.sh

Database operations and maintenance.

**Command:**

```bash
./scripts/finflow-db.sh [OPTIONS]
```

**Options:**

| Option              | Arguments | Description                                  | Example                           |
| ------------------- | --------- | -------------------------------------------- | --------------------------------- |
| `-h, --help`        | -         | Show help message                            | `--help`                          |
| `-v, --verbose`     | -         | Enable verbose output                        | `--verbose`                       |
| `-a, --action`      | ACTION    | Action (migrate/seed/backup/restore/health)  | `--action migrate`                |
| `-e, --environment` | ENV       | Environment (development/staging/production) | `--environment development`       |
| `-t, --type`        | TYPE      | Database type (postgres/mongodb/all)         | `--type postgres`                 |
| `-b, --backup-name` | NAME      | Backup name for restore                      | `--backup-name backup-2025-01-20` |

**Examples:**

```bash
# Run database migrations
./scripts/finflow-db.sh --action migrate --environment development

# Seed development data
./scripts/finflow-db.sh --action seed --environment development

# Create backup
./scripts/finflow-db.sh --action backup --environment production

# Restore from backup
./scripts/finflow-db.sh --action restore --backup-name backup-2025-01-20

# Check database health
./scripts/finflow-db.sh --action health

# Migrate specific database type
./scripts/finflow-db.sh --action migrate --type postgres
```

**Actions:**

| Action    | Description                 | Safe in Production? |
| --------- | --------------------------- | ------------------- |
| `migrate` | Run pending migrations      | Yes                 |
| `seed`    | Populate with sample data   | No (dev only)       |
| `backup`  | Create database backup      | Yes                 |
| `restore` | Restore from backup         | Caution required    |
| `health`  | Check database connectivity | Yes                 |

---

## Deployment Scripts

### finflow-deploy.sh

Application deployment automation.

**Command:**

```bash
./scripts/finflow-deploy.sh [OPTIONS]
```

**Options:**

| Option              | Arguments    | Description                  | Example                       |
| ------------------- | ------------ | ---------------------------- | ----------------------------- |
| `-h, --help`        | -            | Show help message            | `--help`                      |
| `-v, --verbose`     | -            | Enable verbose output        | `--verbose`                   |
| `-e, --environment` | ENV          | Target environment           | `--environment production`    |
| `-s, --services`    | SERVICE_LIST | Services to deploy           | `--services payments-service` |
| `--skip-build`      | -            | Skip build step              | `--skip-build`                |
| `--skip-tests`      | -            | Skip tests (not recommended) | `--skip-tests`                |
| `--rollback`        | -            | Rollback to previous version | `--rollback`                  |
| `--blue-green`      | -            | Use blue-green deployment    | `--blue-green`                |

**Examples:**

```bash
# Deploy to staging
./scripts/finflow-deploy.sh --environment staging

# Deploy to production with tests
./scripts/finflow-deploy.sh --environment production

# Deploy specific services
./scripts/finflow-deploy.sh --environment production --services payments-service,auth-service

# Rollback deployment
./scripts/finflow-deploy.sh --environment production --rollback

# Blue-green deployment
./scripts/finflow-deploy.sh --environment production --blue-green

# Skip tests (emergency only)
./scripts/finflow-deploy.sh --environment staging --skip-tests
```

**Deployment Flow:**

1. Run tests (unless skipped)
2. Build Docker images
3. Push to registry
4. Update Kubernetes manifests
5. Apply rolling update
6. Verify deployment health
7. Send notifications

---

## Quality & Linting

### finflow-quality.sh

Code quality checks and fixes.

**Command:**

```bash
./scripts/finflow-quality.sh [OPTIONS]
```

**Options:**

| Option                 | Arguments    | Description                       | Example                   |
| ---------------------- | ------------ | --------------------------------- | ------------------------- |
| `-h, --help`           | -            | Show help message                 | `--help`                  |
| `-v, --verbose`        | -            | Enable verbose output             | `--verbose`               |
| `-m, --mode`           | MODE         | Mode (check/fix)                  | `--mode check`            |
| `-s, --services`       | SERVICE_LIST | Services to check                 | `--services auth-service` |
| `--install-hooks`      | -            | Install Git pre-commit hooks      | `--install-hooks`         |
| `--report`             | -            | Generate HTML quality report      | `--report`                |
| `--vulnerability-scan` | -            | Run dependency vulnerability scan | `--vulnerability-scan`    |

**Examples:**

```bash
# Check code quality
./scripts/finflow-quality.sh --mode check

# Auto-fix issues
./scripts/finflow-quality.sh --mode fix

# Install pre-commit hooks
./scripts/finflow-quality.sh --install-hooks

# Generate quality report
./scripts/finflow-quality.sh --report

# Run vulnerability scan
./scripts/finflow-quality.sh --vulnerability-scan

# Check specific services
./scripts/finflow-quality.sh --mode check --services auth-service,payments-service
```

**Checks Performed:**

- ESLint for TypeScript/JavaScript
- Pylint/Flake8 for Python
- Prettier formatting
- TypeScript type checking
- Security vulnerabilities
- Code complexity analysis

---

## Monitoring Scripts

### finflow-monitor.sh

Monitoring stack setup and management.

**Command:**

```bash
./scripts/finflow-monitor.sh [OPTIONS]
```

**Options:**

| Option              | Arguments    | Description                      | Example                  |
| ------------------- | ------------ | -------------------------------- | ------------------------ |
| `-h, --help`        | -            | Show help message                | `--help`                 |
| `-v, --verbose`     | -            | Enable verbose output            | `--verbose`              |
| `-a, --action`      | ACTION       | Action (setup/start/stop/status) | `--action setup`         |
| `-s, --services`    | SERVICE_LIST | Services to monitor              | `--services all`         |
| `--dashboard-only`  | -            | Setup dashboards only            | `--dashboard-only`       |
| `--alerts-only`     | -            | Setup alerts only                | `--alerts-only`          |
| `--grafana-port`    | PORT         | Grafana port                     | `--grafana-port 3000`    |
| `--prometheus-port` | PORT         | Prometheus port                  | `--prometheus-port 9090` |

**Examples:**

```bash
# Setup monitoring stack
./scripts/finflow-monitor.sh --action setup

# Start monitoring
./scripts/finflow-monitor.sh --action start

# Check monitoring status
./scripts/finflow-monitor.sh --action status

# Setup dashboards only
./scripts/finflow-monitor.sh --action setup --dashboard-only

# Setup alerts only
./scripts/finflow-monitor.sh --action setup --alerts-only

# Custom ports
./scripts/finflow-monitor.sh --action setup --grafana-port 3001 --prometheus-port 9091
```

**Components:**

- Prometheus (metrics collection)
- Grafana (dashboards)
- ELK Stack (log aggregation)
- Alert Manager (alerts)

---

## Documentation Scripts

### finflow-docs.sh

Documentation generation automation.

**Command:**

```bash
./scripts/finflow-docs.sh [OPTIONS]
```

**Options:**

| Option            | Arguments    | Description               | Example             |
| ----------------- | ------------ | ------------------------- | ------------------- |
| `-h, --help`      | -            | Show help message         | `--help`            |
| `-v, --verbose`   | -            | Enable verbose output     | `--verbose`         |
| `-a, --action`    | ACTION       | Action (generate/clean)   | `--action generate` |
| `-s, --services`  | SERVICE_LIST | Services to document      | `--services all`    |
| `--no-api-docs`   | -            | Skip API documentation    | `--no-api-docs`     |
| `--no-changelog`  | -            | Skip changelog generation | `--no-changelog`    |
| `--update-readme` | -            | Update README files       | `--update-readme`   |

**Examples:**

```bash
# Generate all documentation
./scripts/finflow-docs.sh --action generate

# Generate API docs only
./scripts/finflow-docs.sh --action generate --no-changelog

# Update READMEs
./scripts/finflow-docs.sh --update-readme

# Clean generated docs
./scripts/finflow-docs.sh --action clean

# Document specific services
./scripts/finflow-docs.sh --action generate --services auth-service,payments-service
```

---

## Build Script

### finflow-build.sh

Build services and Docker images.

**Command:**

```bash
./scripts/finflow-build.sh [OPTIONS]
```

**Examples:**

```bash
# Build all services
./scripts/finflow-build.sh

# Build specific service
./scripts/finflow-build.sh --service payments-service

# Build Docker images
./scripts/finflow-build.sh --docker

# Build and push to registry
./scripts/finflow-build.sh --docker --push
```

---

## Global Flags

All scripts support these common flags:

| Flag            | Description                               |
| --------------- | ----------------------------------------- |
| `-h, --help`    | Display help information                  |
| `-v, --verbose` | Enable verbose output                     |
| `--dry-run`     | Show what would be done without executing |
| `--version`     | Show script version                       |

---

## Environment Variables

Scripts respect these environment variables:

| Variable            | Description                                  | Default       |
| ------------------- | -------------------------------------------- | ------------- |
| `FINFLOW_ENV`       | Environment (development/staging/production) | `development` |
| `FINFLOW_ROOT`      | Project root directory                       | Auto-detected |
| `FINFLOW_LOG_LEVEL` | Log level (debug/info/warn/error)            | `info`        |

---

## Tips & Best Practices

### Running in CI/CD

```bash
# Non-interactive mode
export CI=true
./scripts/finflow-test-runner.sh --type all --report junit

# Quiet mode
./scripts/finflow-quality.sh --mode check --quiet
```

### Parallel Execution

```bash
# Run tests in parallel
./scripts/finflow-test-runner.sh --type unit --parallel

# Deploy multiple environments
./scripts/finflow-deploy.sh --environment staging &
./scripts/finflow-deploy.sh --environment qa &
wait
```

### Error Handling

All scripts return appropriate exit codes:

- `0`: Success
- `1`: General error
- `2`: Invalid arguments
- `3`: Prerequisite check failed

---

For complete usage and examples, run any script with `--help` flag.
