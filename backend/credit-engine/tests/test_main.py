# from unittest.mock import MagicMock, patch

# import pytest
# from fastapi.testclient import TestClient
# from src.main import app

# client = TestClient(app)


# Mock JWT token validation to always succeed
# @pytest.fixture(autouse=True)
# def mock_jwt_validation():
#     with patch(
        "src.main.get_current_user", return_value={"sub": "test-user", "role": "USER"}
    ):
#         yield


# def test_health_check():
#     response = client.get("/health")
#     assert response.status_code == 200
#     assert response.json()["status"] == "healthy"
#     assert response.json()["service"] == "credit-engine"


# def test_credit_score():
    # Test data
#     test_data = {
        "income": 75000,
        "numInvoices": 12,
        "avgCashflow": 6500,
        "delinquencies": 0,
    }

#     response = client.post("/score", json=test_data)
#     assert response.status_code == 200

    # Check response structure
#     data = response.json()
#     assert "credit_score" in data
#     assert "risk_category" in data
#     assert "timestamp" in data

    # Check score is in valid range
#     assert 0 <= data["credit_score"] <= 1

    # Check risk category is valid
#     assert data["risk_category"] in ["LOW_RISK", "MEDIUM_RISK", "HIGH_RISK"]


# def test_loan_offers():
#     response = client.get("/offers?score=0.85")
#     assert response.status_code == 200

    # Check response structure
#     data = response.json()
#     assert "credit_score" in data
#     assert "offers" in data
#     assert "timestamp" in data

    # Check offers are present
#     assert len(data["offers"]) > 0

    # Check first offer structure
#     offer = data["offers"][0]
#     assert "amount" in offer
#     assert "interest_rate" in offer
#     assert "term_months" in offer
#     assert "monthly_payment" in offer


# def test_gdpr_export():
#     response = client.get("/user/data")
#     assert response.status_code == 200

    # Check response structure
#     data = response.json()
#     assert "user_id" in data
#     assert "credit_scores" in data
#     assert "loan_applications" in data


# def test_gdpr_delete():
#     response = client.delete("/user/data")
#     assert response.status_code == 204
