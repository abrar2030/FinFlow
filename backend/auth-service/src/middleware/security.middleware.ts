import { Request, Response, NextFunction } from "express";
import { RateLimiterMemory } from "rate-limiter-flexible";
import { logger } from "../utils/logger";

// Create a rate limiter instance
const rateLimiter = new RateLimiterMemory({
  points: 10, // Number of points
  duration: 60, // Per second(s)
});

// Rate limiting middleware
export const rateLimitMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    // Get client IP
    const clientIp = req.ip || req.headers["x-forwarded-for"] || "unknown";

    // Consume points
    await rateLimiter.consume(clientIp.toString());

    // If successful, proceed to next middleware
    next();
  } catch (error) {
    // If rate limit exceeded
    logger.warn(`Rate limit exceeded for IP: ${req.ip}`);

    // Set appropriate headers
    res.status(429).json({
      success: false,
      error: "Too many requests, please try again later.",
    });
  }
};

// CSRF protection middleware
export const csrfProtectionMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  // Skip for GET, HEAD, OPTIONS requests
  if (["GET", "HEAD", "OPTIONS"].includes(req.method)) {
    return next();
  }

  // Check CSRF token
  const csrfToken = req.headers["x-csrf-token"] || req.body._csrf;
  const storedToken = req.cookies?.["csrf_token"];

  if (!csrfToken || !storedToken || csrfToken !== storedToken) {
    logger.warn(`CSRF token validation failed for ${req.path}`);
    return res.status(403).json({
      success: false,
      error: "CSRF token validation failed",
    });
  }

  next();
};

// Security headers middleware
export const securityHeadersMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  // Set security headers
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("X-XSS-Protection", "1; mode=block");
  res.setHeader(
    "Strict-Transport-Security",
    "max-age=31536000; includeSubDomains",
  );
  res.setHeader(
    "Content-Security-Policy",
    "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:;",
  );
  res.setHeader("Referrer-Policy", "same-origin");
  res.setHeader(
    "Permissions-Policy",
    "geolocation=(), microphone=(), camera=()",
  );

  next();
};
