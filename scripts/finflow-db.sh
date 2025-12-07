#!/bin/bash

set -euo pipefail

# FinFlow Database Management Automation
# This script automates database migrations, seeding, backups, and maintenance
# Version: 1.0.0

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
LOG_DIR="$PROJECT_ROOT/logs"
DB_DIR="$PROJECT_ROOT/database"
BACKUP_DIR="$PROJECT_ROOT/database/backups"

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
  echo "[$timestamp] [$level] $message" >> "$LOG_DIR/database.log"
}

# --- Command Line Arguments ---
VERBOSE=false
ACTION="migrate"
ENV="development"
DB_TYPE="all"
BACKUP_NAME=""

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Enable verbose output"
  echo "  -a, --action ACTION        Action to perform (migrate, seed, backup, restore, health)"
  echo "  -e, --environment ENV      Set environment (development, staging, production)"
  echo "  -t, --type TYPE            Database type (postgres, mongodb, all)"
  echo "  -b, --backup-name NAME     Backup name for restore action"
  echo
  echo "Examples:"
  echo "  $0 --action migrate"
  echo "  $0 --action seed --environment development"
  echo "  $0 --action backup --type postgres"
  echo "  $0 --action restore --backup-name postgres_20250520_120000"
  exit 0
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -a|--action) ACTION="$2"; shift 2 ;;
    -e|--environment) ENV="$2"; shift 2 ;;
    -t|--type) DB_TYPE="$2"; shift 2 ;;
    -b|--backup-name) BACKUP_NAME="$2"; shift 2 ;;
    *) print_error "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Initialization ---
print_header "FinFlow Database Management"
print_info "Starting database management with action: $ACTION"

# Create necessary directories
mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$DB_DIR" "$BACKUP_DIR"

# Initialize log file
echo "=== FinFlow Database Management Log $(date) ===" > "$LOG_DIR/database.log"
log_message "INFO" "Starting database management with action: $ACTION"

# --- Check Prerequisites ---
print_header "Checking Prerequisites"

check_prerequisites() {
  # Check if Docker is installed and running (for containerized databases)
  if ! command -v docker &> /dev/null; then
    print_warning "Docker is not installed. Some features may not work."
    log_message "WARNING" "Docker is not installed. Some features may not work."
  else
    if ! docker info &> /dev/null; then
      print_warning "Docker is not running. Some features may not work."
      log_message "WARNING" "Docker is not running. Some features may not work."
    fi
  fi
  
  # Check for PostgreSQL client
  if [ "$DB_TYPE" = "postgres" ] || [ "$DB_TYPE" = "all" ]; then
    if ! command -v psql &> /dev/null; then
      print_warning "PostgreSQL client is not installed. Some features may not work."
      log_message "WARNING" "PostgreSQL client is not installed. Some features may not work."
    fi
  fi
  
  # Check for MongoDB client
  if [ "$DB_TYPE" = "mongodb" ] || [ "$DB_TYPE" = "all" ]; then
    if ! command -v mongosh &> /dev/null && ! command -v mongo &> /dev/null; then
      print_warning "MongoDB client is not installed. Some features may not work."
      log_message "WARNING" "MongoDB client is not installed. Some features may not work."
    fi
  fi
  
  # Check for Node.js (for running migrations)
  if ! command -v node &> /dev/null; then
    print_error "Node.js is required but not installed."
    log_message "ERROR" "Node.js is required but not installed"
    exit 1
  fi
  
  print_success "Prerequisites check completed"
  log_message "INFO" "Prerequisites check completed"
}

check_prerequisites

# --- Load Environment Variables ---
print_header "Loading Environment Variables"

load_env_variables() {
  # Check for environment-specific .env file
  if [ "$ENV" != "development" ] && [ -f "$PROJECT_ROOT/.env.${ENV}" ]; then
    source "$PROJECT_ROOT/.env.${ENV}"
    print_info "Loaded environment variables from .env.${ENV}"
    log_message "INFO" "Loaded environment variables from .env.${ENV}"
  elif [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
    print_info "Loaded environment variables from .env"
    log_message "INFO" "Loaded environment variables from .env"
  else
    print_warning "No .env file found. Using default values."
    log_message "WARNING" "No .env file found. Using default values."
    
    # Set default values
    export POSTGRES_HOST="localhost"
    export POSTGRES_PORT="5432"
    export POSTGRES_USER="finflow"
    export POSTGRES_PASSWORD="password"
    export POSTGRES_DB="finflow"
    
    export MONGODB_URI="mongodb://localhost:27017/finflow"
  fi
  
  # Extract MongoDB connection details
  if [ -n "$MONGODB_URI" ]; then
    # Parse MongoDB URI to extract host, port, and database name\n    # Using a more robust and secure method with regex and parameter expansion\n    # Note: This is a basic parser and may not handle all complex URI formats (e.g., with auth or query params)
    # Extract protocol and credentials (if any) - not used for host/port but good to know\n    local uri_no_protocol="${MONGODB_URI#*://}"\n    local uri_no_auth="${uri_no_protocol#*@}"\n    local host_port_db="${uri_no_auth%%/*}"\n    local db_name="${uri_no_auth#*/}"\n\n    # Extract host and port\n    MONGODB_HOST="${host_port_db%:*}"\n    MONGODB_PORT="${host_port_db##*:}"\n    MONGODB_DB="${db_name%%\?*}" # Remove query parameters
    # Original sed lines removed for clarity and security
    # Original sed lines removed for clarity and security
    
    if [ -z "$MONGODB_HOST" ]; then
      MONGODB_HOST="localhost"
    fi
    
    if [ -z "$MONGODB_PORT" ]; then
      MONGODB_PORT="27017"
    fi
    
    if [ -z "$MONGODB_DB" ]; then
      MONGODB_DB="finflow"
    fi
  fi
  
  print_success "Environment variables loaded"
  log_message "INFO" "Environment variables loaded"
}

load_env_variables

# --- Database Migration ---
if [ "$ACTION" = "migrate" ]; then
  print_header "Running Database Migrations"
  
  run_postgres_migrations() {
    print_info "Running PostgreSQL migrations..."
    log_message "INFO" "Running PostgreSQL migrations"
    
    # Check for migration scripts
    local migration_dir="$DB_DIR/migrations/postgres"
    if [ ! -d "$migration_dir" ]; then
      print_warning "PostgreSQL migration directory not found. Creating it..."
      log_message "WARNING" "PostgreSQL migration directory not found. Creating it..."
      mkdir -p "$migration_dir"
    fi
    
    # Check for migration tool
    if [ -f "$PROJECT_ROOT/backend/node_modules/.bin/knex" ]; then
      local knex_bin="$PROJECT_ROOT/backend/node_modules/.bin/knex"
    elif [ -f "$PROJECT_ROOT/node_modules/.bin/knex" ]; then
      local knex_bin="$PROJECT_ROOT/node_modules/.bin/knex"
    else
      print_info "Installing Knex.js for migrations..."
      (cd "$PROJECT_ROOT" && npm install knex pg) || {
        print_error "Failed to install Knex.js"
        log_message "ERROR" "Failed to install Knex.js"
        return 1
      }
      local knex_bin="$PROJECT_ROOT/node_modules/.bin/knex"
    fi
    
    # Create knexfile.js if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/knexfile.js" ]; then
      print_info "Creating knexfile.js..."
      cat > "$PROJECT_ROOT/knexfile.js" << EOL
module.exports = {
  development: {
    client: 'pg',
    connection: {
      host: process.env.POSTGRES_HOST || 'localhost',
      port: process.env.POSTGRES_PORT || 5432,
      user: process.env.POSTGRES_USER || 'finflow',
      password: process.env.POSTGRES_PASSWORD || 'password',
      database: process.env.POSTGRES_DB || 'finflow',
    },
    migrations: {
      directory: './database/migrations/postgres',
    },
    seeds: {
      directory: './database/seeds/postgres',
    },
  },
  staging: {
    client: 'pg',
    connection: {
      host: process.env.POSTGRES_HOST,
      port: process.env.POSTGRES_PORT,
      user: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      database: process.env.POSTGRES_DB,
    },
    migrations: {
      directory: './database/migrations/postgres',
    },
    seeds: {
      directory: './database/seeds/postgres',
    },
  },
  production: {
    client: 'pg',
    connection: {
      host: process.env.POSTGRES_HOST,
      port: process.env.POSTGRES_PORT,
      user: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      database: process.env.POSTGRES_DB,
    },
    migrations: {
      directory: './database/migrations/postgres',
    },
    seeds: {
      directory: './database/seeds/postgres',
    },
  },
};
EOL
      print_success "Created knexfile.js"
      log_message "INFO" "Created knexfile.js"
    fi
    
    # Run migrations
    print_info "Running PostgreSQL migrations for $ENV environment..."
    (cd "$PROJECT_ROOT" && "$knex_bin" migrate:latest --env "$ENV") || {
      print_error "Failed to run PostgreSQL migrations"
      log_message "ERROR" "Failed to run PostgreSQL migrations"
      return 1
    }
    
    print_success "PostgreSQL migrations completed"
    log_message "INFO" "PostgreSQL migrations completed"
    return 0
  }
  
  run_mongodb_migrations() {
    print_info "Running MongoDB migrations..."
    log_message "INFO" "Running MongoDB migrations"
    
    # Check for migration scripts
    local migration_dir="$DB_DIR/migrations/mongodb"
    if [ ! -d "$migration_dir" ]; then
      print_warning "MongoDB migration directory not found. Creating it..."
      log_message "WARNING" "MongoDB migration directory not found. Creating it..."
      mkdir -p "$migration_dir"
    }
    
    # Check for migration tool
    if [ -f "$PROJECT_ROOT/backend/node_modules/.bin/migrate-mongo" ]; then
      local migrate_mongo_bin="$PROJECT_ROOT/backend/node_modules/.bin/migrate-mongo"
    elif [ -f "$PROJECT_ROOT/node_modules/.bin/migrate-mongo" ]; then
      local migrate_mongo_bin="$PROJECT_ROOT/node_modules/.bin/migrate-mongo"
    else
      print_info "Installing migrate-mongo for migrations..."
      (cd "$PROJECT_ROOT" && npm install migrate-mongo) || {
        print_error "Failed to install migrate-mongo"
        log_message "ERROR" "Failed to install migrate-mongo"
        return 1
      }
      local migrate_mongo_bin="$PROJECT_ROOT/node_modules/.bin/migrate-mongo"
    fi
    
    # Create migrate-mongo-config.js if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/migrate-mongo-config.js" ]; then
      print_info "Creating migrate-mongo-config.js..."
      cat > "$PROJECT_ROOT/migrate-mongo-config.js" << EOL
const config = {
  mongodb: {
    url: process.env.MONGODB_URI || "mongodb://localhost:27017/finflow",
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    }
  },
  migrationsDir: "database/migrations/mongodb",
  changelogCollectionName: "changelog",
  migrationFileExtension: ".js",
  useFileHash: false,
  moduleSystem: 'commonjs',
};

module.exports = config;
EOL
      print_success "Created migrate-mongo-config.js"
      log_message "INFO" "Created migrate-mongo-config.js"
    fi
    
    # Run migrations
    print_info "Running MongoDB migrations..."
    (cd "$PROJECT_ROOT" && "$migrate_mongo_bin" up) || {
      print_error "Failed to run MongoDB migrations"
      log_message "ERROR" "Failed to run MongoDB migrations"
      return 1
    }
    
    print_success "MongoDB migrations completed"
    log_message "INFO" "MongoDB migrations completed"
    return 0
  }
  
  # Run migrations based on database type
  if [ "$DB_TYPE" = "postgres" ] || [ "$DB_TYPE" = "all" ]; then
    run_postgres_migrations
    postgres_status=$?
  fi
  
  if [ "$DB_TYPE" = "mongodb" ] || [ "$DB_TYPE" = "all" ]; then
    run_mongodb_migrations
    mongodb_status=$?
  fi
  
  # Check migration status
  if [ "$DB_TYPE" = "all" ]; then
    if [ $postgres_status -eq 0 ] && [ $mongodb_status -eq 0 ]; then
      print_success "All database migrations completed successfully"
      log_message "INFO" "All database migrations completed successfully"
    else
      print_error "Some database migrations failed"
      log_message "ERROR" "Some database migrations failed"
      exit 1
    fi
  elif [ "$DB_TYPE" = "postgres" ] && [ $postgres_status -ne 0 ]; then
    print_error "PostgreSQL migrations failed"
    log_message "ERROR" "PostgreSQL migrations failed"
    exit 1
  elif [ "$DB_TYPE" = "mongodb" ] && [ $mongodb_status -ne 0 ]; then
    print_error "MongoDB migrations failed"
    log_message "ERROR" "MongoDB migrations failed"
    exit 1
  fi
fi

# --- Database Seeding ---
if [ "$ACTION" = "seed" ]; then
  print_header "Seeding Database"
  
  seed_postgres_database() {
    print_info "Seeding PostgreSQL database..."
    log_message "INFO" "Seeding PostgreSQL database"
    
    # Check for seed scripts
    local seed_dir="$DB_DIR/seeds/postgres"
    if [ ! -d "$seed_dir" ]; then
      print_warning "PostgreSQL seed directory not found. Creating it..."
      log_message "WARNING" "PostgreSQL seed directory not found. Creating it..."
      mkdir -p "$seed_dir"
      
      # Create sample seed file
      print_info "Creating sample seed file..."
      cat > "$seed_dir/01_users.js" << EOL
exports.seed = function(knex) {
  // Deletes ALL existing entries
  return knex('users').del()
    .then(function () {
      // Inserts seed entries
      return knex('users').insert([
        {id: 1, name: 'Admin User', email: 'admin@example.com', role: 'admin'},
        {id: 2, name: 'Test User', email: 'test@example.com', role: 'user'},
      ]);
    });
};
EOL
      print_success "Created sample seed file"
      log_message "INFO" "Created sample seed file"
    }
    
    # Check for knex
    if [ -f "$PROJECT_ROOT/backend/node_modules/.bin/knex" ]; then
      local knex_bin="$PROJECT_ROOT/backend/node_modules/.bin/knex"
    elif [ -f "$PROJECT_ROOT/node_modules/.bin/knex" ]; then
      local knex_bin="$PROJECT_ROOT/node_modules/.bin/knex"
    else
      print_info "Installing Knex.js for seeding..."
      (cd "$PROJECT_ROOT" && npm install knex pg) || {
        print_error "Failed to install Knex.js"
        log_message "ERROR" "Failed to install Knex.js"
        return 1
      }
      local knex_bin="$PROJECT_ROOT/node_modules/.bin/knex"
    fi
    
    # Run seeds
    print_info "Running PostgreSQL seeds for $ENV environment..."
    (cd "$PROJECT_ROOT" && "$knex_bin" seed:run --env "$ENV") || {
      print_error "Failed to run PostgreSQL seeds"
      log_message "ERROR" "Failed to run PostgreSQL seeds"
      return 1
    }
    
    print_success "PostgreSQL seeding completed"
    log_message "INFO" "PostgreSQL seeding completed"
    return 0
  }
  
  seed_mongodb_database() {
    print_info "Seeding MongoDB database..."
    log_message "INFO" "Seeding MongoDB database"
    
    # Check for seed scripts
    local seed_dir="$DB_DIR/seeds/mongodb"
    if [ ! -d "$seed_dir" ]; then
      print_warning "MongoDB seed directory not found. Creating it..."
      log_message "WARNING" "MongoDB seed directory not found. Creating it..."
      mkdir -p "$seed_dir"
      
      # Create sample seed file
      print_info "Creating sample seed file..."
      cat > "$seed_dir/users.js" << EOL
const { MongoClient } = require('mongodb');

async function seedUsers() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/finflow';
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    const database = client.db();
    const users = database.collection('users');
    
    // Delete existing users
    await users.deleteMany({});
    
    // Insert new users
    const result = await users.insertMany([
      {
        name: 'Admin User',
        email: 'admin@example.com',
        role: 'admin',
        createdAt: new Date()
      },
      {
        name: 'Test User',
        email: 'test@example.com',
        role: 'user',
        createdAt: new Date()
      }
    ]);
    
    console.log(\`\${result.insertedCount} users were inserted\`);
  } finally {
    await client.close();
  }
}

seedUsers().catch(console.error);
EOL
      print_success "Created sample seed file"
      log_message "INFO" "Created sample seed file"
    }
    
    # Run seeds
    print_info "Running MongoDB seeds..."
    for seed_file in "$seed_dir"/*.js; do
      if [ -f "$seed_file" ]; then
        print_info "Running seed file: $(basename "$seed_file")..."
        (cd "$PROJECT_ROOT" && node "$seed_file") || {
          print_error "Failed to run seed file: $(basename "$seed_file")"
          log_message "ERROR" "Failed to run seed file: $(basename "$seed_file")"
          return 1
        }
      fi
    done
    
    print_success "MongoDB seeding completed"
    log_message "INFO" "MongoDB seeding completed"
    return 0
  }
  
  # Run seeds based on database type
  if [ "$DB_TYPE" = "postgres" ] || [ "$DB_TYPE" = "all" ]; then
    seed_postgres_database
    postgres_status=$?
  fi
  
  if [ "$DB_TYPE" = "mongodb" ] || [ "$DB_TYPE" = "all" ]; then
    seed_mongodb_database
    mongodb_status=$?
  fi
  
  # Check seeding status
  if [ "$DB_TYPE" = "all" ]; then
    if [ $postgres_status -eq 0 ] && [ $mongodb_status -eq 0 ]; then
      print_success "All database seeding completed successfully"
      log_message "INFO" "All database seeding completed successfully"
    else
      print_error "Some database seeding failed"
      log_message "ERROR" "Some database seeding failed"
      exit 1
    fi
  elif [ "$DB_TYPE" = "postgres" ] && [ $postgres_status -ne 0 ]; then
    print_error "PostgreSQL seeding failed"
    log_message "ERROR" "PostgreSQL seeding failed"
    exit 1
  elif [ "$DB_TYPE" = "mongodb" ] && [ $mongodb_status -ne 0 ]; then
    print_error "MongoDB seeding failed"
    log_message "ERROR" "MongoDB seeding failed"
    exit 1
  fi
fi

# --- Database Backup ---
if [ "$ACTION" = "backup" ]; then
  print_header "Backing Up Database"
  
  backup_postgres_database() {
    print_info "Backing up PostgreSQL database..."
    log_message "INFO" "Backing up PostgreSQL database"
    
    # Create timestamp for backup file
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/postgres_${ENV}_${timestamp}.sql"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Run backup command
    PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -F p > "$backup_file" || {
      print_error "Failed to backup PostgreSQL database"
      log_message "ERROR" "Failed to backup PostgreSQL database"
      return 1
    }
    
    # Compress backup file
    gzip "$backup_file" || {
      print_error "Failed to compress backup file"
      log_message "ERROR" "Failed to compress backup file"
      return 1
    }
    
    print_success "PostgreSQL backup completed: ${backup_file}.gz"
    log_message "INFO" "PostgreSQL backup completed: ${backup_file}.gz"
    return 0
  }
  
  backup_mongodb_database() {
    print_info "Backing up MongoDB database..."
    log_message "INFO" "Backing up MongoDB database"
    
    # Create timestamp for backup file
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    local backup_dir="$BACKUP_DIR/mongodb_${ENV}_${timestamp}"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"
    
    # Run backup command
    mongodump --host "$MONGODB_HOST" --port "$MONGODB_PORT" --db "$MONGODB_DB" --out "$backup_dir" || {
      print_error "Failed to backup MongoDB database"
      log_message "ERROR" "Failed to backup MongoDB database"
      return 1
    }
    
    # Compress backup directory
    tar -czf "${backup_dir}.tar.gz" -C "$BACKUP_DIR" "mongodb_${ENV}_${timestamp}" || {
      print_error "Failed to compress backup directory"
      log_message "ERROR" "Failed to compress backup directory"
      return 1
    }
    
    # Remove uncompressed backup directory
    rm -rf "$backup_dir"
    
    print_success "MongoDB backup completed: ${backup_dir}.tar.gz"
    log_message "INFO" "MongoDB backup completed: ${backup_dir}.tar.gz"
    return 0
  }
  
  # Run backups based on database type
  if [ "$DB_TYPE" = "postgres" ] || [ "$DB_TYPE" = "all" ]; then
    backup_postgres_database
    postgres_status=$?
  fi
  
  if [ "$DB_TYPE" = "mongodb" ] || [ "$DB_TYPE" = "all" ]; then
    backup_mongodb_database
    mongodb_status=$?
  fi
  
  # Check backup status
  if [ "$DB_TYPE" = "all" ]; then
    if [ $postgres_status -eq 0 ] && [ $mongodb_status -eq 0 ]; then
      print_success "All database backups completed successfully"
      log_message "INFO" "All database backups completed successfully"
    else
      print_error "Some database backups failed"
      log_message "ERROR" "Some database backups failed"
      exit 1
    fi
  elif [ "$DB_TYPE" = "postgres" ] && [ $postgres_status -ne 0 ]; then
    print_error "PostgreSQL backup failed"
    log_message "ERROR" "PostgreSQL backup failed"
    exit 1
  elif [ "$DB_TYPE" = "mongodb" ] && [ $mongodb_status -ne 0 ]; then
    print_error "MongoDB backup failed"
    log_message "ERROR" "MongoDB backup failed"
    exit 1
  fi
fi

# --- Database Restore ---
if [ "$ACTION" = "restore" ]; then
  print_header "Restoring Database"
  
  if [ -z "$BACKUP_NAME" ]; then
    print_error "Backup name is required for restore action"
    log_message "ERROR" "Backup name is required for restore action"
    exit 1
  fi
  
  restore_postgres_database() {
    print_info "Restoring PostgreSQL database..."
    log_message "INFO" "Restoring PostgreSQL database"
    
    # Check if backup file exists
    local backup_file="$BACKUP_DIR/${BACKUP_NAME}.sql.gz"
    if [ ! -f "$backup_file" ]; then
      print_error "PostgreSQL backup file not found: $backup_file"
      log_message "ERROR" "PostgreSQL backup file not found: $backup_file"
      return 1
    fi
    
    # Uncompress backup file
    gunzip -c "$backup_file" > "${backup_file%.gz}" || {
      print_error "Failed to uncompress backup file"
      log_message "ERROR" "Failed to uncompress backup file"
      return 1
    }
    
    # Run restore command
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "${backup_file%.gz}" || {
      print_error "Failed to restore PostgreSQL database"
      log_message "ERROR" "Failed to restore PostgreSQL database"
      return 1
    }
    
    # Remove uncompressed backup file
    rm "${backup_file%.gz}"
    
    print_success "PostgreSQL restore completed"
    log_message "INFO" "PostgreSQL restore completed"
    return 0
  }
  
  restore_mongodb_database() {
    print_info "Restoring MongoDB database..."
    log_message "INFO" "Restoring MongoDB database"
    
    # Check if backup file exists
    local backup_file="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    if [ ! -f "$backup_file" ]; then
      print_error "MongoDB backup file not found: $backup_file"
      log_message "ERROR" "MongoDB backup file not found: $backup_file"
      return 1
    }
    
    # Create temporary directory for extraction
    local temp_dir="$BACKUP_DIR/temp_restore"
    mkdir -p "$temp_dir"
    
    # Extract backup file
    tar -xzf "$backup_file" -C "$temp_dir" || {
      print_error "Failed to extract backup file"
      log_message "ERROR" "Failed to extract backup file"
      rm -rf "$temp_dir"
      return 1
    }
    
    # Run restore command
    mongorestore --host "$MONGODB_HOST" --port "$MONGODB_PORT" --db "$MONGODB_DB" --drop "$temp_dir"/* || {
      print_error "Failed to restore MongoDB database"
      log_message "ERROR" "Failed to restore MongoDB database"
      rm -rf "$temp_dir"
      return 1
    }
    
    # Remove temporary directory
    rm -rf "$temp_dir"
    
    print_success "MongoDB restore completed"
    log_message "INFO" "MongoDB restore completed"
    return 0
  }
  
  # Run restore based on database type
  if [ "$DB_TYPE" = "postgres" ] || [ "$DB_TYPE" = "all" ]; then
    restore_postgres_database
    postgres_status=$?
  fi
  
  if [ "$DB_TYPE" = "mongodb" ] || [ "$DB_TYPE" = "all" ]; then
    restore_mongodb_database
    mongodb_status=$?
  fi
  
  # Check restore status
  if [ "$DB_TYPE" = "all" ]; then
    if [ $postgres_status -eq 0 ] && [ $mongodb_status -eq 0 ]; then
      print_success "All database restores completed successfully"
      log_message "INFO" "All database restores completed successfully"
    else
      print_error "Some database restores failed"
      log_message "ERROR" "Some database restores failed"
      exit 1
    fi
  elif [ "$DB_TYPE" = "postgres" ] && [ $postgres_status -ne 0 ]; then
    print_error "PostgreSQL restore failed"
    log_message "ERROR" "PostgreSQL restore failed"
    exit 1
  elif [ "$DB_TYPE" = "mongodb" ] && [ $mongodb_status -ne 0 ]; then
    print_error "MongoDB restore failed"
    log_message "ERROR" "MongoDB restore failed"
    exit 1
  fi
fi

# --- Database Health Check ---
if [ "$ACTION" = "health" ]; then
  print_header "Database Health Check"
  
  check_postgres_health() {
    print_info "Checking PostgreSQL health..."
    log_message "INFO" "Checking PostgreSQL health"
    
    # Run health check command
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1" > /dev/null || {
      print_error "PostgreSQL health check failed"
      log_message "ERROR" "PostgreSQL health check failed"
      return 1
    }
    
    # Check database size
    local db_size=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT pg_size_pretty(pg_database_size('$POSTGRES_DB'))")
    print_info "PostgreSQL database size: $db_size"
    log_message "INFO" "PostgreSQL database size: $db_size"
    
    # Check table count
    local table_count=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'")
    print_info "PostgreSQL table count: $table_count"
    log_message "INFO" "PostgreSQL table count: $table_count"
    
    # Check connection count
    local connection_count=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '$POSTGRES_DB'")
    print_info "PostgreSQL connection count: $connection_count"
    log_message "INFO" "PostgreSQL connection count: $connection_count"
    
    print_success "PostgreSQL health check completed"
    log_message "INFO" "PostgreSQL health check completed"
    return 0
  }
  
  check_mongodb_health() {
    print_info "Checking MongoDB health..."
    log_message "INFO" "Checking MongoDB health"
    
    # Run health check command
    mongo --host "$MONGODB_HOST" --port "$MONGODB_PORT" "$MONGODB_DB" --eval "db.stats()" > /dev/null || {
      print_error "MongoDB health check failed"
      log_message "ERROR" "MongoDB health check failed"
      return 1
    }
    
    # Check database stats
    local db_stats=$(mongo --host "$MONGODB_HOST" --port "$MONGODB_PORT" "$MONGODB_DB" --quiet --eval "JSON.stringify(db.stats())")
    print_info "MongoDB database stats: $db_stats"
    log_message "INFO" "MongoDB database stats: $db_stats"
    
    # Check collection count
    local collection_count=$(mongo --host "$MONGODB_HOST" --port "$MONGODB_PORT" "$MONGODB_DB" --quiet --eval "db.getCollectionNames().length")
    print_info "MongoDB collection count: $collection_count"
    log_message "INFO" "MongoDB collection count: $collection_count"
    
    print_success "MongoDB health check completed"
    log_message "INFO" "MongoDB health check completed"
    return 0
  }
  
  # Run health checks based on database type
  if [ "$DB_TYPE" = "postgres" ] || [ "$DB_TYPE" = "all" ]; then
    check_postgres_health
    postgres_status=$?
  fi
  
  if [ "$DB_TYPE" = "mongodb" ] || [ "$DB_TYPE" = "all" ]; then
    check_mongodb_health
    mongodb_status=$?
  fi
  
  # Check health check status
  if [ "$DB_TYPE" = "all" ]; then
    if [ $postgres_status -eq 0 ] && [ $mongodb_status -eq 0 ]; then
      print_success "All database health checks completed successfully"
      log_message "INFO" "All database health checks completed successfully"
    else
      print_error "Some database health checks failed"
      log_message "ERROR" "Some database health checks failed"
      exit 1
    fi
  elif [ "$DB_TYPE" = "postgres" ] && [ $postgres_status -ne 0 ]; then
    print_error "PostgreSQL health check failed"
    log_message "ERROR" "PostgreSQL health check failed"
    exit 1
  elif [ "$DB_TYPE" = "mongodb" ] && [ $mongodb_status -ne 0 ]; then
    print_error "MongoDB health check failed"
    log_message "ERROR" "MongoDB health check failed"
    exit 1
  fi
fi

# --- Summary ---
print_header "Database Management Summary"

print_success "Database management action '$ACTION' completed successfully!"
log_message "INFO" "Database management action '$ACTION' completed successfully"

if [ "$ACTION" = "backup" ]; then
  echo -e "\n${COLOR_GREEN}Backup Information:${COLOR_RESET}"
  echo -e "Backup Directory: ${COLOR_CYAN}$BACKUP_DIR${COLOR_RESET}"
  if [ "$DB_TYPE" = "postgres" ] || [ "$DB_TYPE" = "all" ]; then
    echo -e "PostgreSQL Backup: ${COLOR_CYAN}postgres_${ENV}_$(date "+%Y%m%d_%H%M%S").sql.gz${COLOR_RESET}"
  fi
  if [ "$DB_TYPE" = "mongodb" ] || [ "$DB_TYPE" = "all" ]; then
    echo -e "MongoDB Backup: ${COLOR_CYAN}mongodb_${ENV}_$(date "+%Y%m%d_%H%M%S").tar.gz${COLOR_RESET}"
  fi
fi

log_message "INFO" "Database management summary provided to user"

exit 0
