# FinFlow Payments Service Dockerfile
# Multi-stage build for optimized production image

# Build stage
FROM node:20-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the application (if using TypeScript or other build steps)
RUN npm run build

# Production stage
FROM node:20-alpine AS production

# Set working directory
WORKDIR /app

# Create app user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy package files and install production dependencies only
COPY package*.json ./
RUN npm ci --only=production

# Copy built application from build stage
COPY --from=build /app/dist /app/dist

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3002

# Expose port
EXPOSE 3002

# Change to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost:3002/health || exit 1

# Start the application
CMD ["node", "dist/main.js"]
