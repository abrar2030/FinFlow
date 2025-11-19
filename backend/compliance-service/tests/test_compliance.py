import unittest
from unittest.mock import patch, MagicMock
import sys
import os
import json
from datetime import datetime

# Add src directory to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '../src'))

from main import app, compliance_service
from fastapi.testclient import TestClient

class TestComplianceService(unittest.TestCase):
    """Test suite for the Compliance Service API"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.client = TestClient(app)
        
        # Sample GDPR request data
        self.gdpr_request_data = {
            "user_id": "user-123",
            "request_type": "export",
            "request_details": {"reason": "User requested data export"}
        }
        
        # Sample PSD2 consent data
        self.psd2_consent_data = {
            "user_id": "user-123",
            "third_party_provider": "fintech-app",
            "scope": ["account_info", "transactions"],
            "duration_days": 90,
            "metadata": {"app_version": "1.0.0"}
        }
        
        # Sample AML screening data
        self.aml_screening_data = {
            "entity_type": "individual",
            "entity_id": "user-123",
            "entity_name": "John Doe",
            "country_code": "US",
            "additional_data": {"date_of_birth": "1980-01-01"}
        }
    
    def test_gdpr_data_request(self):
        """Test creating a GDPR data request"""
        # Mock the process_gdpr_request method
        original_method = compliance_service.process_gdpr_request
        
        try:
            # Replace with mock
            mock_response = MagicMock(
                request_id="gdpr-user-123-20250531",
                user_id="user-123",
                status="COMPLETED",
                data={"user_profile": {"name": "John Doe"}},
                created_at=datetime.now(),
                completed_at=datetime.now()
            )
            compliance_service.process_gdpr_request = MagicMock(return_value=mock_response)
            
            # Make request
            response = self.client.post("/gdpr/data-requests", json=self.gdpr_request_data)
            
            # Verify response
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["user_id"], "user-123")
            self.assertEqual(data["status"], "COMPLETED")
            self.assertIn("data", data)
            self.assertIn("user_profile", data["data"])
            
        finally:
            # Restore original method
            compliance_service.process_gdpr_request = original_method
    
    def test_psd2_consent_creation(self):
        """Test creating a PSD2 consent"""
        # Mock the create_psd2_consent method
        original_method = compliance_service.create_psd2_consent
        
        try:
            # Replace with mock
            mock_response = MagicMock(
                consent_id="psd2-user-123-20250531",
                user_id="user-123",
                third_party_provider="fintech-app",
                scope=["account_info", "transactions"],
                status="AUTHORIZED",
                expires_at=datetime.now(),
                created_at=datetime.now()
            )
            compliance_service.create_psd2_consent = MagicMock(return_value=mock_response)
            
            # Make request
            response = self.client.post("/psd2/consents", json=self.psd2_consent_data)
            
            # Verify response
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["user_id"], "user-123")
            self.assertEqual(data["third_party_provider"], "fintech-app")
            self.assertEqual(data["status"], "AUTHORIZED")
            self.assertEqual(data["scope"], ["account_info", "transactions"])
            
        finally:
            # Restore original method
            compliance_service.create_psd2_consent = original_method
    
    def test_psd2_consent_validation(self):
        """Test validating a PSD2 consent"""
        # Mock the validate_psd2_consent method
        original_method = compliance_service.validate_psd2_consent
        
        try:
            # Replace with mock
            compliance_service.validate_psd2_consent = MagicMock(return_value=True)
            
            # Make request
            response = self.client.get("/psd2/consents/psd2-user-123-20250531/validate?scope=account_info")
            
            # Verify response
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertTrue(data["valid"])
            
        finally:
            # Restore original method
            compliance_service.validate_psd2_consent = original_method
    
    def test_aml_screening(self):
        """Test AML screening"""
        # Mock the screen_entity method
        original_method = compliance_service.screen_entity
        
        try:
            # Replace with mock
            mock_response = MagicMock(
                screening_id="aml-individual-user-123-20250531",
                entity_id="user-123",
                entity_type="individual",
                status="COMPLETED",
                risk_score=0.2,
                risk_level="LOW",
                matches=[],
                created_at=datetime.now()
            )
            compliance_service.screen_entity = MagicMock(return_value=mock_response)
            
            # Make request
            response = self.client.post("/aml/screening", json=self.aml_screening_data)
            
            # Verify response
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["entity_id"], "user-123")
            self.assertEqual(data["entity_type"], "individual")
            self.assertEqual(data["status"], "COMPLETED")
            self.assertEqual(data["risk_level"], "LOW")
            
        finally:
            # Restore original method
            compliance_service.screen_entity = original_method
    
    def test_health_check(self):
        """Test health check endpoint"""
        response = self.client.get("/health")
        
        # Verify response
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["service"], "compliance-service")


if __name__ == '__main__':
    unittest.main()
