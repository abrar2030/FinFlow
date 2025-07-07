import { Producer, ProducerRecord, RecordMetadata } from 'kafkajs';
import { SecurityManager } from '../security/SecurityManager';
import { ComplianceManager } from '../compliance/ComplianceManager';
import { Logger } from '../utils/Logger';
import { EventEmitter } from 'events';

/**
 * SecureProducer implements financial industry standards for Kafka message production
 * Includes encryption, compliance validation, audit logging, and error handling
 */
export class SecureProducer extends EventEmitter {
  private producer: Producer;
  private securityManager: SecurityManager;
  private complianceManager: ComplianceManager;
  private logger: Logger;
  private isConnected: boolean = false;
  private messageBuffer: Map<string, BufferedMessage> = new Map();
  private retryQueue: RetryableMessage[] = [];

  constructor(
    producer: Producer,
    securityManager: SecurityManager,
    complianceManager: ComplianceManager
  ) {
    super();
    this.producer = producer;
    this.securityManager = securityManager;
    this.complianceManager = complianceManager;
    this.logger = new Logger('SecureProducer');
    
    this.setupEventHandlers();
    this.startRetryProcessor();
  }

  /**
   * Connect to Kafka cluster with security validation
   */
  public async connect(): Promise<void> {
    try {
      this.logger.info('Connecting to Kafka cluster');
      await this.producer.connect();
      this.isConnected = true;
      
      this.logger.audit({
        eventType: 'KAFKA_PRODUCER_CONNECTED',
        resource: 'kafka-cluster',
        action: 'CONNECT',
        result: 'SUCCESS'
      });

      this.emit('connected');
    } catch (error) {
      this.logger.error('Failed to connect to Kafka cluster', error);
      
      this.logger.security({
        eventType: 'KAFKA_CONNECTION_FAILED',
        severity: 'HIGH',
        description: 'Producer failed to connect to Kafka cluster',
        details: { error: error.message }
      });

      throw error;
    }
  }

  /**
   * Disconnect from Kafka cluster
   */
  public async disconnect(): Promise<void> {
    try {
      this.logger.info('Disconnecting from Kafka cluster');
      
      // Process any remaining buffered messages
      await this.flushBufferedMessages();
      
      await this.producer.disconnect();
      this.isConnected = false;
      
      this.logger.audit({
        eventType: 'KAFKA_PRODUCER_DISCONNECTED',
        resource: 'kafka-cluster',
        action: 'DISCONNECT',
        result: 'SUCCESS'
      });

      this.emit('disconnected');
    } catch (error) {
      this.logger.error('Failed to disconnect from Kafka cluster', error);
      throw error;
    }
  }

  /**
   * Send secure message with compliance validation
   */
  public async sendMessage(
    topic: string,
    message: any,
    options: SendMessageOptions = {}
  ): Promise<SendMessageResult> {
    const startTime = Date.now();
    const messageId = this.securityManager.generateSecureMessageId();
    
    try {
      // Validate connection
      if (!this.isConnected) {
        throw new Error('Producer not connected to Kafka cluster');
      }

      // Prepare message with metadata
      const enrichedMessage = this.enrichMessage(message, messageId, options);

      // Validate compliance
      const complianceResult = await this.complianceManager.validateMessageCompliance(
        topic, 
        enrichedMessage
      );

      if (!complianceResult.compliant && !options.bypassCompliance) {
        const error = new ComplianceError(
          'Message failed compliance validation',
          complianceResult.violations
        );
        
        this.logger.security({
          eventType: 'COMPLIANCE_VIOLATION',
          severity: 'HIGH',
          description: 'Message blocked due to compliance violations',
          details: {
            messageId,
            topic,
            violations: complianceResult.violations
          }
        });

        throw error;
      }

      // Encrypt sensitive data if required
      const processedMessage = await this.processMessageSecurity(
        topic, 
        enrichedMessage, 
        options
      );

      // Create producer record
      const producerRecord: ProducerRecord = {
        topic,
        messages: [{
          key: options.key || messageId,
          value: JSON.stringify(processedMessage),
          partition: options.partition,
          timestamp: options.timestamp || Date.now().toString(),
          headers: {
            messageId,
            contentType: 'application/json',
            encrypted: processedMessage.encrypted ? 'true' : 'false',
            complianceAuditId: complianceResult.auditId,
            ...options.headers
          }
        }]
      };

      // Send message with retry logic
      const metadata = await this.sendWithRetry(producerRecord, options);

      // Log successful send
      const duration = Date.now() - startTime;
      
      this.logger.performance({
        name: 'message_send_duration',
        value: duration,
        unit: 'milliseconds',
        tags: { topic, messageId }
      });

      this.logger.business({
        eventType: 'MESSAGE_SENT',
        entityType: 'kafka-message',
        entityId: messageId,
        action: 'SEND',
        metadata: {
          topic,
          partition: metadata[0].partition,
          offset: metadata[0].offset,
          duration
        }
      });

      return {
        messageId,
        metadata: metadata[0],
        complianceAuditId: complianceResult.auditId,
        encrypted: processedMessage.encrypted || false,
        warnings: complianceResult.warnings
      };

    } catch (error) {
      const duration = Date.now() - startTime;
      
      this.logger.error('Failed to send message', error, {
        messageId,
        topic,
        duration
      });

      // Add to retry queue if retryable
      if (this.isRetryableError(error) && options.enableRetry !== false) {
        this.addToRetryQueue({
          topic,
          message,
          options,
          messageId,
          attempts: 0,
          lastAttempt: Date.now(),
          error: error.message
        });
      }

      throw error;
    }
  }

  /**
   * Send multiple messages in a batch
   */
  public async sendBatch(
    topic: string,
    messages: any[],
    options: BatchSendOptions = {}
  ): Promise<BatchSendResult> {
    const batchId = this.securityManager.generateSecureMessageId();
    const startTime = Date.now();
    
    this.logger.info(`Sending batch of ${messages.length} messages`, {
      batchId,
      topic,
      messageCount: messages.length
    });

    const results: SendMessageResult[] = [];
    const errors: BatchError[] = [];

    try {
      // Process messages in parallel with concurrency limit
      const concurrency = options.concurrency || 10;
      const chunks = this.chunkArray(messages, concurrency);

      for (const chunk of chunks) {
        const chunkPromises = chunk.map(async (message, index) => {
          try {
            const result = await this.sendMessage(topic, message, {
              ...options,
              key: options.keyGenerator ? options.keyGenerator(message, index) : undefined
            });
            results.push(result);
          } catch (error) {
            errors.push({
              index,
              message,
              error: error.message
            });
          }
        });

        await Promise.all(chunkPromises);
      }

      const duration = Date.now() - startTime;
      
      this.logger.performance({
        name: 'batch_send_duration',
        value: duration,
        unit: 'milliseconds',
        tags: { 
          topic, 
          batchId, 
          messageCount: messages.length.toString(),
          successCount: results.length.toString(),
          errorCount: errors.length.toString()
        }
      });

      return {
        batchId,
        totalMessages: messages.length,
        successfulMessages: results.length,
        failedMessages: errors.length,
        results,
        errors,
        duration
      };

    } catch (error) {
      this.logger.error('Batch send failed', error, { batchId, topic });
      throw error;
    }
  }

  /**
   * Flush any buffered messages
   */
  public async flush(timeout?: number): Promise<void> {
    try {
      await this.producer.flush({ timeout });
      await this.flushBufferedMessages();
      
      this.logger.info('Producer flush completed');
    } catch (error) {
      this.logger.error('Producer flush failed', error);
      throw error;
    }
  }

  // Private methods
  private setupEventHandlers(): void {
    this.producer.on('producer.connect', () => {
      this.logger.info('Producer connected to Kafka');
    });

    this.producer.on('producer.disconnect', () => {
      this.logger.info('Producer disconnected from Kafka');
      this.isConnected = false;
    });

    this.producer.on('producer.network.request_timeout', (payload) => {
      this.logger.warn('Producer network request timeout', payload);
    });
  }

  private enrichMessage(
    message: any, 
    messageId: string, 
    options: SendMessageOptions
  ): any {
    return {
      ...message,
      messageId,
      timestamp: new Date().toISOString(),
      version: '1.0',
      source: options.source || 'finflow-kafka-producer',
      correlationId: options.correlationId || process.env.CORRELATION_ID,
      sessionId: options.sessionId || process.env.SESSION_ID,
      userId: options.userId,
      eventType: options.eventType || 'GENERIC_EVENT'
    };
  }

  private async processMessageSecurity(
    topic: string,
    message: any,
    options: SendMessageOptions
  ): Promise<any> {
    const sensitiveTopics = [
      'payment_completed',
      'invoice_paid',
      'user_registered',
      'kyc_data'
    ];

    if (sensitiveTopics.includes(topic) || options.forceEncryption) {
      const encryptedData = this.securityManager.encryptMessage(message);
      const signature = this.securityManager.signMessage(message);

      return {
        encrypted: true,
        data: encryptedData,
        signature,
        algorithm: 'aes-256-gcm',
        keyVersion: '1.0'
      };
    }

    // Add signature for data integrity
    const signature = this.securityManager.signMessage(message);
    return {
      ...message,
      signature
    };
  }

  private async sendWithRetry(
    record: ProducerRecord,
    options: SendMessageOptions
  ): Promise<RecordMetadata[]> {
    const maxRetries = options.maxRetries || 3;
    let lastError: Error;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await this.producer.send(record);
      } catch (error) {
        lastError = error;
        
        if (attempt < maxRetries && this.isRetryableError(error)) {
          const delay = this.calculateRetryDelay(attempt);
          this.logger.warn(`Send attempt ${attempt + 1} failed, retrying in ${delay}ms`, {
            error: error.message,
            topic: record.topic
          });
          
          await this.sleep(delay);
        }
      }
    }

    throw lastError;
  }

  private isRetryableError(error: any): boolean {
    const retryableErrors = [
      'NETWORK_EXCEPTION',
      'REQUEST_TIMED_OUT',
      'NOT_ENOUGH_REPLICAS',
      'NOT_ENOUGH_REPLICAS_AFTER_APPEND',
      'BROKER_NOT_AVAILABLE'
    ];

    return retryableErrors.some(retryableError => 
      error.message?.includes(retryableError) || error.code === retryableError
    );
  }

  private calculateRetryDelay(attempt: number): number {
    // Exponential backoff with jitter
    const baseDelay = 100;
    const maxDelay = 30000;
    const delay = Math.min(baseDelay * Math.pow(2, attempt), maxDelay);
    const jitter = Math.random() * 0.1 * delay;
    
    return Math.floor(delay + jitter);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private chunkArray<T>(array: T[], chunkSize: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += chunkSize) {
      chunks.push(array.slice(i, i + chunkSize));
    }
    return chunks;
  }

  private addToRetryQueue(message: RetryableMessage): void {
    this.retryQueue.push(message);
    this.logger.info('Message added to retry queue', {
      messageId: message.messageId,
      topic: message.topic
    });
  }

  private startRetryProcessor(): void {
    setInterval(async () => {
      if (this.retryQueue.length === 0) return;

      const now = Date.now();
      const retryableMessages = this.retryQueue.filter(msg => {
        const timeSinceLastAttempt = now - msg.lastAttempt;
        const shouldRetry = timeSinceLastAttempt > this.calculateRetryDelay(msg.attempts);
        return shouldRetry && msg.attempts < 5; // Max 5 retry attempts
      });

      for (const message of retryableMessages) {
        try {
          await this.sendMessage(message.topic, message.message, message.options);
          
          // Remove from retry queue on success
          const index = this.retryQueue.indexOf(message);
          if (index > -1) {
            this.retryQueue.splice(index, 1);
          }
          
          this.logger.info('Retry message sent successfully', {
            messageId: message.messageId,
            attempts: message.attempts + 1
          });
        } catch (error) {
          message.attempts++;
          message.lastAttempt = now;
          message.error = error.message;
          
          if (message.attempts >= 5) {
            // Remove from retry queue after max attempts
            const index = this.retryQueue.indexOf(message);
            if (index > -1) {
              this.retryQueue.splice(index, 1);
            }
            
            this.logger.error('Message retry failed after max attempts', error, {
              messageId: message.messageId,
              attempts: message.attempts
            });
          }
        }
      }
    }, 5000); // Check every 5 seconds
  }

  private async flushBufferedMessages(): Promise<void> {
    // Implementation for flushing any internally buffered messages
    // This would be used for batching optimizations
  }
}

// Type definitions and interfaces
export interface SendMessageOptions {
  key?: string;
  partition?: number;
  timestamp?: string;
  headers?: Record<string, string>;
  source?: string;
  correlationId?: string;
  sessionId?: string;
  userId?: string;
  eventType?: string;
  forceEncryption?: boolean;
  bypassCompliance?: boolean;
  enableRetry?: boolean;
  maxRetries?: number;
}

export interface SendMessageResult {
  messageId: string;
  metadata: RecordMetadata;
  complianceAuditId: string;
  encrypted: boolean;
  warnings?: string[];
}

export interface BatchSendOptions extends SendMessageOptions {
  concurrency?: number;
  keyGenerator?: (message: any, index: number) => string;
}

export interface BatchSendResult {
  batchId: string;
  totalMessages: number;
  successfulMessages: number;
  failedMessages: number;
  results: SendMessageResult[];
  errors: BatchError[];
  duration: number;
}

export interface BatchError {
  index: number;
  message: any;
  error: string;
}

interface BufferedMessage {
  topic: string;
  message: any;
  options: SendMessageOptions;
  timestamp: number;
}

interface RetryableMessage {
  topic: string;
  message: any;
  options: SendMessageOptions;
  messageId: string;
  attempts: number;
  lastAttempt: number;
  error: string;
}

export class ComplianceError extends Error {
  public violations: any[];

  constructor(message: string, violations: any[]) {
    super(message);
    this.name = 'ComplianceError';
    this.violations = violations;
  }
}

