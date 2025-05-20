import { Request, Response, NextFunction } from 'express';
import { logger } from './logger.middleware';

// Error handling middleware
const errorMiddleware = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Log error
  logger.error({
    message: 'Error occurred',
    error: {
      name: error.name,
      message: error.message,
      stack: error.stack
    },
    method: req.method,
    path: req.path
  });

  // Determine status code based on error type
  let statusCode = 500;
  let errorMessage = 'Internal Server Error';

  // Handle specific error types
  if (error.name === 'ValidationError') {
    statusCode = 400;
    errorMessage = error.message;
  } else if (error.name === 'UnauthorizedError') {
    statusCode = 401;
    errorMessage = 'Unauthorized: Invalid or expired token';
  } else if (error.name === 'ForbiddenError') {
    statusCode = 403;
    errorMessage = 'Forbidden: Insufficient permissions';
  } else if (error.name === 'NotFoundError') {
    statusCode = 404;
    errorMessage = error.message || 'Resource not found';
  }

  // Send error response
  res.status(statusCode).json({
    error: {
      message: errorMessage,
      status: statusCode
    }
  });
};

export default errorMiddleware;
