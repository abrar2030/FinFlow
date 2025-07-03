"""
FinFlow AI Features Service

Advanced AI-powered financial features including:
- Predictive cash flow modeling
- Automated financial advisory
- Risk assessment and scoring
- Investment recommendations
- Market analysis and insights
"""

import asyncio
import logging
import sys
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import make_asgi_app

from config.settings import get_settings
from config.database import init_database, close_database
from config.redis_client import init_redis, close_redis
from config.logging_config import setup_logging
from api.v1.router import api_router
from services.model_manager import ModelManager
from services.prediction_service import PredictionService
from services.advisory_service import AdvisoryService
from services.cash_flow_service import CashFlowService
from utils.health_check import HealthChecker

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan manager"""
    logger.info("Starting FinFlow AI Features Service...")
    
    try:
        # Initialize database connections
        await init_database()
        await init_redis()
        
        # Initialize AI services
        model_manager = ModelManager()
        await model_manager.initialize()
        
        prediction_service = PredictionService(model_manager)
        await prediction_service.initialize()
        
        advisory_service = AdvisoryService(model_manager)
        await advisory_service.initialize()
        
        cash_flow_service = CashFlowService(model_manager)
        await cash_flow_service.initialize()
        
        # Store services in app state
        app.state.model_manager = model_manager
        app.state.prediction_service = prediction_service
        app.state.advisory_service = advisory_service
        app.state.cash_flow_service = cash_flow_service
        app.state.health_checker = HealthChecker()
        
        logger.info("AI Features Service initialized successfully")
        
        yield
        
    except Exception as e:
        logger.error(f"Failed to initialize AI Features Service: {e}")
        sys.exit(1)
    
    finally:
        # Cleanup
        logger.info("Shutting down AI Features Service...")
        
        if hasattr(app.state, 'model_manager'):
            await app.state.model_manager.cleanup()
        
        await close_redis()
        await close_database()
        
        logger.info("AI Features Service shutdown complete")


def create_app() -> FastAPI:
    """Create and configure FastAPI application"""
    
    app = FastAPI(
        title="FinFlow AI Features Service",
        description="Advanced AI-powered financial features and analytics",
        version="1.0.0",
        docs_url="/docs" if settings.environment == "development" else None,
        redoc_url="/redoc" if settings.environment == "development" else None,
        lifespan=lifespan
    )
    
    # Add middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    app.add_middleware(GZipMiddleware, minimum_size=1000)
    
    # Add Prometheus metrics endpoint
    metrics_app = make_asgi_app()
    app.mount("/metrics", metrics_app)
    
    # Include API routes
    app.include_router(api_router, prefix="/api/v1")
    
    # Health check endpoint
    @app.get("/health")
    async def health_check():
        """Health check endpoint"""
        try:
            health_checker = getattr(app.state, 'health_checker', None)
            if health_checker:
                health_status = await health_checker.check_health()
                return JSONResponse(content=health_status)
            else:
                return JSONResponse(content={
                    "status": "healthy",
                    "service": "ai-features-service",
                    "timestamp": asyncio.get_event_loop().time()
                })
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            raise HTTPException(status_code=503, detail="Service unhealthy")
    
    # Root endpoint
    @app.get("/")
    async def root():
        """Root endpoint"""
        return {
            "service": "FinFlow AI Features Service",
            "version": "1.0.0",
            "status": "running",
            "docs": "/docs" if settings.environment == "development" else "disabled",
            "health": "/health"
        }
    
    return app


def main():
    """Main entry point"""
    app = create_app()
    
    # Configure uvicorn
    config = uvicorn.Config(
        app,
        host="0.0.0.0",
        port=settings.port,
        log_level=settings.log_level.lower(),
        access_log=True,
        reload=settings.environment == "development",
        workers=1 if settings.environment == "development" else settings.workers
    )
    
    server = uvicorn.Server(config)
    
    try:
        logger.info(f"Starting server on http://0.0.0.0:{settings.port}")
        server.run()
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

