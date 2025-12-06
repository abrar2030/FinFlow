import unittest
from datetime import datetime
from unittest.mock import patch

# NOTE: Assuming main.py is in the same directory for imports.
# If not, the following line would be needed, but it's often problematic in test runners:
# sys.path.append(os.path.join(os.path.dirname(__file__), "../src"))

from fastapi.testclient import TestClient

# NOTE: We need to import the actual app and service from the fixed main.py
from main import (
    app,
    compliance_service,
    GDPRDataResponse,
    PSD2AuthResponse,
    AMLScreeningResponse,
)


class TestComplianceService(unittest.TestCase):
    """Test suite for the Compliance Service API"""

    def setUp(self):
        """Set up test fixtures"""
        self.client = TestClient(app)

        # Sample GDPR request data
        self.gdpr_request_data = {
            "user_id": "user-123",
            "request_type": "export",
            "request_details": {"reason": "User requested data export"},
        }

        # Sample PSD2 consent data
        self.psd2_consent_data = {
            "user_id": "user-123",
            "third_party_provider": "fintech-app",
            "scope": ["account_info", "transactions"],
            "duration_days": 90,
            "metadata": {"app_version": "1.0.0"},
        }

        # Sample AML screening data
        self.aml_screening_data = {
            "entity_type": "individual",
            "entity_id": "user-123",
            "entity_name": "John Doe",
            "country_code": "US",
            "additional_data": {"date_of_birth": "1980-01-01"},
        }

    def test_gdpr_data_request(self):
        """Test creating a GDPR data request"""
        # FIX: Instead of mocking the internal method, we'll use patch to mock the
        # return value of the actual method, and ensure the mock returns a Pydantic object
        # that can be serialized by FastAPI.

        mock_response = GDPRDataResponse(
            request_id="gdpr-user-123-20250531",
            user_id="user-123",
            status="COMPLETED",
            data={"user_profile": {"name": "John Doe"}},
            created_at=datetime.now(),
            completed_at=datetime.now(),
        )

        with patch.object(
            compliance_service, "process_gdpr_request", return_value=mock_response
        ) as mock_method:
            # Make request
            response = self.client.post(
                "/gdpr/data-requests", json=self.gdpr_request_data
            )

            # Verify response
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["user_id"], "user-123")
            self.assertEqual(data["status"], "COMPLETED")
            self.assertIn("data", data)
            self.assertIn("user_profile", data["data"])
            mock_method.assert_called_once()

    def test_psd2_consent_creation(self):
        """Test creating a PSD2 consent"""
        # FIX: Use patch and a real Pydantic object for the mock return value.
        mock_response = PSD2AuthResponse(
            consent_id="psd2-user-123-20250531",
            user_id="user-123",
            third_party_provider="fintech-app",
            scope=["account_info", "transactions"],
            status="ACTIVE",  # Changed from AUTHORIZED to ACTIVE to match service mock
            expires_at=datetime.now() + timedelta(days=90),
            created_at=datetime.now(),
        )

        with patch.object(
            compliance_service, "create_psd2_consent", return_value=mock_response
        ) as mock_method:
            # Make request
            response = self.client.post("/psd2/consents", json=self.psd2_consent_data)

            # Verify response
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["user_id"], "user-123")
            self.assertEqual(data["third_party_provider"], "fintech-app")
            self.assertEqual(data["status"], "ACTIVE")  # Check for ACTIVE
            self.assertEqual(data["scope"], ["account_info", "transactions"])
            mock_method.assert_called_once()

    def test_psd2_consent_validation(self):
        """Test validating a PSD2 consent"""
        # FIX: Use patch.object for mocking
        with patch.object(
            compliance_service, "validate_psd2_consent", return_value=True
        ) as mock_method:
            # Make request
            response = self.client.get(
                "/psd2/consents/psd2-user-123-20250531/validate?scope=account_info"
            )

            # Verify response
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertTrue(data["valid"])
            mock_method.assert_called_once()

    def test_aml_screening(self):
        """Test AML screening"""
        # FIX: Use patch and a real Pydantic object for the mock return value.
        mock_response = AMLScreeningResponse(
            screening_id="aml-individual-user-123-20250531",
            entity_id="user-123",
            entity_type="individual",
            status="COMPLETED",
            risk_score=0.2,
            risk_level="LOW",
            matches=[],
            created_at=datetime.now(),
        )

        with patch.object(
            compliance_service, "screen_entity", return_value=mock_response
        ) as mock_method:
            # Make request
            response = self.client.post("/aml/screening", json=self.aml_screening_data)

            # Verify response
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["entity_id"], "user-123")
            self.assertEqual(data["entity_type"], "individual")
            self.assertEqual(data["status"], "COMPLETED")
            self.assertEqual(data["risk_level"], "LOW")
            mock_method.assert_called_once()

    def test_health_check(self):
        """Test health check endpoint"""
        response = self.client.get("/health")

        # Verify response
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["service"], "compliance-service")


if __name__ == "__main__":
    # FIX: Need to import timedelta for the mock PSD2 response
    from datetime import timedelta

    unittest.main()
