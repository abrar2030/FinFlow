import dotenv from "dotenv";
import logger from "./logger";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import passport from "passport";
import routes from "./routes";
import { initializeDatabase } from "./config/database";
import { initializeKafka } from "./config/kafka";
import { initializePassport } from "./config/passport";
import errorMiddleware from "./error.middleware";
import loggerMiddleware from "./middlewares/logger.middleware";

// Load environment variables
dotenv.config();

// Create Express application
const app = express();

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // CORS support
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
app.use(loggerMiddleware); // Request logging

// Initialize Passport
initializePassport();
app.use(passport.initialize());

// Routes
app.use("/api", routes);

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", service: "auth-service" });
});

// Error handling middleware
app.use(errorMiddleware);

// Initialize services
const initializeApp = async () => {
  try {
    // Connect to database
    await initializeDatabase();

    // Connect to Kafka
    await initializeKafka();

    logger.info("All services initialized successfully");
  } catch (error) {
    logger.error("Failed to initialize services:", error);
    process.exit(1);
  }
};

// Call initialization function
initializeApp();

export default app;
