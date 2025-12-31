# Troubleshooting Guide

Common issues, solutions, and debugging tips for FinFlow platform.

---

## Table of Contents

- [Installation Issues](#installation-issues)
- [Service Issues](#service-issues)
- [Database Issues](#database-issues)
- [Authentication Issues](#authentication-issues)
- [Payment Processing Issues](#payment-processing-issues)
- [Docker & Kubernetes Issues](#docker--kubernetes-issues)
- [Performance Issues](#performance-issues)
- [Debugging Tips](#debugging-tips)

---

## Installation Issues

### Problem: Docker Compose fails to start services

**Symptoms:**

```
ERROR: Port 3001 is already allocated
```

**Solution:**

```bash
# Check what's using the port
sudo netstat -tulpn | grep 3001

# Kill the process or change port in docker-compose.yml
# Stop all containers and restart
docker-compose down
docker-compose up --force-recreate
```

---

### Problem: npm install fails with EACCES error

**Symptoms:**

```
npm ERR! code EACCES
npm ERR! syscall access
npm ERR! path /usr/local/lib/node_modules
```

**Solution:**

```bash
# Fix npm permissions (recommended)
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Or use nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 16
nvm use 16
```

---

### Problem: Python dependencies installation fails

**Symptoms:**

```
ERROR: Could not build wheels for scikit-learn
```

**Solution:**

```bash
# Install build dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install python3-dev build-essential

# macOS
brew install python@3.9

# Upgrade pip and setuptools
pip install --upgrade pip setuptools wheel

# Install requirements
pip install -r backend/requirements.txt
```

---

## Service Issues

### Problem: Service fails to connect to database

**Symptoms:**

```
Error: connect ECONNREFUSED 127.0.0.1:5432
```

**Solution:**

```bash
# 1. Check if PostgreSQL is running
sudo systemctl status postgresql
# or
docker ps | grep postgres

# 2. Verify database credentials in .env
cat backend/auth-service/.env | grep DATABASE_URL

# 3. Test connection manually
psql -h localhost -U finflow_user -d finflow

# 4. Check network (Docker)
docker network ls
docker network inspect finflow_network
```

---

### Problem: Kafka connection timeout

**Symptoms:**

```
Error: Connection timeout at bootstrap servers localhost:9092
```

**Solution:**

```bash
# 1. Check Kafka is running
docker ps | grep kafka

# 2. Verify Kafka broker configuration
docker logs kafka

# 3. Test connection
kafkacat -b localhost:9092 -L

# 4. Update KAFKA_BROKERS in .env
KAFKA_BROKERS=kafka:9092  # for Docker
# or
KAFKA_BROKERS=localhost:9092  # for local
```

---

## Database Issues

### Problem: Database migration fails

**Symptoms:**

```
Error: relation "users" already exists
```

**Solution:**

```bash
# 1. Check current migration status
cd backend/auth-service
npx prisma migrate status

# 2. Reset database (DEVELOPMENT ONLY)
npx prisma migrate reset

# 3. Apply migrations
npx prisma migrate deploy

# 4. Generate Prisma client
npx prisma generate
```

---

### Problem: Connection pool exhausted

**Symptoms:**

```
Error: Timed out fetching a new connection from the pool
```

**Solution:**

```bash
# 1. Increase connection pool size in DATABASE_URL
DATABASE_URL="postgresql://user:pass@host:5432/db?max_connections=50"

# 2. Check active connections
SELECT count(*) FROM pg_stat_activity;

# 3. Kill idle connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle' AND state_change < NOW() - INTERVAL '10 minutes';

# 4. Configure connection timeout
idle_in_transaction_session_timeout = 30000  # PostgreSQL config
```

---

## Authentication Issues

### Problem: JWT token expired or invalid

**Symptoms:**

```
401 Unauthorized: Token expired
```

**Solution:**

```bash
# 1. Refresh token
curl -X POST http://localhost:3001/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "YOUR_REFRESH_TOKEN"}'

# 2. Verify JWT_SECRET matches across services
grep JWT_SECRET backend/*/. env

# 3. Check token expiration setting
JWT_EXPIRATION=24h  # Increase if needed

# 4. Clear browser/client storage and re-login
localStorage.clear()  # In browser console
```

---

### Problem: OAuth login fails

**Symptoms:**

```
Error: Invalid OAuth client credentials
```

**Solution:**

```bash
# 1. Verify OAuth credentials in .env
OAUTH_GOOGLE_CLIENT_ID=your_client_id
OAUTH_GOOGLE_CLIENT_SECRET=your_secret

# 2. Check redirect URI matches OAuth app config
# Google Console: https://console.cloud.google.com
# Authorized redirect URIs should include:
# http://localhost:3000/auth/callback/google

# 3. Verify OAuth scopes
# Required scopes: email, profile

# 4. Test with curl
curl 'https://oauth2.googleapis.com/token' \
  -d 'client_id=YOUR_CLIENT_ID' \
  -d 'client_secret=YOUR_CLIENT_SECRET' \
  -d 'code=YOUR_AUTH_CODE' \
  -d 'grant_type=authorization_code'
```

---

## Payment Processing Issues

### Problem: Stripe payment fails

**Symptoms:**

```
Error: No such token: tok_invalid
```

**Solution:**

```bash
# 1. Verify Stripe API keys
echo $STRIPE_API_KEY | cut -c1-10  # Should start with 'sk_test_' or 'sk_live_'

# 2. Test with Stripe CLI
stripe listen --forward-to localhost:3002/api/payments/webhook

# 3. Use test cards for development
# Test card: 4242424242424242
# Any future expiry, any CVC

# 4. Check webhook secret
STRIPE_WEBHOOK_SECRET=whsec_...

# 5. Verify mode (test vs live)
# Ensure test keys are used in development
```

---

### Problem: PayPal sandbox not working

**Symptoms:**

```
Error: AUTHENTICATION_FAILURE
```

**Solution:**

```bash
# 1. Verify sandbox credentials
PAYPAL_CLIENT_ID=your_sandbox_client_id
PAYPAL_CLIENT_SECRET=your_sandbox_secret
PAYPAL_MODE=sandbox

# 2. Test credentials
curl -v https://api-m.sandbox.paypal.com/v1/oauth2/token \
  -u "CLIENT_ID:SECRET" \
  -d "grant_type=client_credentials"

# 3. Use sandbox test accounts
# https://developer.paypal.com/dashboard/accounts

# 4. Check API endpoint
# Sandbox: https://api-m.sandbox.paypal.com
# Live: https://api-m.paypal.com
```

---

## Docker & Kubernetes Issues

### Problem: Docker build fails

**Symptoms:**

```
ERROR [build 5/10] RUN npm install
npm ERR! network timeout
```

**Solution:**

```bash
# 1. Increase Docker build timeout
docker build --network=host --no-cache -t image-name .

# 2. Use BuildKit for better caching
DOCKER_BUILDKIT=1 docker build -t image-name .

# 3. Clear Docker build cache
docker builder prune -af

# 4. Check Docker daemon settings
# Increase memory limit in Docker Desktop settings
```

---

### Problem: Kubernetes pod keeps restarting

**Symptoms:**

```
kubectl get pods
NAME                     READY   STATUS             RESTARTS
payments-service-abc123  0/1     CrashLoopBackOff   5
```

**Solution:**

```bash
# 1. Check pod logs
kubectl logs payments-service-abc123
kubectl logs payments-service-abc123 --previous  # Previous container

# 2. Describe pod for events
kubectl describe pod payments-service-abc123

# 3. Check resource limits
# Increase memory/CPU in deployment.yaml

# 4. Verify secrets and configmaps
kubectl get secrets
kubectl get configmaps

# 5. Check liveness/readiness probes
# Adjust initialDelaySeconds and timeouts
```

---

## Performance Issues

### Problem: API responses are slow

**Symptoms:**

- Response times > 1 second
- Timeouts occurring

**Solution:**

```bash
# 1. Enable Redis caching
REDIS_URL=redis://localhost:6379
CACHE_TTL_SECONDS=300

# 2. Check database query performance
# Enable query logging in PostgreSQL
log_statement = 'all'

# 3. Add database indexes
CREATE INDEX idx_users_email ON users(email);

# 4. Optimize queries
# Use EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT * FROM transactions WHERE user_id = 'uuid';

# 5. Enable connection pooling
DATABASE_URL="postgresql://user:pass@host:5432/db?max_connections=50&connection_limit=10"

# 6. Use pagination for large result sets
GET /api/payments?page=1&limit=50
```

---

### Problem: High memory usage

**Symptoms:**

```
Out of memory error
Process killed by OOM killer
```

**Solution:**

```bash
# 1. Monitor memory usage
docker stats
kubectl top pods

# 2. Increase container memory limits
resources:
  limits:
    memory: 2Gi

# 3. Check for memory leaks
# Use Node.js --inspect flag
node --inspect --max-old-space-size=4096 app.js

# 4. Optimize code
# - Clear intervals/timers
# - Close database connections
# - Limit in-memory caching

# 5. Enable garbage collection logs
NODE_OPTIONS="--max-old-space-size=4096 --trace-gc"
```

---

## Debugging Tips

### Enable Debug Logging

**Node.js Services:**

```bash
LOG_LEVEL=debug npm run start:dev
```

**Python Services:**

```bash
LOG_LEVEL=DEBUG python src/main.py
```

### Network Debugging

```bash
# Test service connectivity
curl -v http://localhost:3001/health

# Check DNS resolution
nslookup payments-service.finflow-prod.svc.cluster.local

# Trace network path
traceroute api.finflow.com

# Check open ports
nc -zv localhost 3001-3005
```

### Database Debugging

```bash
# PostgreSQL query performance
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM payments WHERE status = 'pending';

# Show slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

# Check table sizes
SELECT tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Kafka Debugging

```bash
# List topics
kafka-topics --list --bootstrap-server localhost:9092

# Consume messages
kafka-console-consumer --bootstrap-server localhost:9092 \
  --topic payment.events --from-beginning

# Check consumer lag
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group finflow-consumers
```

---

## Getting Help

If you can't find a solution here:

1. **Check Logs**: Always check service logs first

   ```bash
   docker-compose logs service-name
   kubectl logs pod-name
   ```

2. **GitHub Issues**: Search existing issues or create a new one
   - https://github.com/abrar2030/FinFlow/issues

3. **Documentation**: Review relevant sections
   - [Installation](INSTALLATION.md)
   - [Configuration](CONFIGURATION.md)
   - [Architecture](ARCHITECTURE.md)

---

**When reporting issues, include:**

- Error message and stack trace
- Service logs
- Environment (OS, Docker version, etc.)
- Configuration (redact secrets)
- Steps to reproduce
