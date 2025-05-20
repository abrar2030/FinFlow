import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

// Load environment variables
dotenv.config();

// Create Prisma client instance
const prisma = new PrismaClient();

// Initialize database connection
export const initializeDatabase = async (): Promise<void> => {
  try {
    // Test connection by querying the database
    await prisma.$connect();
    console.log('Database connection established');
  } catch (error) {
    console.error('Failed to connect to database:', error);
    throw error;
  }
};

// Disconnect from database
export const disconnectDatabase = async (): Promise<void> => {
  try {
    await prisma.$disconnect();
    console.log('Database connection closed');
  } catch (error) {
    console.error('Failed to disconnect from database:', error);
    throw error;
  }
};

export default {
  prisma,
  initializeDatabase,
  disconnectDatabase
};
