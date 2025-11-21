/**
 * Enhanced Kafka Implementation for Financial Services
 *
 * This module provides a comprehensive, enterprise-grade Kafka implementation
 * specifically designed for financial services organizations with robust
 * security, compliance, and operational excellence features.
 *
 * @author FinFlow Development Team
 * @version 1.0.0
 * @license MIT
 */

// Core exports
export { SecurityManager } from './security/SecurityManager';
export { ComplianceManager } from './compliance/ComplianceManager';
export { Logger } from './utils/Logger';

// Producer exports
export {
  SecureProducer,
  SendMessageOptions,
  SendMessageResult,
  BatchSendOptions,
  BatchSendResult,
  BatchError,
  ComplianceError as ProducerComplianceError,
} from './producers/SecureProducer';

// Consumer exports
export {
  SecureConsumer,
  MessageHandler,
  MessageContext,
  SubscribeOptions,
  ConsumerRunOptions,
  ProcessingOptions,
  ProcessingMetrics,
  ConsumerMetrics,
  DeadLetterMessage,
  ComplianceError as ConsumerComplianceError,
} from './consumers/SecureConsumer';

// Utility exports
export { AuditEvent, SecurityEvent, PerformanceMetric, BusinessEvent } from './utils/Logger';

// Type definitions
export interface KafkaConfig {
  brokers: string[];
  clientId: string;
  ssl?: {
    rejectUnauthorized: boolean;
    ca?: string[];
    cert?: string;
    key?: string;
    passphrase?: string;
  };
  sasl?: {
    mechanism: string;
    username: string;
    password: string;
  };
  connectionTimeout?: number;
  authenticationTimeout?: number;
  reauthenticationThreshold?: number;
  retry?: {
    initialRetryTime: number;
    retries: number;
    maxRetryTime: number;
    factor: number;
    multiplier: number;
    restartOnFailure?: (error: Error) => Promise<boolean>;
  };
}

export interface TopicConfig {
  name: string;
  partitions: number;
  replicationFactor: number;
  configs?: Record<string, string>;
  security?: {
    encryptionRequired: boolean;
    piiData: boolean;
    financialData: boolean;
  };
  compliance?: {
    retentionRegulation: string;
    dataClassification: string;
  };
}

export interface EnhancedKafkaOptions {
  kafkaConfig: KafkaConfig;
  securityConfig?: {
    encryptionKey?: string;
    signingKey?: string;
    enableDataMasking?: boolean;
  };
  complianceConfig?: {
    enableGDPR?: boolean;
    enablePCIDSS?: boolean;
    enableSOX?: boolean;
    enableHIPAA?: boolean;
  };
  monitoringConfig?: {
    enableMetrics?: boolean;
    enableTracing?: boolean;
    enableAuditLogging?: boolean;
  };
}

/**
 * Enhanced Kafka Client Factory
 *
 * Creates configured instances of SecureProducer and SecureConsumer
 * with all security, compliance, and monitoring features enabled.
 */
export class EnhancedKafkaClient {
  private securityManager: SecurityManager;
  private complianceManager: ComplianceManager;
  private logger: Logger;
  private kafkaConfig: KafkaConfig;

  constructor(options: EnhancedKafkaOptions) {
    this.kafkaConfig = options.kafkaConfig;
    this.logger = new Logger('EnhancedKafkaClient');

    // Initialize security manager
    this.securityManager = new SecurityManager();

    // Initialize compliance manager
    this.complianceManager = new ComplianceManager(this.securityManager);

    this.logger.info('Enhanced Kafka client initialized', {
      clientId: options.kafkaConfig.clientId,
      brokers: options.kafkaConfig.brokers.length,
      securityEnabled: !!options.securityConfig,
      complianceEnabled: !!options.complianceConfig,
    });
  }

  /**
   * Create a secure producer instance
   */
  public createProducer(producerConfig?: any): SecureProducer {
    const { Kafka } = require('kafkajs');
    const kafka = new Kafka(this.kafkaConfig);
    const producer = kafka.producer(producerConfig);

    return new SecureProducer(producer, this.securityManager, this.complianceManager);
  }

  /**
   * Create a secure consumer instance
   */
  public createConsumer(groupId: string, consumerConfig?: any): SecureConsumer {
    const { Kafka } = require('kafkajs');
    const kafka = new Kafka(this.kafkaConfig);
    const consumer = kafka.consumer({ groupId, ...consumerConfig });

    return new SecureConsumer(consumer, this.securityManager, this.complianceManager);
  }

  /**
   * Get security manager instance
   */
  public getSecurityManager(): SecurityManager {
    return this.securityManager;
  }

  /**
   * Get compliance manager instance
   */
  public getComplianceManager(): ComplianceManager {
    return this.complianceManager;
  }

  /**
   * Get logger instance
   */
  public getLogger(): Logger {
    return this.logger;
  }

  /**
   * Create admin client for topic management
   */
  public createAdmin(adminConfig?: any): any {
    const { Kafka } = require('kafkajs');
    const kafka = new Kafka(this.kafkaConfig);
    return kafka.admin(adminConfig);
  }

  /**
   * Health check for the Kafka client
   */
  public async healthCheck(): Promise<{
    status: 'healthy' | 'unhealthy';
    details: Record<string, any>;
  }> {
    try {
      const admin = this.createAdmin();
      await admin.connect();

      const metadata = await admin.fetchTopicMetadata();
      await admin.disconnect();

      return {
        status: 'healthy',
        details: {
          brokers: this.kafkaConfig.brokers.length,
          topics: metadata.topics.length,
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      this.logger.error('Health check failed', error);

      return {
        status: 'unhealthy',
        details: {
          error: error.message,
          timestamp: new Date().toISOString(),
        },
      };
    }
  }
}

/**
 * Default export for convenience
 */
export default EnhancedKafkaClient;
