import app from './app';
import dotenv from 'dotenv';
import { disconnectDatabase } from './config/database';
import { disconnectKafka } from './config/kafka';

// Load environment variables
dotenv.config();

// Get port from environment or use default
const PORT = process.env.PORT || 4000;

// Start server
const server = app.listen(PORT, () => {
  console.log(`Auth service running on port ${PORT}`);
});

// Handle graceful shutdown
const gracefulShutdown = async () => {
  console.log('Shutting down auth service...');
  
  // Close server
  server.close(() => {
    console.log('HTTP server closed');
  });
  
  try {
    // Disconnect from database
    await disconnectDatabase();
    
    // Disconnect from Kafka
    await disconnectKafka();
    
    console.log('All connections closed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
};

// Listen for termination signals
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

export default server;
