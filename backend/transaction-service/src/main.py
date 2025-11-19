import asyncio
import json
import logging
import os
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import (BackgroundTasks, Depends, FastAPI, HTTPException, Request,
                     status)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from redis import Redis
from redis.exceptions import RedisError

from .models import (TransactionBatch, TransactionBatchResponse,
                     TransactionQuery, TransactionRequest, TransactionResponse,
                     TransactionStatus, ValidationResult)
from .validation import BatchTransactionValidator, TransactionValidator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)
logger = logging.getLogger("transaction-service")

# Initialize FastAPI app
app = FastAPI(
    title="FinFlow Transaction Service",
    description="Comprehensive transaction processing and validation API",
    version="1.0.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OAuth2 scheme for JWT validation
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Initialize transaction validator
transaction_validator = TransactionValidator()
batch_validator = BatchTransactionValidator(transaction_validator)

# Initialize Redis client for caching
try:
    redis_host = os.getenv("REDIS_HOST", "localhost")
    redis_port = int(os.getenv("REDIS_PORT", "6379"))
    redis_client = Redis(
        host=redis_host,
        port=redis_port,
        decode_responses=True,
        socket_timeout=5,
    )
    logger.info(f"Redis client initialized: {redis_host}:{redis_port}")
except Exception as e:
    logger.error(f"Failed to initialize Redis client: {e}")
    redis_client = None

# JWT validation dependency
async def get_current_user(token: str = Depends(oauth2_scheme)):
    # In production, this would validate the JWT against Auth service
    # For demo, we'll just log and accept any token
    logger.info(f"Received token: {token[:10]}...")
    return {"sub": "demo-user", "role": "USER"}

# Request context extraction
async def get_request_context(request: Request) -> Dict[str, Any]:
    """
    Extract context information from the request.
    
    Args:
        request: FastAPI Request object
        
    Returns:
        Dictionary with context information
    """
    context = {
        "ip_address": request.client.host if request.client else None,
        "user_agent": request.headers.get("user-agent"),
        "request_id": str(uuid.uuid4()),
        "timestamp": datetime.now().isoformat(),
    }
    
    # In production, this would extract more information:
    # - Device fingerprint from headers or cookies
    # - Geolocation based on IP
    # - User session information
    
    return context

# Cache middleware
async def get_cached_response(cache_key: str) -> Optional[Dict[str, Any]]:
    """
    Get cached response if available.
    
    Args:
        cache_key: Cache key
        
    Returns:
        Cached response or None
    """
    if not redis_client:
        return None
    
    try:
        cached = redis_client.get(cache_key)
        if cached:
            logger.info(f"Cache hit for key: {cache_key}")
            return json.loads(cached)
    except RedisError as e:
        logger.error(f"Redis error when getting cached response: {e}")
    except Exception as e:
        logger.error(f"Error when getting cached response: {e}")
    
    return None

async def set_cached_response(cache_key: str, response: Dict[str, Any], ttl_seconds: int = 300) -> None:
    """
    Cache response for future requests.
    
    Args:
        cache_key: Cache key
        response: Response to cache
        ttl_seconds: Time-to-live in seconds
    """
    if not redis_client:
        return
    
    try:
        redis_client.setex(
            cache_key,
            ttl_seconds,
            json.dumps(response)
        )
        logger.info(f"Cached response with key: {cache_key}, TTL: {ttl_seconds}s")
    except RedisError as e:
        logger.error(f"Redis error when caching response: {e}")
    except Exception as e:
        logger.error(f"Error when caching response: {e}")

# Endpoints
@app.post("/transactions", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def create_transaction(
    transaction: TransactionRequest,
    background_tasks: BackgroundTasks,
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """
    Create and validate a new transaction
    """
    # Extract request context
    context = await get_request_context(request)
    context["user_id"] = current_user["sub"]
    
    # Log the request (audit logging)
    logger.info(f"Transaction request from user {current_user['sub']}: {transaction.transaction_id}")
    
    try:
        # Validate transaction
        validation_result = transaction_validator.validate_transaction(transaction, context)
        
        # Determine transaction status based on validation result
        if validation_result.is_valid:
            if validation_result.risk_level.value in ["HIGH", "CRITICAL"]:
                status_value = TransactionStatus.HELD
            else:
                status_value = TransactionStatus.PROCESSING
        else:
            status_value = TransactionStatus.REJECTED
        
        # Create transaction response
        response = TransactionResponse(
            transaction_id=transaction.transaction_id,
            source_account_id=transaction.source_account_id,
            destination_account_id=transaction.destination_account_id,
            amount=transaction.amount,
            currency=transaction.currency,
            transaction_type=transaction.transaction_type,
            status=status_value,
            reference=transaction.reference,
            description=transaction.description,
            created_at=datetime.now(),
            updated_at=datetime.now(),
            completed_at=None,
            validation_result={
                "is_valid": validation_result.is_valid,
                "risk_score": validation_result.risk_score,
                "risk_level": validation_result.risk_level.value,
                "validation_checks": validation_result.validation_checks
            },
            risk_score=validation_result.risk_score,
            risk_level=validation_result.risk_level,
            metadata=transaction.metadata,
            errors=validation_result.errors if not validation_result.is_valid else None
        )
        
        # Process transaction asynchronously if valid
        if validation_result.is_valid and status_value == TransactionStatus.PROCESSING:
            background_tasks.add_task(
                process_transaction_async,
                transaction,
                response,
                context
            )
        
        # Log the response (audit logging)
        logger.info(
            f"Transaction response for {transaction.transaction_id}: "
            f"status={status_value.value}, valid={validation_result.is_valid}, "
            f"risk={validation_result.risk_level.value}"
        )
        
        return response
    
    except Exception as e:
        logger.error(f"Error processing transaction {transaction.transaction_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process transaction"
        )

@app.post("/transactions/batch", response_model=TransactionBatchResponse)
async def create_transaction_batch(
    batch: TransactionBatch,
    background_tasks: BackgroundTasks,
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """
    Create and validate a batch of transactions
    """
    # Extract request context
    context = await get_request_context(request)
    context["user_id"] = current_user["sub"]
    
    # Log the request (audit logging)
    logger.info(f"Transaction batch request from user {current_user['sub']}: {batch.batch_id}, {len(batch.transactions)} transactions")
    
    try:
        # Validate transactions in batch
        validation_results = batch_validator.validate_batch(batch.transactions, context)
        
        # Process each transaction and create responses
        transaction_responses = []
        successful_count = 0
        failed_count = 0
        
        for transaction in batch.transactions:
            validation_result = validation_results.get(transaction.transaction_id)
            
            if not validation_result:
                # This should not happen, but handle it gracefully
                failed_count += 1
                continue
            
            # Determine transaction status based on validation result
            if validation_result.is_valid:
                if validation_result.risk_level.value in ["HIGH", "CRITICAL"]:
                    status_value = TransactionStatus.HELD
                else:
                    status_value = TransactionStatus.PROCESSING
                    successful_count += 1
            else:
                status_value = TransactionStatus.REJECTED
                failed_count += 1
            
            # Create transaction response
            response = TransactionResponse(
                transaction_id=transaction.transaction_id,
                source_account_id=transaction.source_account_id,
                destination_account_id=transaction.destination_account_id,
                amount=transaction.amount,
                currency=transaction.currency,
                transaction_type=transaction.transaction_type,
                status=status_value,
                reference=transaction.reference,
                description=transaction.description,
                created_at=datetime.now(),
                updated_at=datetime.now(),
                completed_at=None,
                validation_result={
                    "is_valid": validation_result.is_valid,
                    "risk_score": validation_result.risk_score,
                    "risk_level": validation_result.risk_level.value,
                    "validation_checks": validation_result.validation_checks
                },
                risk_score=validation_result.risk_score,
                risk_level=validation_result.risk_level,
                metadata=transaction.metadata,
                errors=validation_result.errors if not validation_result.is_valid else None
            )
            
            transaction_responses.append(response)
            
            # Process valid transactions asynchronously
            if validation_result.is_valid and status_value == TransactionStatus.PROCESSING:
                background_tasks.add_task(
                    process_transaction_async,
                    transaction,
                    response,
                    context
                )
        
        # Create batch response
        batch_response = TransactionBatchResponse(
            batch_id=batch.batch_id,
            processed_count=len(batch.transactions),
            successful_count=successful_count,
            failed_count=failed_count,
            transactions=transaction_responses,
            created_at=batch.created_at,
            completed_at=datetime.now()
        )
        
        # Log the response (audit logging)
        logger.info(
            f"Transaction batch response for {batch.batch_id}: "
            f"processed={len(batch.transactions)}, successful={successful_count}, failed={failed_count}"
        )
        
        return batch_response
    
    except Exception as e:
        logger.error(f"Error processing transaction batch {batch.batch_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process transaction batch"
        )

@app.get("/transactions/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(
    transaction_id: str,
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """
    Get transaction details by ID
    """
    # Generate cache key
    cache_key = f"transaction:{transaction_id}"
    
    # Try to get from cache
    cached_response = await get_cached_response(cache_key)
    if cached_response:
        return cached_response
    
    # Log the request (audit logging)
    logger.info(f"Transaction details request from user {current_user['sub']}: {transaction_id}")
    
    try:
        # In production, this would query a database
        # For demo, we'll return a mock response
        response = TransactionResponse(
            transaction_id=transaction_id,
            source_account_id="account123",
            destination_account_id="account456",
            amount=1000.0,
            currency="USD",
            transaction_type=TransactionType.TRANSFER,
            status=TransactionStatus.COMPLETED,
            reference="REF123",
            description="Demo transaction",
            created_at=datetime.now(),
            updated_at=datetime.now(),
            completed_at=datetime.now(),
            validation_result={
                "is_valid": True,
                "risk_score": 0.2,
                "risk_level": "LOW",
                "validation_checks": {"basic_fields_valid": True, "amount_valid": True}
            },
            risk_score=0.2,
            risk_level=RiskLevel.LOW,
            metadata={"demo": True},
            errors=None
        )
        
        # Cache the response
        await set_cached_response(cache_key, response.dict(), ttl_seconds=300)
        
        return response
    
    except Exception as e:
        logger.error(f"Error retrieving transaction {transaction_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve transaction"
        )

@app.get("/transactions", response_model=List[TransactionResponse])
async def query_transactions(
    query: TransactionQuery = Depends(),
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """
    Query transactions based on filters
    """
    # Generate cache key based on query parameters
    cache_key = f"transactions:query:{hash(frozenset(query.dict().items()))}"
    
    # Try to get from cache
    cached_response = await get_cached_response(cache_key)
    if cached_response:
        return cached_response
    
    # Log the request (audit logging)
    logger.info(f"Transaction query request from user {current_user['sub']}: {query.dict()}")
    
    try:
        # In production, this would query a database with filters
        # For demo, we'll return mock responses
        responses = [
            TransactionResponse(
                transaction_id=f"tx-{i}",
                source_account_id="account123",
                destination_account_id="account456",
                amount=1000.0 * (i + 1),
                currency="USD",
                transaction_type=TransactionType.TRANSFER,
                status=TransactionStatus.COMPLETED,
                reference=f"REF{i}",
                description=f"Demo transaction {i}",
                created_at=datetime.now(),
                updated_at=datetime.now(),
                completed_at=datetime.now(),
                validation_result={
                    "is_valid": True,
                    "risk_score": 0.2,
                    "risk_level": "LOW",
                    "validation_checks": {"basic_fields_valid": True, "amount_valid": True}
                },
                risk_score=0.2,
                risk_level=RiskLevel.LOW,
                metadata={"demo": True, "index": i},
                errors=None
            )
            for i in range(min(query.limit, 10))
        ]
        
        # Cache the response
        await set_cached_response(cache_key, [r.dict() for r in responses], ttl_seconds=60)
        
        return responses
    
    except Exception as e:
        logger.error(f"Error querying transactions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to query transactions"
        )

# Background processing function
async def process_transaction_async(
    transaction: TransactionRequest,
    response: TransactionResponse,
    context: Dict[str, Any]
) -> None:
    """
    Process a transaction asynchronously.
    In production, this would interact with account and ledger services.
    
    Args:
        transaction: Transaction request
        response: Transaction response
        context: Request context
    """
    # Simulate processing delay
    await asyncio.sleep(1)
    
    # In production, this would:
    # 1. Update account balances
    # 2. Record in ledger
    # 3. Send notifications
    # 4. Update transaction status
    
    logger.info(f"Transaction {transaction.transaction_id} processed successfully")

# Health check endpoint
@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    """
    Health check endpoint for monitoring
    """
    # Check Redis connection if available
    redis_status = "healthy" if redis_client else "unavailable"
    
    try:
        if redis_client:
            redis_client.ping()
    except Exception:
        redis_status = "unhealthy"
    
    return {
        "status": "healthy",
        "service": "transaction-service",
        "dependencies": {
            "redis": redis_status
        },
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8001")))
