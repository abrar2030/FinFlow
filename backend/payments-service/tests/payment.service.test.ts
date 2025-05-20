import { describe, expect, test, jest, beforeEach } from '@jest/globals';
import paymentService from '../src/payment.service';
import { PaymentProcessorFactory } from '../src/factories/payment-processor.factory';
import { PaymentProcessorInterface } from '../src/interfaces/payment-processor.interface';
import { PaymentStatus, ProcessorType } from '../src/payment.types';
import { logger } from '../../common/logger';

// Mock dependencies
jest.mock('../src/factories/payment-processor.factory');
jest.mock('../../common/logger');

describe('PaymentService', () => {
  // Mock payment processor
  const mockProcessor: jest.Mocked<PaymentProcessorInterface> = {
    processPayment: jest.fn(),
    refundPayment: jest.fn(),
    getPaymentStatus: jest.fn(),
    validatePaymentDetails: jest.fn()
  };

  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
    
    // Default mock implementation for factory
    (PaymentProcessorFactory.getProcessor as jest.Mock).mockReturnValue(mockProcessor);
  });

  describe('processPayment', () => {
    test('should process payment successfully', async () => {
      // Arrange
      const paymentDetails = {
        amount: 100.00,
        currency: 'USD',
        source: 'card_token_123',
        description: 'Test payment',
        metadata: {
          orderId: 'order_123'
        },
        processorType: ProcessorType.STRIPE
      };

      const processorResponse = {
        id: 'payment_123',
        status: PaymentStatus.COMPLETED,
        processorId: 'ch_123456',
        amount: paymentDetails.amount,
        currency: paymentDetails.currency,
        createdAt: new Date()
      };

      mockProcessor.processPayment.mockResolvedValue(processorResponse);
      mockProcessor.validatePaymentDetails.mockReturnValue(true);

      // Act
      const result = await paymentService.processPayment(paymentDetails);

      // Assert
      expect(PaymentProcessorFactory.getProcessor).toHaveBeenCalledWith(ProcessorType.STRIPE);
      expect(mockProcessor.validatePaymentDetails).toHaveBeenCalledWith(paymentDetails);
      expect(mockProcessor.processPayment).toHaveBeenCalledWith(paymentDetails);
      expect(result).toEqual(processorResponse);
    });

    test('should throw error when payment details are invalid', async () => {
      // Arrange
      const paymentDetails = {
        amount: -100.00, // Invalid amount
        currency: 'USD',
        source: 'card_token_123',
        description: 'Test payment',
        metadata: {
          orderId: 'order_123'
        },
        processorType: ProcessorType.STRIPE
      };

      mockProcessor.validatePaymentDetails.mockReturnValue(false);

      // Act & Assert
      await expect(paymentService.processPayment(paymentDetails)).rejects.toThrow('Invalid payment details');
      expect(mockProcessor.processPayment).not.toHaveBeenCalled();
    });

    test('should throw error when processor type is invalid', async () => {
      // Arrange
      const paymentDetails = {
        amount: 100.00,
        currency: 'USD',
        source: 'card_token_123',
        description: 'Test payment',
        metadata: {
          orderId: 'order_123'
        },
        processorType: 'INVALID_PROCESSOR' as ProcessorType
      };

      (PaymentProcessorFactory.getProcessor as jest.Mock).mockImplementation(() => {
        throw new Error('Invalid processor type');
      });

      // Act & Assert
      await expect(paymentService.processPayment(paymentDetails)).rejects.toThrow('Invalid processor type');
      expect(mockProcessor.processPayment).not.toHaveBeenCalled();
    });

    test('should handle processor errors during payment processing', async () => {
      // Arrange
      const paymentDetails = {
        amount: 100.00,
        currency: 'USD',
        source: 'card_token_123',
        description: 'Test payment',
        metadata: {
          orderId: 'order_123'
        },
        processorType: ProcessorType.STRIPE
      };

      const processorError = new Error('Payment processor error');
      mockProcessor.validatePaymentDetails.mockReturnValue(true);
      mockProcessor.processPayment.mockRejectedValue(processorError);

      // Act & Assert
      await expect(paymentService.processPayment(paymentDetails)).rejects.toThrow('Payment processor error');
      expect(logger.error).toHaveBeenCalled();
    });
  });

  describe('refundPayment', () => {
    test('should refund payment successfully', async () => {
      // Arrange
      const refundDetails = {
        paymentId: 'payment_123',
        amount: 100.00,
        reason: 'Customer requested',
        processorType: ProcessorType.STRIPE,
        processorPaymentId: 'ch_123456'
      };

      const refundResponse = {
        id: 'refund_123',
        paymentId: refundDetails.paymentId,
        amount: refundDetails.amount,
        status: 'completed',
        processorId: 're_123456',
        createdAt: new Date()
      };

      mockProcessor.refundPayment.mockResolvedValue(refundResponse);

      // Act
      const result = await paymentService.refundPayment(refundDetails);

      // Assert
      expect(PaymentProcessorFactory.getProcessor).toHaveBeenCalledWith(ProcessorType.STRIPE);
      expect(mockProcessor.refundPayment).toHaveBeenCalledWith(refundDetails);
      expect(result).toEqual(refundResponse);
    });

    test('should throw error when refund fails', async () => {
      // Arrange
      const refundDetails = {
        paymentId: 'payment_123',
        amount: 100.00,
        reason: 'Customer requested',
        processorType: ProcessorType.STRIPE,
        processorPaymentId: 'ch_123456'
      };

      const refundError = new Error('Refund failed');
      mockProcessor.refundPayment.mockRejectedValue(refundError);

      // Act & Assert
      await expect(paymentService.refundPayment(refundDetails)).rejects.toThrow('Refund failed');
      expect(logger.error).toHaveBeenCalled();
    });
  });

  describe('getPaymentStatus', () => {
    test('should get payment status successfully', async () => {
      // Arrange
      const paymentId = 'payment_123';
      const processorType = ProcessorType.STRIPE;
      const processorPaymentId = 'ch_123456';

      const statusResponse = {
        status: PaymentStatus.COMPLETED,
        updatedAt: new Date()
      };

      mockProcessor.getPaymentStatus.mockResolvedValue(statusResponse);

      // Act
      const result = await paymentService.getPaymentStatus(paymentId, processorType, processorPaymentId);

      // Assert
      expect(PaymentProcessorFactory.getProcessor).toHaveBeenCalledWith(processorType);
      expect(mockProcessor.getPaymentStatus).toHaveBeenCalledWith(processorPaymentId);
      expect(result).toEqual(statusResponse);
    });

    test('should throw error when getting status fails', async () => {
      // Arrange
      const paymentId = 'payment_123';
      const processorType = ProcessorType.STRIPE;
      const processorPaymentId = 'ch_123456';

      const statusError = new Error('Status check failed');
      mockProcessor.getPaymentStatus.mockRejectedValue(statusError);

      // Act & Assert
      await expect(paymentService.getPaymentStatus(paymentId, processorType, processorPaymentId)).rejects.toThrow('Status check failed');
      expect(logger.error).toHaveBeenCalled();
    });
  });
});
