import fs from "fs";
import path from "path";
import { logger } from "../utils/logger";

/**
 * Utility for audit logging
 * Logs security-relevant events to both the application log and a dedicated audit log file
 */

// Define audit log types
export interface AuditLogEntry {
  timestamp: string;
  action: string;
  userId?: string;
  resourceType: string;
  resourceId?: string;
  metadata?: Record<string, any>;
}

// Path to audit log file
const AUDIT_LOG_PATH =
  process.env.AUDIT_LOG_PATH || path.join(__dirname, "../../logs/audit.log");

// Ensure log directory exists
const logDir = path.dirname(AUDIT_LOG_PATH);
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

/**
 * Log an audit event
 * @param entry Audit log entry details
 */
export const auditLog = async (
  entry: Omit<AuditLogEntry, "timestamp">,
): Promise<void> => {
  try {
    const timestamp = new Date().toISOString();

    const logEntry: AuditLogEntry = {
      timestamp,
      ...entry,
    };

    // Log to application logger
    logger.info(`AUDIT: ${JSON.stringify(logEntry)}`);

    // Write to dedicated audit log file
    fs.appendFileSync(AUDIT_LOG_PATH, JSON.stringify(logEntry) + "\n", {
      encoding: "utf8",
    });
  } catch (error) {
    logger.error(`Error writing to audit log: ${error}`);
    // Don't throw error, just log it
  }
};

/**
 * Get audit logs for a specific user
 * @param userId User ID to filter logs by
 * @param startDate Optional start date for filtering
 * @param endDate Optional end date for filtering
 * @returns Array of audit log entries
 */
export const getUserAuditLogs = (
  userId: string,
  startDate?: Date,
  endDate?: Date,
): AuditLogEntry[] => {
  try {
    // Read audit log file
    const logContent = fs.readFileSync(AUDIT_LOG_PATH, "utf8");

    // Parse log entries
    const logEntries: AuditLogEntry[] = logContent
      .split("\n")
      .filter((line) => line.trim() !== "")
      .map((line) => JSON.parse(line))
      .filter((entry) => entry.userId === userId);

    // Apply date filtering if provided
    if (startDate || endDate) {
      return logEntries.filter((entry) => {
        const entryDate = new Date(entry.timestamp);

        if (startDate && entryDate < startDate) {
          return false;
        }

        if (endDate && entryDate > endDate) {
          return false;
        }

        return true;
      });
    }

    return logEntries;
  } catch (error) {
    logger.error(`Error reading audit logs: ${error}`);
    return [];
  }
};

/**
 * Get audit logs for a specific resource
 * @param resourceType Resource type to filter logs by
 * @param resourceId Optional resource ID to filter logs by
 * @param startDate Optional start date for filtering
 * @param endDate Optional end date for filtering
 * @returns Array of audit log entries
 */
export const getResourceAuditLogs = (
  resourceType: string,
  resourceId?: string,
  startDate?: Date,
  endDate?: Date,
): AuditLogEntry[] => {
  try {
    // Read audit log file
    const logContent = fs.readFileSync(AUDIT_LOG_PATH, "utf8");

    // Parse log entries
    const logEntries: AuditLogEntry[] = logContent
      .split("\n")
      .filter((line) => line.trim() !== "")
      .map((line) => JSON.parse(line))
      .filter((entry) => {
        if (entry.resourceType !== resourceType) {
          return false;
        }

        if (resourceId && entry.resourceId !== resourceId) {
          return false;
        }

        return true;
      });

    // Apply date filtering if provided
    if (startDate || endDate) {
      return logEntries.filter((entry) => {
        const entryDate = new Date(entry.timestamp);

        if (startDate && entryDate < startDate) {
          return false;
        }

        if (endDate && entryDate > endDate) {
          return false;
        }

        return true;
      });
    }

    return logEntries;
  } catch (error) {
    logger.error(`Error reading audit logs: ${error}`);
    return [];
  }
};
