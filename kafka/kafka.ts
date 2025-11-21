import dotenv from 'dotenv';
import { Kafka, Producer, Consumer, KafkaConfig } from 'kafkajs';

// Load environment variables
dotenv.config();

// Kafka configuration
const kafkaConfig: KafkaConfig = {
  clientId: process.env.KAFKA_CLIENT_ID || 'auth-service',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
  retry: {
    initialRetryTime: 100,
    retries: 8,
  },
};

// Create Kafka instance
const kafka = new Kafka(kafkaConfig);

// Create producer
const producer: Producer = kafka.producer();

// Create consumer
const consumer: Consumer = kafka.consumer({
  groupId: process.env.KAFKA_GROUP_ID || 'auth-service-group',
});

// Initialize Kafka connections
export const initializeKafka = async (): Promise<void> => {
  try {
    await producer.connect();
    console.log('Kafka producer connected');

    await consumer.connect();
    console.log('Kafka consumer connected');
  } catch (error) {
    console.error('Failed to connect to Kafka:', error);
    throw error;
  }
};

// Disconnect Kafka connections
export const disconnectKafka = async (): Promise<void> => {
  try {
    await producer.disconnect();
    console.log('Kafka producer disconnected');

    await consumer.disconnect();
    console.log('Kafka consumer disconnected');
  } catch (error) {
    console.error('Failed to disconnect from Kafka:', error);
    throw error;
  }
};

// Send message to Kafka topic
export const sendMessage = async (topic: string, message: any): Promise<void> => {
  try {
    await producer.send({
      topic,
      messages: [
        {
          key: message.id || String(Date.now()),
          value: JSON.stringify(message),
        },
      ],
    });
    console.log(`Message sent to topic ${topic}`);
  } catch (error) {
    console.error(`Failed to send message to topic ${topic}:`, error);
    throw error;
  }
};

// Subscribe to Kafka topic
export const subscribeToTopic = async (
  topic: string,
  callback: (message: any) => Promise<void>
): Promise<void> => {
  try {
    await consumer.subscribe({ topic, fromBeginning: false });

    await consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        const value = message.value?.toString();
        if (value) {
          try {
            const parsedValue = JSON.parse(value);
            await callback(parsedValue);
          } catch (error) {
            console.error(`Failed to process message from topic ${topic}:`, error);
          }
        }
      },
    });

    console.log(`Subscribed to topic ${topic}`);
  } catch (error) {
    console.error(`Failed to subscribe to topic ${topic}:`, error);
    throw error;
  }
};

export default {
  kafka,
  producer,
  consumer,
  initializeKafka,
  disconnectKafka,
  sendMessage,
  subscribeToTopic,
};
