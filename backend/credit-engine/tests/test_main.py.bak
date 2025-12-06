from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

# NOTE: Assuming main.py is in the same directory or importable from the test runner's path.
# If the project structure is src/main.py, the import should be 'from src.main import app'.
# Given the previous task, we assume 'main' is importable.
from main import app

client = TestClient(app)


# Mock JWT token validation to always succeed
@pytest.fixture(autouse=True)
def mock_jwt_validation():
    # Fix: The original patch path was likely incorrect.
    # We patch the dependency function directly in the main module.
    with patch(
        "main.get_current_user", return_value={"sub": "test-user", "role": "USER"}
    ):
        yield


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
    assert response.json()["service"] == "credit-engine"


def test_credit_score_low_risk():
    # Test data for a low-risk score (high income, low delinquencies)
    test_data = {
        "income": 150000,
        "numInvoices": 50,
        "avgCashflow": 15000,
        "delinquencies": 0,
    }

    response = client.post("/score", json=test_data)
    assert response.status_code == 200

    # Check response structure
    data = response.json()
    assert "credit_score" in data
    assert "risk_category" in data
    assert "timestamp" in data

    # Check score is in valid range
    assert 0.0 <= data["credit_score"] <= 1.0

    # Check risk category is valid and likely LOW_RISK
    assert data["risk_category"] == "LOW_RISK"


def test_credit_score_high_risk():
    # Test data for a high-risk score (low income, high delinquencies)
    test_data = {
        "income": 20000,
        "numInvoices": 5,
        "avgCashflow": 1000,
        "delinquencies": 5,
    }

    response = client.post("/score", json=test_data)
    assert response.status_code == 200
    data = response.json()
    assert data["risk_category"] == "HIGH_RISK"


def test_loan_offers_low_score():
    # Test for high-risk offers
    response = client.get("/offers?score=0.3")
    assert response.status_code == 200
    data = response.json()
    assert len(data["offers"]) == 2  # High risk gets 2 offers


def test_loan_offers_high_score():
    # Test for low-risk offers
    response = client.get("/offers?score=0.9")
    assert response.status_code == 200
    data = response.json()
    assert len(data["offers"]) == 3  # Low risk gets 3 offers

    # Check response structure
    assert "credit_score" in data
    assert "offers" in data
    assert "timestamp" in data

    # Check first offer structure
    offer = data["offers"][0]
    assert "amount" in offer
    assert "interest_rate" in offer
    assert "term_months" in offer
    assert "monthly_payment" in offer


def test_gdpr_export():
    response = client.get("/user/data")
    assert response.status_code == 200

    # Check response structure
    data = response.json()
    assert "user_id" == data["user_id"]
    assert "credit_scores" in data
    assert "loan_applications" in data


def test_gdpr_delete():
    response = client.delete("/user/data")
    assert response.status_code == 204
    # Check that the response body is empty for 204
    assert response.text == ""
