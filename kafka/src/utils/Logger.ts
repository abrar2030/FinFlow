import { createLogger, format, transports, Logger as WinstonLogger } from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';

/**
 * Enhanced Logger for financial services compliance
 * Provides structured logging with audit trail capabilities
 */
export class Logger {
  private logger: WinstonLogger;
  private context: string;

  constructor(context: string) {
    this.context = context;
    this.logger = this.createLogger();
  }

  private createLogger(): WinstonLogger {
    const logFormat = format.combine(
      format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss.SSS',
      }),
      format.errors({ stack: true }),
      format.json(),
      format.printf(({ timestamp, level, message, context, ...meta }) => {
        const logEntry = {
          timestamp,
          level: level.toUpperCase(),
          context: context || this.context,
          message,
          ...meta,
        };

        // Add correlation ID if available
        if (process.env.CORRELATION_ID) {
          logEntry.correlationId = process.env.CORRELATION_ID;
        }

        // Add session ID if available
        if (process.env.SESSION_ID) {
          logEntry.sessionId = process.env.SESSION_ID;
        }

        return JSON.stringify(logEntry);
      })
    );

    const logger = createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: logFormat,
      defaultMeta: {
        service: 'finflow-kafka',
        version: process.env.APP_VERSION || '1.0.0',
        environment: process.env.NODE_ENV || 'development',
      },
      transports: [
        // Console transport for development
        new transports.Console({
          format: format.combine(format.colorize(), format.simple()),
        }),

        // Application logs
        new DailyRotateFile({
          filename: '/var/log/kafka/application-%DATE%.log',
          datePattern: 'YYYY-MM-DD',
          maxSize: '100m',
          maxFiles: '30d',
          level: 'info',
        }),

        // Error logs
        new DailyRotateFile({
          filename: '/var/log/kafka/error-%DATE%.log',
          datePattern: 'YYYY-MM-DD',
          maxSize: '100m',
          maxFiles: '90d',
          level: 'error',
        }),

        // Audit logs for compliance
        new DailyRotateFile({
          filename: '/var/log/kafka/audit-%DATE%.log',
          datePattern: 'YYYY-MM-DD',
          maxSize: '100m',
          maxFiles: '2555d', // 7 years retention for financial compliance
          level: 'info',
          format: format.combine(format.timestamp(), format.json()),
        }),

        // Security logs
        new DailyRotateFile({
          filename: '/var/log/kafka/security-%DATE%.log',
          datePattern: 'YYYY-MM-DD',
          maxSize: '100m',
          maxFiles: '2555d', // 7 years retention
          level: 'warn',
        }),
      ],

      // Handle uncaught exceptions and rejections
      exceptionHandlers: [
        new DailyRotateFile({
          filename: '/var/log/kafka/exceptions-%DATE%.log',
          datePattern: 'YYYY-MM-DD',
          maxSize: '100m',
          maxFiles: '90d',
        }),
      ],

      rejectionHandlers: [
        new DailyRotateFile({
          filename: '/var/log/kafka/rejections-%DATE%.log',
          datePattern: 'YYYY-MM-DD',
          maxSize: '100m',
          maxFiles: '90d',
        }),
      ],
    });

    return logger;
  }

  /**
   * Log info level message
   */
  public info(message: string, meta?: any): void {
    this.logger.info(message, { context: this.context, ...meta });
  }

  /**
   * Log warning level message
   */
  public warn(message: string, meta?: any): void {
    this.logger.warn(message, { context: this.context, ...meta });
  }

  /**
   * Log error level message
   */
  public error(message: string, error?: Error | any, meta?: any): void {
    const errorMeta =
      error instanceof Error
        ? {
            error: {
              name: error.name,
              message: error.message,
              stack: error.stack,
            },
          }
        : { error };

    this.logger.error(message, {
      context: this.context,
      ...errorMeta,
      ...meta,
    });
  }

  /**
   * Log debug level message
   */
  public debug(message: string, meta?: any): void {
    this.logger.debug(message, { context: this.context, ...meta });
  }

  /**
   * Log audit event for compliance
   */
  public audit(event: AuditEvent): void {
    this.logger.info('AUDIT_EVENT', {
      context: 'AUDIT',
      eventType: event.eventType,
      userId: event.userId,
      resource: event.resource,
      action: event.action,
      result: event.result,
      timestamp: event.timestamp || new Date().toISOString(),
      details: event.details,
      sourceIp: event.sourceIp,
      userAgent: event.userAgent,
      sessionId: event.sessionId,
    });
  }

  /**
   * Log security event
   */
  public security(event: SecurityEvent): void {
    this.logger.warn('SECURITY_EVENT', {
      context: 'SECURITY',
      eventType: event.eventType,
      severity: event.severity,
      description: event.description,
      sourceIp: event.sourceIp,
      userId: event.userId,
      timestamp: event.timestamp || new Date().toISOString(),
      details: event.details,
    });
  }

  /**
   * Log performance metrics
   */
  public performance(metric: PerformanceMetric): void {
    this.logger.info('PERFORMANCE_METRIC', {
      context: 'PERFORMANCE',
      metricName: metric.name,
      value: metric.value,
      unit: metric.unit,
      timestamp: metric.timestamp || new Date().toISOString(),
      tags: metric.tags,
    });
  }

  /**
   * Log business event
   */
  public business(event: BusinessEvent): void {
    this.logger.info('BUSINESS_EVENT', {
      context: 'BUSINESS',
      eventType: event.eventType,
      entityType: event.entityType,
      entityId: event.entityId,
      action: event.action,
      timestamp: event.timestamp || new Date().toISOString(),
      metadata: event.metadata,
    });
  }

  /**
   * Create child logger with additional context
   */
  public child(additionalContext: string): Logger {
    const childLogger = new Logger(`${this.context}:${additionalContext}`);
    return childLogger;
  }

  /**
   * Set correlation ID for request tracing
   */
  public setCorrelationId(correlationId: string): void {
    process.env.CORRELATION_ID = correlationId;
  }

  /**
   * Set session ID for user session tracking
   */
  public setSessionId(sessionId: string): void {
    process.env.SESSION_ID = sessionId;
  }

  /**
   * Clear correlation and session IDs
   */
  public clearContext(): void {
    delete process.env.CORRELATION_ID;
    delete process.env.SESSION_ID;
  }
}

// Type definitions
export interface AuditEvent {
  eventType: string;
  userId?: string;
  resource: string;
  action: string;
  result: 'SUCCESS' | 'FAILURE' | 'PARTIAL';
  timestamp?: string;
  details?: any;
  sourceIp?: string;
  userAgent?: string;
  sessionId?: string;
}

export interface SecurityEvent {
  eventType: string;
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  description: string;
  sourceIp?: string;
  userId?: string;
  timestamp?: string;
  details?: any;
}

export interface PerformanceMetric {
  name: string;
  value: number;
  unit: string;
  timestamp?: string;
  tags?: Record<string, string>;
}

export interface BusinessEvent {
  eventType: string;
  entityType: string;
  entityId: string;
  action: string;
  timestamp?: string;
  metadata?: any;
}
