import { Consumer, EachMessagePayload, ConsumerSubscribeTopics, ConsumerRunConfig } from 'kafkajs';
import { SecurityManager } from '../security/SecurityManager';
import { ComplianceManager } from '../compliance/ComplianceManager';
import { Logger } from '../utils/Logger';
import { EventEmitter } from 'events';

/**
 * SecureConsumer implements financial industry standards for Kafka message consumption
 * Includes decryption, compliance validation, audit logging, and error handling
 */
export class SecureConsumer extends EventEmitter {
  private consumer: Consumer;
  private securityManager: SecurityManager;
  private complianceManager: ComplianceManager;
  private logger: Logger;
  private isConnected: boolean = false;
  private isRunning: boolean = false;
  private messageHandlers: Map<string, MessageHandler> = new Map();
  private deadLetterQueue: DeadLetterMessage[] = [];
  private processingMetrics: ProcessingMetrics = {
    totalProcessed: 0,
    successfullyProcessed: 0,
    failed: 0,
    averageProcessingTime: 0
  };

  constructor(
    consumer: Consumer,
    securityManager: SecurityManager,
    complianceManager: ComplianceManager
  ) {
    super();
    this.consumer = consumer;
    this.securityManager = securityManager;
    this.complianceManager = complianceManager;
    this.logger = new Logger('SecureConsumer');
    
    this.setupEventHandlers();
    this.startMetricsReporting();
  }

  /**
   * Connect to Kafka cluster
   */
  public async connect(): Promise<void> {
    try {
      this.logger.info('Connecting consumer to Kafka cluster');
      await this.consumer.connect();
      this.isConnected = true;
      
      this.logger.audit({
        eventType: 'KAFKA_CONSUMER_CONNECTED',
        resource: 'kafka-cluster',
        action: 'CONNECT',
        result: 'SUCCESS'
      });

      this.emit('connected');
    } catch (error) {
      this.logger.error('Failed to connect consumer to Kafka cluster', error);
      
      this.logger.security({
        eventType: 'KAFKA_CONNECTION_FAILED',
        severity: 'HIGH',
        description: 'Consumer failed to connect to Kafka cluster',
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
      this.logger.info('Disconnecting consumer from Kafka cluster');
      
      if (this.isRunning) {
        await this.stop();
      }
      
      await this.consumer.disconnect();
      this.isConnected = false;
      
      this.logger.audit({
        eventType: 'KAFKA_CONSUMER_DISCONNECTED',
        resource: 'kafka-cluster',
        action: 'DISCONNECT',
        result: 'SUCCESS'
      });

      this.emit('disconnected');
    } catch (error) {
      this.logger.error('Failed to disconnect consumer from Kafka cluster', error);
      throw error;
    }
  }

  /**
   * Subscribe to topics with message handlers
   */
  public async subscribe(
    topics: string | string[],
    handler: MessageHandler,
    options: SubscribeOptions = {}
  ): Promise<void> {
    try {
      if (!this.isConnected) {
        throw new Error('Consumer not connected to Kafka cluster');
      }

      const topicList = Array.isArray(topics) ? topics : [topics];
      
      // Register message handlers
      topicList.forEach(topic => {
        this.messageHandlers.set(topic, handler);
      });

      const subscribeTopics: ConsumerSubscribeTopics = {
        topics: topicList,
        fromBeginning: options.fromBeginning || false
      };

      await this.consumer.subscribe(subscribeTopics);
      
      this.logger.info('Subscribed to topics', { topics: topicList });
      
      this.logger.audit({
        eventType: 'KAFKA_TOPIC_SUBSCRIPTION',
        resource: 'kafka-topics',
        action: 'SUBSCRIBE',
        result: 'SUCCESS',
        details: { topics: topicList }
      });

    } catch (error) {
      this.logger.error('Failed to subscribe to topics', error, { topics });
      throw error;
    }
  }

  /**
   * Start consuming messages
   */
  public async run(options: ConsumerRunOptions = {}): Promise<void> {
    try {
      if (!this.isConnected) {
        throw new Error('Consumer not connected to Kafka cluster');
      }

      if (this.isRunning) {
        throw new Error('Consumer is already running');
      }

      this.logger.info('Starting message consumption');
      this.isRunning = true;

      const runConfig: ConsumerRunConfig = {
        autoCommit: options.autoCommit !== false,
        autoCommitInterval: options.autoCommitInterval || 5000,
        autoCommitThreshold: options.autoCommitThreshold || 100,
        eachMessage: this.createMessageProcessor(options),
        eachBatch: options.eachBatch
      };

      await this.consumer.run(runConfig);
      
      this.logger.audit({
        eventType: 'KAFKA_CONSUMER_STARTED',
        resource: 'kafka-consumer',
        action: 'START',
        result: 'SUCCESS'
      });

      this.emit('started');

    } catch (error) {
      this.isRunning = false;
      this.logger.error('Failed to start consumer', error);
      throw error;
    }
  }

  /**
   * Stop consuming messages
   */
  public async stop(): Promise<void> {
    try {
      if (!this.isRunning) {
        return;
      }

      this.logger.info('Stopping message consumption');
      await this.consumer.stop();
      this.isRunning = false;
      
      this.logger.audit({
        eventType: 'KAFKA_CONSUMER_STOPPED',
        resource: 'kafka-consumer',
        action: 'STOP',
        result: 'SUCCESS'
      });

      this.emit('stopped');

    } catch (error) {
      this.logger.error('Failed to stop consumer', error);
      throw error;
    }
  }

  /**
   * Commit current offsets
   */
  public async commitOffsets(offsets?: any[]): Promise<void> {
    try {
      await this.consumer.commitOffsets(offsets);
      this.logger.debug('Offsets committed successfully');
    } catch (error) {
      this.logger.error('Failed to commit offsets', error);
      throw error;
    }
  }

  /**
   * Get consumer metrics
   */
  public getMetrics(): ConsumerMetrics {
    return {
      isConnected: this.isConnected,
      isRunning: this.isRunning,
      subscribedTopics: Array.from(this.messageHandlers.keys()),
      processing: { ...this.processingMetrics },
      deadLetterQueueSize: this.deadLetterQueue.length
    };
  }

  /**
   * Get dead letter queue messages
   */
  public getDeadLetterQueue(): DeadLetterMessage[] {
    return [...this.deadLetterQueue];
  }

  /**
   * Retry dead letter queue message
   */
  public async retryDeadLetterMessage(messageId: string): Promise<void> {
    const dlqMessage = this.deadLetterQueue.find(msg => msg.messageId === messageId);
    if (!dlqMessage) {
      throw new Error(`Dead letter message not found: ${messageId}`);
    }

    try {
      const handler = this.messageHandlers.get(dlqMessage.topic);
      if (!handler) {
        throw new Error(`No handler found for topic: ${dlqMessage.topic}`);
      }

      await this.processMessage(dlqMessage.payload, handler, { isRetry: true });
      
      // Remove from dead letter queue on success
      const index = this.deadLetterQueue.indexOf(dlqMessage);
      if (index > -1) {
        this.deadLetterQueue.splice(index, 1);
      }

      this.logger.info('Dead letter message processed successfully', { messageId });

    } catch (error) {
      dlqMessage.retryCount++;
      dlqMessage.lastRetryAt = new Date().toISOString();
      dlqMessage.lastError = error.message;
      
      this.logger.error('Dead letter message retry failed', error, { messageId });
      throw error;
    }
  }

  // Private methods
  private setupEventHandlers(): void {
    this.consumer.on('consumer.connect', () => {
      this.logger.info('Consumer connected to Kafka');
    });

    this.consumer.on('consumer.disconnect', () => {
      this.logger.info('Consumer disconnected from Kafka');
      this.isConnected = false;
      this.isRunning = false;
    });

    this.consumer.on('consumer.stop', () => {
      this.logger.info('Consumer stopped');
      this.isRunning = false;
    });

    this.consumer.on('consumer.crash', (payload) => {
      this.logger.error('Consumer crashed', payload.error);
      this.isRunning = false;
      
      this.logger.security({
        eventType: 'KAFKA_CONSUMER_CRASH',
        severity: 'CRITICAL',
        description: 'Consumer crashed unexpectedly',
        details: payload
      });

      this.emit('crashed', payload);
    });

    this.consumer.on('consumer.network.request_timeout', (payload) => {
      this.logger.warn('Consumer network request timeout', payload);
    });
  }

  private createMessageProcessor(options: ConsumerRunOptions) {
    return async (payload: EachMessagePayload) => {
      const startTime = Date.now();
      let messageId: string = 'unknown';

      try {
        // Extract message metadata
        messageId = payload.message.headers?.messageId?.toString() || 'unknown';
        const topic = payload.topic;
        const partition = payload.partition;
        const offset = payload.message.offset;

        this.logger.debug('Processing message', {
          messageId,
          topic,
          partition,
          offset
        });

        // Get message handler
        const handler = this.messageHandlers.get(topic);
        if (!handler) {
          throw new Error(`No handler registered for topic: ${topic}`);
        }

        // Process the message
        await this.processMessage(payload, handler, options);

        // Update metrics
        const processingTime = Date.now() - startTime;
        this.updateProcessingMetrics(true, processingTime);

        this.logger.performance({
          name: 'message_processing_duration',
          value: processingTime,
          unit: 'milliseconds',
          tags: { topic, messageId, partition: partition.toString() }
        });

      } catch (error) {
        const processingTime = Date.now() - startTime;
        this.updateProcessingMetrics(false, processingTime);

        this.logger.error('Message processing failed', error, {
          messageId,
          topic: payload.topic,
          partition: payload.partition,
          offset: payload.message.offset
        });

        // Add to dead letter queue
        this.addToDeadLetterQueue(payload, error.message, messageId);

        // Don't rethrow error to prevent consumer from crashing
        // The message will be committed and moved to DLQ
      }
    };
  }

  private async processMessage(
    payload: EachMessagePayload,
    handler: MessageHandler,
    options: ProcessingOptions = {}
  ): Promise<void> {
    const messageValue = payload.message.value?.toString();
    if (!messageValue) {
      throw new Error('Message value is empty');
    }

    let parsedMessage: any;
    let decryptedMessage: any;

    try {
      // Parse message
      parsedMessage = JSON.parse(messageValue);

      // Decrypt if encrypted
      if (parsedMessage.encrypted) {
        decryptedMessage = this.securityManager.decryptMessage(parsedMessage.data);
        
        // Verify signature
        if (parsedMessage.signature) {
          const signatureValid = this.securityManager.verifyMessageSignature(
            decryptedMessage,
            parsedMessage.signature
          );
          
          if (!signatureValid) {
            throw new Error('Message signature verification failed');
          }
        }
      } else {
        decryptedMessage = parsedMessage;
        
        // Verify signature for non-encrypted messages
        if (parsedMessage.signature) {
          const { signature, ...messageData } = parsedMessage;
          const signatureValid = this.securityManager.verifyMessageSignature(
            messageData,
            signature
          );
          
          if (!signatureValid) {
            throw new Error('Message signature verification failed');
          }
          
          decryptedMessage = messageData;
        }
      }

      // Validate compliance (if not a retry)
      if (!options.isRetry) {
        const complianceResult = await this.complianceManager.validateMessageCompliance(
          payload.topic,
          decryptedMessage
        );

        if (!complianceResult.compliant) {
          this.logger.security({
            eventType: 'COMPLIANCE_VIOLATION_CONSUMPTION',
            severity: 'HIGH',
            description: 'Message consumption blocked due to compliance violations',
            details: {
              messageId: decryptedMessage.messageId,
              topic: payload.topic,
              violations: complianceResult.violations
            }
          });

          throw new ComplianceError(
            'Message failed compliance validation during consumption',
            complianceResult.violations
          );
        }
      }

      // Create processing context
      const context: MessageContext = {
        topic: payload.topic,
        partition: payload.partition,
        offset: payload.message.offset,
        timestamp: payload.message.timestamp,
        headers: payload.message.headers,
        messageId: decryptedMessage.messageId || 'unknown',
        correlationId: decryptedMessage.correlationId,
        sessionId: decryptedMessage.sessionId,
        userId: decryptedMessage.userId,
        isRetry: options.isRetry || false
      };

      // Call message handler
      await handler(decryptedMessage, context);

      // Log successful processing
      this.logger.business({
        eventType: 'MESSAGE_PROCESSED',
        entityType: 'kafka-message',
        entityId: context.messageId,
        action: 'PROCESS',
        metadata: {
          topic: payload.topic,
          partition: payload.partition,
          offset: payload.message.offset,
          isRetry: options.isRetry
        }
      });

    } catch (error) {
      // Log processing error
      this.logger.error('Message processing error', error, {
        messageId: parsedMessage?.messageId || 'unknown',
        topic: payload.topic
      });

      throw error;
    }
  }

  private addToDeadLetterQueue(
    payload: EachMessagePayload,
    error: string,
    messageId: string
  ): void {
    const dlqMessage: DeadLetterMessage = {
      messageId,
      topic: payload.topic,
      partition: payload.partition,
      offset: payload.message.offset,
      payload,
      error,
      timestamp: new Date().toISOString(),
      retryCount: 0,
      lastRetryAt: null,
      lastError: error
    };

    this.deadLetterQueue.push(dlqMessage);
    
    // Limit DLQ size to prevent memory issues
    if (this.deadLetterQueue.length > 10000) {
      this.deadLetterQueue.shift(); // Remove oldest message
    }

    this.logger.warn('Message added to dead letter queue', {
      messageId,
      topic: payload.topic,
      error
    });

    this.emit('deadLetter', dlqMessage);
  }

  private updateProcessingMetrics(success: boolean, processingTime: number): void {
    this.processingMetrics.totalProcessed++;
    
    if (success) {
      this.processingMetrics.successfullyProcessed++;
    } else {
      this.processingMetrics.failed++;
    }

    // Update average processing time (simple moving average)
    const totalTime = this.processingMetrics.averageProcessingTime * (this.processingMetrics.totalProcessed - 1);
    this.processingMetrics.averageProcessingTime = (totalTime + processingTime) / this.processingMetrics.totalProcessed;
  }

  private startMetricsReporting(): void {
    setInterval(() => {
      if (this.processingMetrics.totalProcessed > 0) {
        this.logger.performance({
          name: 'consumer_processing_rate',
          value: this.processingMetrics.successfullyProcessed,
          unit: 'messages',
          tags: { 
            consumer_group: this.consumer.groupId,
            success_rate: (this.processingMetrics.successfullyProcessed / this.processingMetrics.totalProcessed * 100).toFixed(2)
          }
        });

        this.logger.performance({
          name: 'consumer_error_rate',
          value: this.processingMetrics.failed,
          unit: 'messages',
          tags: { 
            consumer_group: this.consumer.groupId,
            error_rate: (this.processingMetrics.failed / this.processingMetrics.totalProcessed * 100).toFixed(2)
          }
        });
      }
    }, 60000); // Report every minute
  }
}

// Type definitions
export type MessageHandler = (message: any, context: MessageContext) => Promise<void>;

export interface MessageContext {
  topic: string;
  partition: number;
  offset: string;
  timestamp: string;
  headers: any;
  messageId: string;
  correlationId?: string;
  sessionId?: string;
  userId?: string;
  isRetry: boolean;
}

export interface SubscribeOptions {
  fromBeginning?: boolean;
}

export interface ConsumerRunOptions {
  autoCommit?: boolean;
  autoCommitInterval?: number;
  autoCommitThreshold?: number;
  eachBatch?: any;
}

export interface ProcessingOptions {
  isRetry?: boolean;
}

export interface ProcessingMetrics {
  totalProcessed: number;
  successfullyProcessed: number;
  failed: number;
  averageProcessingTime: number;
}

export interface ConsumerMetrics {
  isConnected: boolean;
  isRunning: boolean;
  subscribedTopics: string[];
  processing: ProcessingMetrics;
  deadLetterQueueSize: number;
}

export interface DeadLetterMessage {
  messageId: string;
  topic: string;
  partition: number;
  offset: string;
  payload: EachMessagePayload;
  error: string;
  timestamp: string;
  retryCount: number;
  lastRetryAt: string | null;
  lastError: string;
}

export class ComplianceError extends Error {
  public violations: any[];

  constructor(message: string, violations: any[]) {
    super(message);
    this.name = 'ComplianceError';
    this.violations = violations;
  }
}

