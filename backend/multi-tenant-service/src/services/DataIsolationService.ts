import { EventEmitter } from "events";
import { Pool, PoolClient } from "pg";
import Redis from "ioredis";
import winston from "winston";
import { createObjectCsvWriter } from "csv-writer";
import archiver from "archiver";
import { Readable } from "stream";

import { logger } from "../config/logger";
import { getDatabase } from "../config/database";
import { getRedis } from "../config/redis";
import {
  DataIsolationStrategy,
  TenantDataAccess,
  BulkOperation,
  DataExportOptions,
  DataValidationRule,
  DataEncryption,
} from "../types/isolation";

export class DataIsolationService extends EventEmitter {
  private db: Pool;
  private redis: Redis;
  private isInitialized: boolean = false;

  // Data isolation strategies
  private isolationStrategies: Map<string, DataIsolationStrategy> = new Map();

  // Tenant-specific database connections (for database-per-tenant)
  private tenantDatabases: Map<string, Pool> = new Map();

  // Data validation rules
  private validationRules: Map<string, DataValidationRule[]> = new Map();

  constructor() {
    super();
  }

  async initialize(): Promise<void> {
    try {
      logger.info("Initializing Data Isolation Service...");

      this.db = await getDatabase();
      this.redis = await getRedis();

      // Load isolation strategies
      await this.loadIsolationStrategies();

      // Initialize tenant databases
      await this.initializeTenantDatabases();

      // Setup data validation rules
      await this.setupValidationRules();

      // Create isolation tables
      await this.createIsolationTables();

      this.isInitialized = true;
      logger.info("Data Isolation Service initialized successfully");
    } catch (error) {
      logger.error("Failed to initialize Data Isolation Service:", error);
      throw error;
    }
  }

  private async loadIsolationStrategies(): Promise<void> {
    try {
      // Schema-based isolation (default)
      this.isolationStrategies.set("schema", {
        type: "schema",
        description: "Each tenant gets their own database schema",
        implementation: "schema_per_tenant",
        security_level: "high",
        performance_impact: "low",
        complexity: "medium",
      });

      // Database-based isolation (highest security)
      this.isolationStrategies.set("database", {
        type: "database",
        description: "Each tenant gets their own database",
        implementation: "database_per_tenant",
        security_level: "highest",
        performance_impact: "medium",
        complexity: "high",
      });

      // Row-level isolation (shared tables)
      this.isolationStrategies.set("row", {
        type: "row",
        description: "Shared tables with tenant_id column",
        implementation: "row_level_security",
        security_level: "medium",
        performance_impact: "low",
        complexity: "low",
      });

      logger.info("Data isolation strategies loaded");
    } catch (error) {
      logger.error("Error loading isolation strategies:", error);
      throw error;
    }
  }

  private async initializeTenantDatabases(): Promise<void> {
    try {
      // Get all tenants with database isolation
      const result = await this.db.query(`
        SELECT t.id, t.slug, td.database_name, td.connection_string
        FROM tenants t
        JOIN tenant_databases td ON t.id = td.tenant_id
        WHERE td.isolation_type = 'database' AND td.status = 'active'
      `);

      for (const row of result.rows) {
        try {
          const pool = new Pool({
            connectionString: row.connection_string,
            max: 5, // Smaller pool per tenant
            idleTimeoutMillis: 30000,
            connectionTimeoutMillis: 2000,
          });

          this.tenantDatabases.set(row.id, pool);
          logger.info(
            `Initialized database connection for tenant: ${row.slug}`,
          );
        } catch (error) {
          logger.error(
            `Failed to initialize database for tenant ${row.slug}:`,
            error,
          );
        }
      }
    } catch (error) {
      logger.error("Error initializing tenant databases:", error);
    }
  }

  private async setupValidationRules(): Promise<void> {
    try {
      // Define validation rules for different resource types
      const transactionRules: DataValidationRule[] = [
        {
          field: "amount",
          type: "number",
          required: true,
          min: 0.01,
          max: 1000000,
        },
        {
          field: "currency",
          type: "string",
          required: true,
          pattern: "^[A-Z]{3}$",
        },
        {
          field: "user_id",
          type: "uuid",
          required: true,
        },
      ];

      const userRules: DataValidationRule[] = [
        {
          field: "email",
          type: "email",
          required: true,
          unique: true,
        },
        {
          field: "first_name",
          type: "string",
          required: true,
          minLength: 1,
          maxLength: 100,
        },
        {
          field: "last_name",
          type: "string",
          required: true,
          minLength: 1,
          maxLength: 100,
        },
      ];

      this.validationRules.set("transactions", transactionRules);
      this.validationRules.set("users", userRules);

      logger.info("Data validation rules setup complete");
    } catch (error) {
      logger.error("Error setting up validation rules:", error);
    }
  }

  private async createIsolationTables(): Promise<void> {
    try {
      // Data access log table
      await this.db.query(`
        CREATE TABLE IF NOT EXISTS tenant_data_access_log (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          tenant_id UUID NOT NULL,
          user_id UUID,
          resource_type VARCHAR(100) NOT NULL,
          resource_id VARCHAR(255),
          action VARCHAR(50) NOT NULL,
          ip_address INET,
          user_agent TEXT,
          timestamp TIMESTAMP DEFAULT NOW(),
          metadata JSONB DEFAULT '{}',
          isolation_strategy VARCHAR(50),
          data_hash VARCHAR(255)
        )
      `);

      // Data encryption keys table
      await this.db.query(`
        CREATE TABLE IF NOT EXISTS tenant_encryption_keys (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          tenant_id UUID NOT NULL,
          key_name VARCHAR(100) NOT NULL,
          encrypted_key TEXT NOT NULL,
          algorithm VARCHAR(50) DEFAULT 'AES-256-GCM',
          created_at TIMESTAMP DEFAULT NOW(),
          expires_at TIMESTAMP,
          status VARCHAR(50) DEFAULT 'active',
          UNIQUE(tenant_id, key_name)
        )
      `);

      // Data backup metadata table
      await this.db.query(`
        CREATE TABLE IF NOT EXISTS tenant_data_backups (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          tenant_id UUID NOT NULL,
          backup_type VARCHAR(50) NOT NULL,
          file_path TEXT NOT NULL,
          file_size BIGINT,
          checksum VARCHAR(255),
          created_at TIMESTAMP DEFAULT NOW(),
          expires_at TIMESTAMP,
          status VARCHAR(50) DEFAULT 'active',
          metadata JSONB DEFAULT '{}'
        )
      `);

      // Create indexes
      await this.db.query(`
        CREATE INDEX IF NOT EXISTS idx_tenant_data_access_log_tenant_id ON tenant_data_access_log(tenant_id);
        CREATE INDEX IF NOT EXISTS idx_tenant_data_access_log_timestamp ON tenant_data_access_log(timestamp);
        CREATE INDEX IF NOT EXISTS idx_tenant_encryption_keys_tenant_id ON tenant_encryption_keys(tenant_id);
        CREATE INDEX IF NOT EXISTS idx_tenant_data_backups_tenant_id ON tenant_data_backups(tenant_id);
      `);

      logger.info("Data isolation tables created successfully");
    } catch (error) {
      logger.error("Error creating isolation tables:", error);
      throw error;
    }
  }

  async getData(
    tenantId: string,
    resource: string,
    filters: any = {},
    options: any = {},
  ): Promise<any[]> {
    if (!this.isInitialized) {
      throw new Error("Data Isolation Service not initialized");
    }

    try {
      // Log data access
      await this.logDataAccess(
        tenantId,
        options.userId,
        resource,
        null,
        "read",
        options,
      );

      // Get tenant isolation strategy
      const strategy = await this.getTenantIsolationStrategy(tenantId);

      // Apply data isolation based on strategy
      let data: any[];

      switch (strategy) {
        case "database":
          data = await this.getDataFromTenantDatabase(
            tenantId,
            resource,
            filters,
            options,
          );
          break;
        case "schema":
          data = await this.getDataFromTenantSchema(
            tenantId,
            resource,
            filters,
            options,
          );
          break;
        case "row":
        default:
          data = await this.getDataWithRowLevelSecurity(
            tenantId,
            resource,
            filters,
            options,
          );
          break;
      }

      // Apply data masking/encryption if needed
      data = await this.applyDataMasking(tenantId, resource, data, options);

      // Cache frequently accessed data
      if (options.cache !== false) {
        await this.cacheData(tenantId, resource, filters, data);
      }

      return data;
    } catch (error) {
      logger.error("Error getting data:", error);
      throw error;
    }
  }

  async createData(
    tenantId: string,
    resource: string,
    data: any,
    options: any = {},
  ): Promise<any> {
    if (!this.isInitialized) {
      throw new Error("Data Isolation Service not initialized");
    }

    try {
      // Validate data
      await this.validateData(resource, data);

      // Encrypt sensitive fields
      data = await this.encryptSensitiveData(tenantId, resource, data);

      // Get tenant isolation strategy
      const strategy = await this.getTenantIsolationStrategy(tenantId);

      let result: any;

      switch (strategy) {
        case "database":
          result = await this.createDataInTenantDatabase(
            tenantId,
            resource,
            data,
            options,
          );
          break;
        case "schema":
          result = await this.createDataInTenantSchema(
            tenantId,
            resource,
            data,
            options,
          );
          break;
        case "row":
        default:
          result = await this.createDataWithRowLevelSecurity(
            tenantId,
            resource,
            data,
            options,
          );
          break;
      }

      // Log data access
      await this.logDataAccess(
        tenantId,
        options.userId,
        resource,
        result.id,
        "create",
        options,
      );

      // Clear related cache
      await this.clearDataCache(tenantId, resource);

      // Emit data created event
      this.emit("data:created", {
        tenantId,
        resource,
        data: result,
        userId: options.userId,
      });

      return result;
    } catch (error) {
      logger.error("Error creating data:", error);
      throw error;
    }
  }

  async updateData(
    tenantId: string,
    resource: string,
    id: string,
    data: any,
    options: any = {},
  ): Promise<any> {
    if (!this.isInitialized) {
      throw new Error("Data Isolation Service not initialized");
    }

    try {
      // Validate data
      await this.validateData(resource, data, true);

      // Encrypt sensitive fields
      data = await this.encryptSensitiveData(tenantId, resource, data);

      // Get tenant isolation strategy
      const strategy = await this.getTenantIsolationStrategy(tenantId);

      let result: any;

      switch (strategy) {
        case "database":
          result = await this.updateDataInTenantDatabase(
            tenantId,
            resource,
            id,
            data,
            options,
          );
          break;
        case "schema":
          result = await this.updateDataInTenantSchema(
            tenantId,
            resource,
            id,
            data,
            options,
          );
          break;
        case "row":
        default:
          result = await this.updateDataWithRowLevelSecurity(
            tenantId,
            resource,
            id,
            data,
            options,
          );
          break;
      }

      // Log data access
      await this.logDataAccess(
        tenantId,
        options.userId,
        resource,
        id,
        "update",
        options,
      );

      // Clear related cache
      await this.clearDataCache(tenantId, resource);

      // Emit data updated event
      this.emit("data:updated", {
        tenantId,
        resource,
        id,
        data: result,
        userId: options.userId,
      });

      return result;
    } catch (error) {
      logger.error("Error updating data:", error);
      throw error;
    }
  }

  async deleteData(
    tenantId: string,
    resource: string,
    id: string,
    options: any = {},
  ): Promise<void> {
    if (!this.isInitialized) {
      throw new Error("Data Isolation Service not initialized");
    }

    try {
      // Get tenant isolation strategy
      const strategy = await this.getTenantIsolationStrategy(tenantId);

      switch (strategy) {
        case "database":
          await this.deleteDataFromTenantDatabase(
            tenantId,
            resource,
            id,
            options,
          );
          break;
        case "schema":
          await this.deleteDataFromTenantSchema(
            tenantId,
            resource,
            id,
            options,
          );
          break;
        case "row":
        default:
          await this.deleteDataWithRowLevelSecurity(
            tenantId,
            resource,
            id,
            options,
          );
          break;
      }

      // Log data access
      await this.logDataAccess(
        tenantId,
        options.userId,
        resource,
        id,
        "delete",
        options,
      );

      // Clear related cache
      await this.clearDataCache(tenantId, resource);

      // Emit data deleted event
      this.emit("data:deleted", {
        tenantId,
        resource,
        id,
        userId: options.userId,
      });
    } catch (error) {
      logger.error("Error deleting data:", error);
      throw error;
    }
  }

  async bulkOperations(
    tenantId: string,
    resource: string,
    operations: BulkOperation[],
    options: any = {},
  ): Promise<any[]> {
    if (!this.isInitialized) {
      throw new Error("Data Isolation Service not initialized");
    }

    const results: any[] = [];
    const client = await this.getClientForTenant(tenantId);

    try {
      await client.query("BEGIN");

      for (const operation of operations) {
        try {
          let result: any;

          switch (operation.type) {
            case "create":
              result = await this.createData(
                tenantId,
                resource,
                operation.data,
                { ...options, client },
              );
              break;
            case "update":
              result = await this.updateData(
                tenantId,
                resource,
                operation.id!,
                operation.data,
                { ...options, client },
              );
              break;
            case "delete":
              await this.deleteData(tenantId, resource, operation.id!, {
                ...options,
                client,
              });
              result = { id: operation.id, deleted: true };
              break;
            default:
              throw new Error(`Unknown operation type: ${operation.type}`);
          }

          results.push({
            operation,
            result,
            success: true,
          });
        } catch (error) {
          results.push({
            operation,
            error: error.message,
            success: false,
          });
        }
      }

      await client.query("COMMIT");

      // Log bulk operation
      await this.logDataAccess(
        tenantId,
        options.userId,
        resource,
        null,
        "bulk",
        {
          ...options,
          operationCount: operations.length,
          successCount: results.filter((r) => r.success).length,
        },
      );

      return results;
    } catch (error) {
      await client.query("ROLLBACK");
      logger.error("Error in bulk operations:", error);
      throw error;
    } finally {
      if (client !== this.db) {
        client.release();
      }
    }
  }

  async exportData(
    tenantId: string,
    resource: string,
    format: string = "json",
    options: DataExportOptions = {},
  ): Promise<string | Buffer> {
    if (!this.isInitialized) {
      throw new Error("Data Isolation Service not initialized");
    }

    try {
      // Get data with filters
      const data = await this.getData(
        tenantId,
        resource,
        options.filters || {},
        options,
      );

      // Apply data masking for export
      const maskedData = await this.applyDataMasking(tenantId, resource, data, {
        ...options,
        export: true,
      });

      let exportData: string | Buffer;

      switch (format.toLowerCase()) {
        case "csv":
          exportData = await this.exportToCSV(maskedData, options);
          break;
        case "json":
          exportData = JSON.stringify(maskedData, null, 2);
          break;
        case "zip":
          exportData = await this.exportToZip(
            tenantId,
            resource,
            maskedData,
            options,
          );
          break;
        default:
          throw new Error(`Unsupported export format: ${format}`);
      }

      // Log export
      await this.logDataAccess(
        tenantId,
        options.userId,
        resource,
        null,
        "export",
        {
          ...options,
          format,
          recordCount: maskedData.length,
        },
      );

      // Store backup metadata
      await this.storeBackupMetadata(
        tenantId,
        resource,
        format,
        exportData,
        options,
      );

      return exportData;
    } catch (error) {
      logger.error("Error exporting data:", error);
      throw error;
    }
  }

  private async getTenantIsolationStrategy(tenantId: string): Promise<string> {
    try {
      // Check cache first
      const cached = await this.redis.get(`tenant:isolation:${tenantId}`);
      if (cached) {
        return cached;
      }

      // Query database
      const result = await this.db.query(
        `
        SELECT td.isolation_type
        FROM tenant_databases td
        WHERE td.tenant_id = $1 AND td.status = 'active'
        LIMIT 1
      `,
        [tenantId],
      );

      const strategy =
        result.rows.length > 0 ? result.rows[0].isolation_type : "row";

      // Cache for future use
      await this.redis.setex(`tenant:isolation:${tenantId}`, 3600, strategy);

      return strategy;
    } catch (error) {
      logger.error("Error getting tenant isolation strategy:", error);
      return "row"; // Default to row-level security
    }
  }

  private async getClientForTenant(tenantId: string): Promise<PoolClient> {
    const strategy = await this.getTenantIsolationStrategy(tenantId);

    if (strategy === "database") {
      const tenantPool = this.tenantDatabases.get(tenantId);
      if (tenantPool) {
        return await tenantPool.connect();
      }
    }

    return await this.db.connect();
  }

  private async getDataFromTenantDatabase(
    tenantId: string,
    resource: string,
    filters: any,
    options: any,
  ): Promise<any[]> {
    const client = await this.getClientForTenant(tenantId);

    try {
      const { query, values } = this.buildSelectQuery(
        resource,
        filters,
        options,
      );
      const result = await client.query(query, values);
      return result.rows;
    } finally {
      client.release();
    }
  }

  private async getDataFromTenantSchema(
    tenantId: string,
    resource: string,
    filters: any,
    options: any,
  ): Promise<any[]> {
    const client = await this.db.connect();

    try {
      // Get tenant schema name
      const schemaName = `tenant_${tenantId.replace(/-/g, "_")}`;

      const { query, values } = this.buildSelectQuery(
        resource,
        filters,
        options,
        schemaName,
      );
      const result = await client.query(query, values);
      return result.rows;
    } finally {
      client.release();
    }
  }

  private async getDataWithRowLevelSecurity(
    tenantId: string,
    resource: string,
    filters: any,
    options: any,
  ): Promise<any[]> {
    const client = await this.db.connect();

    try {
      // Add tenant_id filter
      const tenantFilters = { ...filters, tenant_id: tenantId };

      const { query, values } = this.buildSelectQuery(
        resource,
        tenantFilters,
        options,
      );
      const result = await client.query(query, values);
      return result.rows;
    } finally {
      client.release();
    }
  }

  private async createDataInTenantDatabase(
    tenantId: string,
    resource: string,
    data: any,
    options: any,
  ): Promise<any> {
    const client = options.client || (await this.getClientForTenant(tenantId));

    try {
      const { query, values } = this.buildInsertQuery(resource, data);
      const result = await client.query(query, values);
      return result.rows[0];
    } finally {
      if (!options.client && client !== this.db) {
        client.release();
      }
    }
  }

  private async createDataInTenantSchema(
    tenantId: string,
    resource: string,
    data: any,
    options: any,
  ): Promise<any> {
    const client = options.client || (await this.db.connect());

    try {
      const schemaName = `tenant_${tenantId.replace(/-/g, "_")}`;
      const { query, values } = this.buildInsertQuery(
        resource,
        data,
        schemaName,
      );
      const result = await client.query(query, values);
      return result.rows[0];
    } finally {
      if (!options.client) {
        client.release();
      }
    }
  }

  private async createDataWithRowLevelSecurity(
    tenantId: string,
    resource: string,
    data: any,
    options: any,
  ): Promise<any> {
    const client = options.client || (await this.db.connect());

    try {
      // Add tenant_id to data
      const tenantData = { ...data, tenant_id: tenantId };

      const { query, values } = this.buildInsertQuery(resource, tenantData);
      const result = await client.query(query, values);
      return result.rows[0];
    } finally {
      if (!options.client) {
        client.release();
      }
    }
  }

  private async updateDataInTenantDatabase(
    tenantId: string,
    resource: string,
    id: string,
    data: any,
    options: any,
  ): Promise<any> {
    const client = options.client || (await this.getClientForTenant(tenantId));

    try {
      const { query, values } = this.buildUpdateQuery(resource, id, data);
      const result = await client.query(query, values);

      if (result.rows.length === 0) {
        throw new Error(`${resource} with id ${id} not found`);
      }

      return result.rows[0];
    } finally {
      if (!options.client && client !== this.db) {
        client.release();
      }
    }
  }

  private async updateDataInTenantSchema(
    tenantId: string,
    resource: string,
    id: string,
    data: any,
    options: any,
  ): Promise<any> {
    const client = options.client || (await this.db.connect());

    try {
      const schemaName = `tenant_${tenantId.replace(/-/g, "_")}`;
      const { query, values } = this.buildUpdateQuery(
        resource,
        id,
        data,
        schemaName,
      );
      const result = await client.query(query, values);

      if (result.rows.length === 0) {
        throw new Error(`${resource} with id ${id} not found`);
      }

      return result.rows[0];
    } finally {
      if (!options.client) {
        client.release();
      }
    }
  }

  private async updateDataWithRowLevelSecurity(
    tenantId: string,
    resource: string,
    id: string,
    data: any,
    options: any,
  ): Promise<any> {
    const client = options.client || (await this.db.connect());

    try {
      const { query, values } = this.buildUpdateQuery(
        resource,
        id,
        data,
        null,
        tenantId,
      );
      const result = await client.query(query, values);

      if (result.rows.length === 0) {
        throw new Error(`${resource} with id ${id} not found or access denied`);
      }

      return result.rows[0];
    } finally {
      if (!options.client) {
        client.release();
      }
    }
  }

  private async deleteDataFromTenantDatabase(
    tenantId: string,
    resource: string,
    id: string,
    options: any,
  ): Promise<void> {
    const client = options.client || (await this.getClientForTenant(tenantId));

    try {
      const query = `DELETE FROM ${resource} WHERE id = $1`;
      const result = await client.query(query, [id]);

      if (result.rowCount === 0) {
        throw new Error(`${resource} with id ${id} not found`);
      }
    } finally {
      if (!options.client && client !== this.db) {
        client.release();
      }
    }
  }

  private async deleteDataFromTenantSchema(
    tenantId: string,
    resource: string,
    id: string,
    options: any,
  ): Promise<void> {
    const client = options.client || (await this.db.connect());

    try {
      const schemaName = `tenant_${tenantId.replace(/-/g, "_")}`;
      const query = `DELETE FROM ${schemaName}.${resource} WHERE id = $1`;
      const result = await client.query(query, [id]);

      if (result.rowCount === 0) {
        throw new Error(`${resource} with id ${id} not found`);
      }
    } finally {
      if (!options.client) {
        client.release();
      }
    }
  }

  private async deleteDataWithRowLevelSecurity(
    tenantId: string,
    resource: string,
    id: string,
    options: any,
  ): Promise<void> {
    const client = options.client || (await this.db.connect());

    try {
      const query = `DELETE FROM ${resource} WHERE id = $1 AND tenant_id = $2`;
      const result = await client.query(query, [id, tenantId]);

      if (result.rowCount === 0) {
        throw new Error(`${resource} with id ${id} not found or access denied`);
      }
    } finally {
      if (!options.client) {
        client.release();
      }
    }
  }

  private buildSelectQuery(
    resource: string,
    filters: any,
    options: any,
    schema?: string,
  ): { query: string; values: any[] } {
    const tableName = schema ? `${schema}.${resource}` : resource;
    let query = `SELECT * FROM ${tableName}`;
    const values: any[] = [];
    const conditions: string[] = [];
    let paramIndex = 1;

    // Build WHERE conditions
    for (const [key, value] of Object.entries(filters)) {
      if (value !== undefined && value !== null) {
        conditions.push(`${key} = $${paramIndex++}`);
        values.push(value);
      }
    }

    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(" AND ")}`;
    }

    // Add ordering
    if (options.orderBy) {
      query += ` ORDER BY ${options.orderBy}`;
      if (options.orderDirection) {
        query += ` ${options.orderDirection}`;
      }
    }

    // Add pagination
    if (options.limit) {
      query += ` LIMIT $${paramIndex++}`;
      values.push(options.limit);
    }

    if (options.offset) {
      query += ` OFFSET $${paramIndex++}`;
      values.push(options.offset);
    }

    return { query, values };
  }

  private buildInsertQuery(
    resource: string,
    data: any,
    schema?: string,
  ): { query: string; values: any[] } {
    const tableName = schema ? `${schema}.${resource}` : resource;
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = columns.map((_, index) => `$${index + 1}`);

    const query = `
      INSERT INTO ${tableName} (${columns.join(", ")})
      VALUES (${placeholders.join(", ")})
      RETURNING *
    `;

    return { query, values };
  }

  private buildUpdateQuery(
    resource: string,
    id: string,
    data: any,
    schema?: string,
    tenantId?: string,
  ): { query: string; values: any[] } {
    const tableName = schema ? `${schema}.${resource}` : resource;
    const columns = Object.keys(data);
    const values = Object.values(data);
    const setClause = columns.map((col, index) => `${col} = $${index + 2}`);

    let query = `
      UPDATE ${tableName}
      SET ${setClause.join(", ")}, updated_at = NOW()
      WHERE id = $1
    `;

    const queryValues = [id, ...values];

    // Add tenant isolation for row-level security
    if (tenantId) {
      query += ` AND tenant_id = $${queryValues.length + 1}`;
      queryValues.push(tenantId);
    }

    query += " RETURNING *";

    return { query, values: queryValues };
  }

  private async validateData(
    resource: string,
    data: any,
    isUpdate: boolean = false,
  ): Promise<void> {
    const rules = this.validationRules.get(resource);
    if (!rules) return;

    for (const rule of rules) {
      const value = data[rule.field];

      // Check required fields
      if (
        rule.required &&
        !isUpdate &&
        (value === undefined || value === null)
      ) {
        throw new Error(`Field ${rule.field} is required`);
      }

      if (value !== undefined && value !== null) {
        // Type validation
        switch (rule.type) {
          case "string":
            if (typeof value !== "string") {
              throw new Error(`Field ${rule.field} must be a string`);
            }
            if (rule.minLength && value.length < rule.minLength) {
              throw new Error(
                `Field ${rule.field} must be at least ${rule.minLength} characters`,
              );
            }
            if (rule.maxLength && value.length > rule.maxLength) {
              throw new Error(
                `Field ${rule.field} must be at most ${rule.maxLength} characters`,
              );
            }
            if (rule.pattern && !new RegExp(rule.pattern).test(value)) {
              throw new Error(`Field ${rule.field} format is invalid`);
            }
            break;

          case "number":
            if (typeof value !== "number") {
              throw new Error(`Field ${rule.field} must be a number`);
            }
            if (rule.min !== undefined && value < rule.min) {
              throw new Error(
                `Field ${rule.field} must be at least ${rule.min}`,
              );
            }
            if (rule.max !== undefined && value > rule.max) {
              throw new Error(
                `Field ${rule.field} must be at most ${rule.max}`,
              );
            }
            break;

          case "email":
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(value)) {
              throw new Error(
                `Field ${rule.field} must be a valid email address`,
              );
            }
            break;

          case "uuid":
            const uuidRegex =
              /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
            if (!uuidRegex.test(value)) {
              throw new Error(`Field ${rule.field} must be a valid UUID`);
            }
            break;
        }
      }
    }
  }

  private async encryptSensitiveData(
    tenantId: string,
    resource: string,
    data: any,
  ): Promise<any> {
    // Define sensitive fields that need encryption
    const sensitiveFields = {
      users: ["ssn", "tax_id", "bank_account"],
      transactions: ["account_number", "routing_number"],
      payments: ["card_number", "cvv"],
    };

    const fieldsToEncrypt = sensitiveFields[resource] || [];
    if (fieldsToEncrypt.length === 0) return data;

    const encryptedData = { ...data };

    for (const field of fieldsToEncrypt) {
      if (encryptedData[field]) {
        // In a real implementation, use proper encryption
        encryptedData[field] =
          `encrypted:${Buffer.from(encryptedData[field]).toString("base64")}`;
      }
    }

    return encryptedData;
  }

  private async applyDataMasking(
    tenantId: string,
    resource: string,
    data: any[],
    options: any,
  ): Promise<any[]> {
    // Define fields that need masking for different contexts
    const maskingRules = {
      users: {
        export: ["ssn", "tax_id"],
        api: ["password_hash"],
      },
      transactions: {
        export: ["account_number"],
        api: [],
      },
    };

    const rules = maskingRules[resource];
    if (!rules) return data;

    const fieldsToMask = rules[options.export ? "export" : "api"] || [];
    if (fieldsToMask.length === 0) return data;

    return data.map((item) => {
      const maskedItem = { ...item };

      for (const field of fieldsToMask) {
        if (maskedItem[field]) {
          maskedItem[field] = "***MASKED***";
        }
      }

      return maskedItem;
    });
  }

  private async exportToCSV(
    data: any[],
    options: DataExportOptions,
  ): Promise<string> {
    if (data.length === 0) return "";

    const headers = Object.keys(data[0]);
    let csv = headers.join(",") + "\n";

    for (const row of data) {
      const values = headers.map((header) => {
        const value = row[header];
        if (value === null || value === undefined) return "";
        if (typeof value === "string" && value.includes(",")) {
          return `"${value.replace(/"/g, '""')}"`;
        }
        return value;
      });
      csv += values.join(",") + "\n";
    }

    return csv;
  }

  private async exportToZip(
    tenantId: string,
    resource: string,
    data: any[],
    options: DataExportOptions,
  ): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const archive = archiver("zip", { zlib: { level: 9 } });
      const chunks: Buffer[] = [];

      archive.on("data", (chunk) => chunks.push(chunk));
      archive.on("end", () => resolve(Buffer.concat(chunks)));
      archive.on("error", reject);

      // Add JSON file
      const jsonData = JSON.stringify(data, null, 2);
      archive.append(jsonData, { name: `${resource}.json` });

      // Add CSV file
      const csvData = await this.exportToCSV(data, options);
      archive.append(csvData, { name: `${resource}.csv` });

      // Add metadata file
      const metadata = {
        tenantId,
        resource,
        exportDate: new Date().toISOString(),
        recordCount: data.length,
        format: "zip",
      };
      archive.append(JSON.stringify(metadata, null, 2), {
        name: "metadata.json",
      });

      archive.finalize();
    });
  }

  private async cacheData(
    tenantId: string,
    resource: string,
    filters: any,
    data: any[],
  ): Promise<void> {
    try {
      const cacheKey = `data:${tenantId}:${resource}:${JSON.stringify(filters)}`;
      await this.redis.setex(cacheKey, 300, JSON.stringify(data)); // Cache for 5 minutes
    } catch (error) {
      logger.warning("Failed to cache data:", error);
    }
  }

  private async clearDataCache(
    tenantId: string,
    resource: string,
  ): Promise<void> {
    try {
      const pattern = `data:${tenantId}:${resource}:*`;
      const keys = await this.redis.keys(pattern);

      if (keys.length > 0) {
        await this.redis.del(...keys);
      }
    } catch (error) {
      logger.warning("Failed to clear data cache:", error);
    }
  }

  private async logDataAccess(
    tenantId: string,
    userId: string | undefined,
    resource: string,
    resourceId: string | null,
    action: string,
    options: any,
  ): Promise<void> {
    try {
      await this.db.query(
        `
        INSERT INTO tenant_data_access_log (
          tenant_id, user_id, resource_type, resource_id, action,
          ip_address, user_agent, metadata, isolation_strategy
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      `,
        [
          tenantId,
          userId,
          resource,
          resourceId,
          action,
          options.ip,
          options.userAgent,
          JSON.stringify(options.metadata || {}),
          await this.getTenantIsolationStrategy(tenantId),
        ],
      );
    } catch (error) {
      logger.error("Error logging data access:", error);
    }
  }

  private async storeBackupMetadata(
    tenantId: string,
    resource: string,
    format: string,
    data: string | Buffer,
    options: DataExportOptions,
  ): Promise<void> {
    try {
      const fileSize = Buffer.isBuffer(data)
        ? data.length
        : Buffer.byteLength(data);
      const checksum = require("crypto")
        .createHash("sha256")
        .update(data)
        .digest("hex");

      await this.db.query(
        `
        INSERT INTO tenant_data_backups (
          tenant_id, backup_type, file_path, file_size, checksum, metadata
        ) VALUES ($1, $2, $3, $4, $5, $6)
      `,
        [
          tenantId,
          format,
          `exports/${tenantId}/${resource}_${Date.now()}.${format}`,
          fileSize,
          checksum,
          JSON.stringify({ resource, options }),
        ],
      );
    } catch (error) {
      logger.error("Error storing backup metadata:", error);
    }
  }

  async cleanup(): Promise<void> {
    try {
      logger.info("Cleaning up Data Isolation Service...");

      // Close tenant database connections
      for (const [tenantId, pool] of this.tenantDatabases) {
        try {
          await pool.end();
          logger.info(`Closed database connection for tenant: ${tenantId}`);
        } catch (error) {
          logger.error(`Error closing database for tenant ${tenantId}:`, error);
        }
      }

      this.tenantDatabases.clear();
    } catch (error) {
      logger.error("Error during cleanup:", error);
    }
  }
}
