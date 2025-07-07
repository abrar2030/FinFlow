import crypto from 'crypto';
import { KafkaConfig, SASLOptions } from 'kafkajs';
import { Logger } from '../utils/Logger';

/**
 * SecurityManager handles all security-related operations for Kafka
 * Implements financial industry security standards and best practices
 */
export class SecurityManager {
  private logger: Logger;
  private encryptionKey: Buffer;
  private signingKey: Buffer;

  constructor() {
    this.logger = new Logger('SecurityManager');
    this.initializeKeys();
  }

  /**
   * Initialize encryption and signing keys from environment variables
   */
  private initializeKeys(): void {
    const encryptionKeyHex = process.env.KAFKA_ENCRYPTION_KEY;
    const signingKeyHex = process.env.KAFKA_SIGNING_KEY;

    if (!encryptionKeyHex || !signingKeyHex) {
      throw new Error('Encryption and signing keys must be provided via environment variables');
    }

    this.encryptionKey = Buffer.from(encryptionKeyHex, 'hex');
    this.signingKey = Buffer.from(signingKeyHex, 'hex');

    if (this.encryptionKey.length !== 32) {
      throw new Error('Encryption key must be 256 bits (32 bytes)');
    }

    if (this.signingKey.length !== 32) {
      throw new Error('Signing key must be 256 bits (32 bytes)');
    }
  }

  /**
   * Get secure Kafka configuration with SSL/SASL
   */
  public getSecureKafkaConfig(): KafkaConfig {
    const brokers = (process.env.KAFKA_BROKERS || 'localhost:9094').split(',');
    
    const saslConfig: SASLOptions = {
      mechanism: 'scram-sha-512',
      username: process.env.KAFKA_USERNAME || '',
      password: process.env.KAFKA_PASSWORD || ''
    };

    const sslConfig = {
      rejectUnauthorized: true,
      ca: process.env.KAFKA_SSL_CA ? [process.env.KAFKA_SSL_CA] : undefined,
      cert: process.env.KAFKA_SSL_CERT,
      key: process.env.KAFKA_SSL_KEY,
      passphrase: process.env.KAFKA_SSL_PASSPHRASE
    };

    return {
      clientId: process.env.KAFKA_CLIENT_ID || 'finflow-secure-client',
      brokers,
      ssl: sslConfig,
      sasl: saslConfig,
      connectionTimeout: 10000,
      authenticationTimeout: 10000,
      reauthenticationThreshold: 10000,
      retry: {
        initialRetryTime: 100,
        retries: 8,
        maxRetryTime: 30000,
        factor: 2,
        multiplier: 2,
        restartOnFailure: async (e) => {
          this.logger.error('Kafka connection failed, restarting', e);
          return true;
        }
      }
    };
  }

  /**
   * Encrypt sensitive message data using AES-256-GCM
   */
  public encryptMessage(data: any): string {
    try {
      const plaintext = JSON.stringify(data);
      const iv = crypto.randomBytes(16);
      const cipher = crypto.createCipher('aes-256-gcm', this.encryptionKey);
      cipher.setAAD(Buffer.from('finflow-kafka-message'));

      let encrypted = cipher.update(plaintext, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      const authTag = cipher.getAuthTag();
      
      const result = {
        iv: iv.toString('hex'),
        encrypted,
        authTag: authTag.toString('hex'),
        algorithm: 'aes-256-gcm'
      };

      return Buffer.from(JSON.stringify(result)).toString('base64');
    } catch (error) {
      this.logger.error('Failed to encrypt message', error);
      throw new Error('Message encryption failed');
    }
  }

  /**
   * Decrypt message data
   */
  public decryptMessage(encryptedData: string): any {
    try {
      const data = JSON.parse(Buffer.from(encryptedData, 'base64').toString());
      const { iv, encrypted, authTag, algorithm } = data;

      if (algorithm !== 'aes-256-gcm') {
        throw new Error('Unsupported encryption algorithm');
      }

      const decipher = crypto.createDecipher('aes-256-gcm', this.encryptionKey);
      decipher.setAAD(Buffer.from('finflow-kafka-message'));
      decipher.setAuthTag(Buffer.from(authTag, 'hex'));

      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      return JSON.parse(decrypted);
    } catch (error) {
      this.logger.error('Failed to decrypt message', error);
      throw new Error('Message decryption failed');
    }
  }

  /**
   * Sign message for integrity verification
   */
  public signMessage(message: any): string {
    const messageString = JSON.stringify(message);
    const hmac = crypto.createHmac('sha256', this.signingKey);
    hmac.update(messageString);
    return hmac.digest('hex');
  }

  /**
   * Verify message signature
   */
  public verifyMessageSignature(message: any, signature: string): boolean {
    const expectedSignature = this.signMessage(message);
    return crypto.timingSafeEqual(
      Buffer.from(signature, 'hex'),
      Buffer.from(expectedSignature, 'hex')
    );
  }

  /**
   * Mask sensitive data for logging and non-production environments
   */
  public maskSensitiveData(data: any): any {
    const sensitiveFields = [
      'ssn', 'socialSecurityNumber',
      'creditCardNumber', 'cardNumber',
      'bankAccountNumber', 'accountNumber',
      'routingNumber',
      'email', 'emailAddress',
      'phoneNumber', 'phone',
      'password', 'pin',
      'taxId', 'ein'
    ];

    const masked = JSON.parse(JSON.stringify(data));

    const maskValue = (obj: any, path: string[] = []): void => {
      for (const key in obj) {
        if (obj.hasOwnProperty(key)) {
          const currentPath = [...path, key];
          
          if (sensitiveFields.some(field => 
            key.toLowerCase().includes(field.toLowerCase())
          )) {
            obj[key] = this.maskString(String(obj[key]));
          } else if (typeof obj[key] === 'object' && obj[key] !== null) {
            maskValue(obj[key], currentPath);
          }
        }
      }
    };

    maskValue(masked);
    return masked;
  }

  /**
   * Mask string value while preserving format
   */
  private maskString(value: string): string {
    if (value.length <= 4) {
      return '*'.repeat(value.length);
    }
    
    const visibleChars = 2;
    const maskedLength = value.length - (visibleChars * 2);
    
    return value.substring(0, visibleChars) + 
           '*'.repeat(maskedLength) + 
           value.substring(value.length - visibleChars);
  }

  /**
   * Generate secure message ID
   */
  public generateSecureMessageId(): string {
    const timestamp = Date.now().toString();
    const randomBytes = crypto.randomBytes(8).toString('hex');
    const hash = crypto.createHash('sha256')
      .update(timestamp + randomBytes)
      .digest('hex')
      .substring(0, 16);
    
    return `${timestamp}-${hash}`;
  }

  /**
   * Validate message structure and content
   */
  public validateMessage(message: any): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    // Check required fields
    if (!message.messageId) {
      errors.push('Message ID is required');
    }

    if (!message.timestamp) {
      errors.push('Timestamp is required');
    }

    if (!message.eventType) {
      errors.push('Event type is required');
    }

    // Validate timestamp
    if (message.timestamp) {
      const messageTime = new Date(message.timestamp).getTime();
      const currentTime = Date.now();
      const timeDiff = Math.abs(currentTime - messageTime);
      
      // Message should not be older than 1 hour or in the future
      if (timeDiff > 3600000 || messageTime > currentTime + 60000) {
        errors.push('Message timestamp is invalid');
      }
    }

    // Check message size (max 1MB)
    const messageSize = Buffer.byteLength(JSON.stringify(message), 'utf8');
    if (messageSize > 1048576) {
      errors.push('Message size exceeds maximum limit (1MB)');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  /**
   * Create audit log entry for security events
   */
  public createAuditLogEntry(event: {
    eventType: string;
    userId?: string;
    resource: string;
    action: string;
    result: 'SUCCESS' | 'FAILURE';
    details?: any;
  }): any {
    return {
      auditId: this.generateSecureMessageId(),
      timestamp: new Date().toISOString(),
      eventType: event.eventType,
      userId: event.userId || 'system',
      resource: event.resource,
      action: event.action,
      result: event.result,
      details: event.details ? this.maskSensitiveData(event.details) : undefined,
      sourceIp: process.env.NODE_ENV === 'production' ? 'masked' : '127.0.0.1',
      userAgent: 'kafka-client',
      sessionId: crypto.randomBytes(16).toString('hex')
    };
  }
}

