import app from './app';
import logger from './logger';
import dotenv from 'dotenv';
import { disconnectDatabase } from './config/database';
import { disconnectKafka } from './config/kafka';

// Load environment variables
dotenv.config();

// Get port from environment or use default
const PORT = process.env.PORT || 4000;

// Start server
const server = app.listen(PORT, () => {
  logger.info(`Auth service running on port ${PORT}`);
});

// Handle graceful shutdown
const gracefulShutdown = async () => {
  logger.info('Shutting down auth service...');
  
  // Close server
  server.close(() => {
    logger.info('HTTP server closed');
  });
  
  try {
    // Disconnect from database
    await disconnectDatabase();
    
    // Disconnect from Kafka
    await disconnectKafka();
    
    logger.info('All connections closed successfully');
    process.exit(0);
  } catch (error) {
    logger.error('Error during shutdown:', error);
    process.exit(1);
  }
};

// Listen for termination signals
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

export default server;
