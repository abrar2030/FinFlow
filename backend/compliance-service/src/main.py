from typing import Dict, List, Any, Optional, Union
import logging
import json
import os
from datetime import datetime, timedelta
from fastapi import FastAPI, Depends, HTTPException, status, Request, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)
logger = logging.getLogger("compliance-service")

# Initialize FastAPI app
app = FastAPI(
    title="FinFlow Compliance Service",
    description="Financial compliance modules for GDPR, PSD2, and other regulations",
    version="1.0.0",
)

# Models for GDPR compliance
class GDPRDataRequest(BaseModel):
    user_id: str
    request_type: str = Field(..., description="Type of GDPR request: export, delete, restrict, etc.")
    request_details: Optional[Dict[str, Any]] = None

class GDPRDataResponse(BaseModel):
    request_id: str
    user_id: str
    status: str
    data: Optional[Dict[str, Any]] = None
    created_at: datetime
    completed_at: Optional[datetime] = None

# Models for PSD2 compliance
class PSD2AuthRequest(BaseModel):
    user_id: str
    third_party_provider: str
    scope: List[str]
    duration_days: int = Field(90, ge=1, le=90)
    metadata: Optional[Dict[str, Any]] = None

class PSD2AuthResponse(BaseModel):
    consent_id: str
    user_id: str
    third_party_provider: str
    scope: List[str]
    status: str
    expires_at: datetime
    created_at: datetime

# Models for AML/CFT compliance
class AMLScreeningRequest(BaseModel):
    entity_type: str = Field(..., description="Type of entity: individual, organization")
    entity_id: str
    entity_name: str
    country_code: Optional[str] = None
    additional_data: Optional[Dict[str, Any]] = None

class AMLScreeningResponse(BaseModel):
    screening_id: str
    entity_id: str
    entity_type: str
    status: str
    risk_score: float
    risk_level: str
    matches: List[Dict[str, Any]]
    created_at: datetime

# Compliance service implementation
class ComplianceService:
    """
    Comprehensive compliance service implementing GDPR, PSD2, and other financial regulations.
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the compliance service with optional configuration.
        
        Args:
            config: Configuration dictionary with compliance settings
        """
        self.config = config or self._default_config()
        self._data_requests = {}  # In production, this would be a database
        self._psd2_consents = {}  # In production, this would be a database
        self._aml_screenings = {}  # In production, this would be a database
        logger.info("Compliance service initialized with configuration")
    
    def _default_config(self) -> Dict[str, Any]:
        """
        Default configuration for compliance service.
        
        Returns:
            Dict containing default compliance configuration
        """
        return {
            "gdpr": {
                "data_retention_days": 730,  # 2 years
                "export_format": "json",
                "data_sources": ["transactions", "accounts", "user_profiles", "audit_logs"],
            },
            "psd2": {
                "max_consent_days": 90,
                "allowed_scopes": ["account_info", "balance", "transactions", "payments"],
                "require_strong_authentication": True,
                "renewal_notification_days": 15,
            },
            "aml": {
                "screening_providers": ["internal", "external"],
                "rescreening_interval_days": 90,
                "pep_check_enabled": True,
                "sanctions_check_enabled": True,
                "adverse_media_check_enabled": True,
            }
        }
    
    # GDPR compliance methods
    
    def process_gdpr_request(self, request: GDPRDataRequest) -> GDPRDataResponse:
        """
        Process a GDPR data request (export, delete, etc.).
        
        Args:
            request: GDPR data request
            
        Returns:
            GDPR data response
        """
        request_id = f"gdpr-{request.user_id}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # Log the request for audit purposes
        logger.info(f"GDPR {request.request_type} request {request_id} for user {request.user_id}")
        
        # Initialize response
        response = GDPRDataResponse(
            request_id=request_id,
            user_id=request.user_id,
            status="PROCESSING",
            created_at=datetime.now(),
        )
        
        # Store request for tracking
        self._data_requests[request_id] = response.dict()
        
        # Process based on request type
        if request.request_type == "export":
            # In production, this would gather data from all systems
            user_data = self._gather_user_data(request.user_id)
            response.data = user_data
            response.status = "COMPLETED"
            response.completed_at = datetime.now()
        
        elif request.request_type == "delete":
            # In production, this would delete data from all systems
            self._delete_user_data(request.user_id)
            response.status = "COMPLETED"
            response.completed_at = datetime.now()
        
        elif request.request_type == "restrict":
            # In production, this would restrict processing in all systems
            self._restrict_user_data_processing(request.user_id)
            response.status = "COMPLETED"
            response.completed_at = datetime.now()
        
        else:
            response.status = "FAILED"
            logger.error(f"Unknown GDPR request type: {request.request_type}")
        
        # Update stored request
        self._data_requests[request_id] = response.dict()
        
        return response
    
    def get_gdpr_request_status(self, request_id: str) -> Optional[GDPRDataResponse]:
        """
        Get the status of a GDPR data request.
        
        Args:
            request_id: GDPR request ID
            
        Returns:
            GDPR data response or None if not found
        """
        if request_id in self._data_requests:
            data = self._data_requests[request_id]
            return GDPRDataResponse(**data)
        return None
    
    def _gather_user_data(self, user_id: str) -> Dict[str, Any]:
        """
        Gather all data for a user across systems.
        In production, this would query multiple services.
        
        Args:
            user_id: User ID
            
        Returns:
            Dictionary with all user data
        """
        # Mock implementation
        return {
            "user_profile": {
                "user_id": user_id,
                "email": f"user{user_id}@example.com",
                "name": f"User {user_id}",
                "created_at": "2024-01-01T00:00:00Z",
            },
            "accounts": [
                {
                    "account_id": f"acct-{user_id}-1",
                    "type": "CHECKING",
                    "balance": 1000.0,
                    "currency": "USD",
                    "created_at": "2024-01-02T00:00:00Z",
                }
            ],
            "transactions": [
                {
                    "transaction_id": f"tx-{user_id}-1",
                    "account_id": f"acct-{user_id}-1",
                    "amount": 100.0,
                    "currency": "USD",
                    "type": "DEPOSIT",
                    "created_at": "2024-01-03T00:00:00Z",
                }
            ],
            "consents": [
                {
                    "consent_id": f"consent-{user_id}-1",
                    "type": "MARKETING",
                    "status": "ACTIVE",
                    "created_at": "2024-01-01T00:00:00Z",
                }
            ],
            "audit_logs": [
                {
                    "log_id": f"log-{user_id}-1",
                    "action": "LOGIN",
                    "timestamp": "2024-01-04T00:00:00Z",
                    "ip_address": "192.168.1.1",
                }
            ]
        }
    
    def _delete_user_data(self, user_id: str) -> None:
        """
        Delete all data for a user across systems.
        In production, this would delete from multiple services.
        
        Args:
            user_id: User ID
        """
        # Mock implementation
        logger.info(f"Deleted all data for user {user_id}")
    
    def _restrict_user_data_processing(self, user_id: str) -> None:
        """
        Restrict processing of data for a user across systems.
        In production, this would update flags in multiple services.
        
        Args:
            user_id: User ID
        """
        # Mock implementation
        logger.info(f"Restricted data processing for user {user_id}")
    
    # PSD2 compliance methods
    
    def create_psd2_consent(self, request: PSD2AuthRequest) -> PSD2AuthResponse:
        """
        Create a PSD2 consent for third-party access.
        
        Args:
            request: PSD2 authorization request
            
        Returns:
            PSD2 authorization response
        """
        # Validate scopes against allowed scopes
        for scope in request.scope:
            if scope not in self.config["psd2"]["allowed_scopes"]:
                raise ValueError(f"Invalid scope: {scope}")
        
        # Generate consent ID
        consent_id = f"psd2-{request.user_id}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # Calculate expiration date
        expires_at = datetime.now() + timedelta(days=min(request.duration_days, self.config["psd2"]["max_consent_days"]))
        
        # Create response
        response = PSD2AuthResponse(
            consent_id=consent_id,
            user_id=request.user_id,
            third_party_provider=request.third_party_provider,
            scope=request.scope,
            status="AUTHORIZED",
            expires_at=expires_at,
            created_at=datetime.now(),
        )
        
        # Store consent
        self._psd2_consents[consent_id] = response.dict()
        
        # Log for audit
        logger.info(f"PSD2 consent {consent_id} created for user {request.user_id}, TPP: {request.third_party_provider}")
        
        return response
    
    def revoke_psd2_consent(self, consent_id: str) -> bool:
        """
        Revoke a PSD2 consent.
        
        Args:
            consent_id: Consent ID
            
        Returns:
            True if successful, False if consent not found
        """
        if consent_id in self._psd2_consents:
            consent = self._psd2_consents[consent_id]
            consent["status"] = "REVOKED"
            self._psd2_consents[consent_id] = consent
            
            # Log for audit
            logger.info(f"PSD2 consent {consent_id} revoked for user {consent['user_id']}")
            
            return True
        
        return False
    
    def validate_psd2_consent(self, consent_id: str, scope: str) -> bool:
        """
        Validate a PSD2 consent for a specific scope.
        
        Args:
            consent_id: Consent ID
            scope: Requested scope
            
        Returns:
            True if consent is valid for the scope
        """
        if consent_id not in self._psd2_consents:
            return False
        
        consent = self._psd2_consents[consent_id]
        
        # Check if consent is active
        if consent["status"] != "AUTHORIZED":
            return False
        
        # Check if consent has expired
        expires_at = datetime.fromisoformat(consent["expires_at"]) if isinstance(consent["expires_at"], str) else consent["expires_at"]
        if expires_at < datetime.now():
            # Auto-update status to expired
            consent["status"] = "EXPIRED"
            self._psd2_consents[consent_id] = consent
            return False
        
        # Check if requested scope is authorized
        if scope not in consent["scope"]:
            return False
        
        return True
    
    # AML/CFT compliance methods
    
    def screen_entity(self, request: AMLScreeningRequest) -> AMLScreeningResponse:
        """
        Screen an entity against AML/CFT watchlists.
        
        Args:
            request: AML screening request
            
        Returns:
            AML screening response
        """
        # Generate screening ID
        screening_id = f"aml-{request.entity_type}-{request.entity_id}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # Log for audit
        logger.info(f"AML screening {screening_id} for {request.entity_type} {request.entity_name}")
        
        # In production, this would call external screening services
        # Mock implementation with random results
        import random
        
        risk_score = random.uniform(0.0, 1.0)
        
        if risk_score < 0.3:
            risk_level = "LOW"
            matches = []
        elif risk_score < 0.7:
            risk_level = "MEDIUM"
            matches = [
                {
                    "list_type": "PEP",
                    "match_score": 0.7,
                    "entity_name": request.entity_name,
                    "source": "Internal PEP Database",
                }
            ]
        else:
            risk_level = "HIGH"
            matches = [
                {
                    "list_type": "SANCTIONS",
                    "match_score": 0.9,
                    "entity_name": request.entity_name,
                    "source": "OFAC",
                }
            ]
        
        # Create response
        response = AMLScreeningResponse(
            screening_id=screening_id,
            entity_id=request.entity_id,
            entity_type=request.entity_type,
            status="COMPLETED",
            risk_score=risk_score,
            risk_level=risk_level,
            matches=matches,
            created_at=datetime.now(),
        )
        
        # Store screening result
        self._aml_screenings[screening_id] = response.dict()
        
        return response
    
    def get_screening_result(self, screening_id: str) -> Optional[AMLScreeningResponse]:
        """
        Get an AML screening result.
        
        Args:
            screening_id: Screening ID
            
        Returns:
            AML screening response or None if not found
        """
        if screening_id in self._aml_screenings:
            data = self._aml_screenings[screening_id]
            return AMLScreeningResponse(**data)
        return None
    
    def schedule_rescreening(self, entity_id: str, entity_type: str) -> str:
        """
        Schedule periodic rescreening for an entity.
        
        Args:
            entity_id: Entity ID
            entity_type: Entity type
            
        Returns:
            Scheduled screening ID
        """
        # In production, this would create a scheduled job
        next_screening_date = datetime.now() + timedelta(days=self.config["aml"]["rescreening_interval_days"])
        
        scheduled_id = f"scheduled-{entity_type}-{entity_id}-{next_screening_date.strftime('%Y%m%d')}"
        
        logger.info(f"Scheduled rescreening {scheduled_id} for {entity_type} {entity_id} on {next_screening_date.isoformat()}")
        
        return scheduled_id

# Initialize compliance service
compliance_service = ComplianceService()

# GDPR endpoints
@app.post("/gdpr/data-requests", response_model=GDPRDataResponse)
async def create_gdpr_request(request: GDPRDataRequest, background_tasks: BackgroundTasks):
    """
    Create a new GDPR data request (export, delete, etc.)
    """
    try:
        response = compliance_service.process_gdpr_request(request)
        return response
    except Exception as e:
        logger.error(f"Error processing GDPR request: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process GDPR request: {str(e)}"
        )

@app.get("/gdpr/data-requests/{request_id}", response_model=GDPRDataResponse)
async def get_gdpr_request(request_id: str):
    """
    Get the status of a GDPR data request
    """
    response = compliance_service.get_gdpr_request_status(request_id)
    if not response:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"GDPR request {request_id} not found"
        )
    return response

# PSD2 endpoints
@app.post("/psd2/consents", response_model=PSD2AuthResponse)
async def create_psd2_consent(request: PSD2AuthRequest):
    """
    Create a new PSD2 consent for third-party access
    """
    try:
        response = compliance_service.create_psd2_consent(request)
        return response
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error creating PSD2 consent: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create PSD2 consent: {str(e)}"
        )

@app.delete("/psd2/consents/{consent_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_psd2_consent(consent_id: str):
    """
    Revoke a PSD2 consent
    """
    success = compliance_service.revoke_psd2_consent(consent_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"PSD2 consent {consent_id} not found"
        )

@app.get("/psd2/consents/{consent_id}/validate")
async def validate_psd2_consent(consent_id: str, scope: str):
    """
    Validate a PSD2 consent for a specific scope
    """
    valid = compliance_service.validate_psd2_consent(consent_id, scope)
    return {"valid": valid}

# AML/CFT endpoints
@app.post("/aml/screening", response_model=AMLScreeningResponse)
async def screen_entity(request: AMLScreeningRequest):
    """
    Screen an entity against AML/CFT watchlists
    """
    try:
        response = compliance_service.screen_entity(request)
        return response
    except Exception as e:
        logger.error(f"Error screening entity: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to screen entity: {str(e)}"
        )

@app.get("/aml/screening/{screening_id}", response_model=AMLScreeningResponse)
async def get_screening_result(screening_id: str):
    """
    Get an AML screening result
    """
    response = compliance_service.get_screening_result(screening_id)
    if not response:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Screening {screening_id} not found"
        )
    return response

@app.post("/aml/reschedule/{entity_type}/{entity_id}")
async def schedule_rescreening(entity_type: str, entity_id: str):
    """
    Schedule periodic rescreening for an entity
    """
    try:
        scheduled_id = compliance_service.schedule_rescreening(entity_id, entity_type)
        return {"scheduled_id": scheduled_id}
    except Exception as e:
        logger.error(f"Error scheduling rescreening: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to schedule rescreening: {str(e)}"
        )

# Health check endpoint
@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    """
    Health check endpoint for monitoring
    """
    return {
        "status": "healthy",
        "service": "compliance-service",
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8002")))
