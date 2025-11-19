# import json
# import logging
# import os
# from datetime import datetime
# from typing import Any, Dict, List, Optional

# import joblib
# from fastapi import Depends, FastAPI, HTTPException, status
# from fastapi.middleware.cors import CORSMiddleware
# from fastapi.security import OAuth2PasswordBearer
# from pydantic import BaseModel

# Configure logging
# logging.basicConfig(
#     level=logging.INFO,
#     format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
# logger = logging.getLogger("credit-engine")

# Initialize FastAPI app
# app = FastAPI(
#     title="FinFlow Credit Engine",
#     description="AI-driven credit scoring and loan offers API",
#     version="1.0.0",
)

# Add CORS middleware
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],  # In production, replace with specific origins
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
)

# OAuth2 scheme for JWT validation
# oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


# Load model (in production, this would be a trained model)
# For demo purposes, we'll create a simple model that returns predefined scores
# class CreditModel:
#     def predict(self, features):
        # Simple logic for demo: higher income and cashflow = higher score
#         income, num_invoices, avg_cashflow, delinquencies = features
#         base_score = min(0.9, (income / 10000) * 0.5 + (avg_cashflow / 5000) * 0.5)
#         penalty = delinquencies * 0.1
#         return max(0.1, min(0.9, base_score - penalty))


# Initialize model
# try:
    # In production: credit_model = joblib.load('models/credit_score_model.pkl')
#     credit_model = CreditModel()
#     logger.info("Credit scoring model loaded successfully")
# except Exception as e:
#     logger.error(f"Failed to load credit scoring model: {e}")
#     credit_model = None


# Pydantic models for request/response validation
# class CreditScoreRequest(BaseModel):
#     income: float
#     numInvoices: int
#     avgCashflow: float
#     delinquencies: int


# class CreditScoreResponse(BaseModel):
#     credit_score: float
#     risk_category: str
#     timestamp: str


# class LoanOffer(BaseModel):
#     amount: float
#     interest_rate: float
#     term_months: int
#     monthly_payment: float


# class LoanOffersResponse(BaseModel):
#     credit_score: float
#     offers: List[LoanOffer]
#     timestamp: str


# JWT validation dependency
# async def get_current_user(token: str = Depends(oauth2_scheme)):
    # In production, this would validate the JWT against Auth service
    # For demo, we'll just log and accept any token
#     logger.info(f"Received token: {token[:10]}...")
#     return {"sub": "demo-user", "role": "USER"}


# Endpoints
# @app.post("/score", response_model=CreditScoreResponse)
# async def score_credit(
#     input_data: CreditScoreRequest, current_user: dict = Depends(get_current_user)
):
#    """"""
##     Calculate credit score based on financial metrics
#    """"""
#     if not credit_model:
#         raise HTTPException(
#             status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
#             detail="Credit scoring model is not available",
        )

    # Log the request (audit logging)
#     logger.info(
#         f"Credit score request for user {current_user['sub']}: {json.dumps(input_data.dict())}"
    )

#     try:
        # Extract features in the expected order
#         features = [
#             input_data.income,
#             input_data.numInvoices,
#             input_data.avgCashflow,
#             input_data.delinquencies,
        ]

        # Get prediction from model
#         score = credit_model.predict(features)

        # Determine risk category
#         if score >= 0.8:
#             risk_category = "LOW_RISK"
#         elif score >= 0.6:
#             risk_category = "MEDIUM_RISK"
#         else:
#             risk_category = "HIGH_RISK"

        # Create response
#         response = CreditScoreResponse(
#             credit_score=score,
#             risk_category=risk_category,
#             timestamp=datetime.now().isoformat(),
        )

        # Log the response (audit logging)
#         logger.info(
#             f"Credit score response for user {current_user['sub']}: {json.dumps(response.dict())}"
        )

#         return response

#     except Exception as e:
#         logger.error(f"Error calculating credit score: {e}")
#         raise HTTPException(
#             status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
#             detail="Failed to calculate credit score",
        )


# @app.get("/offers", response_model=LoanOffersResponse)
# async def get_loan_offers(
#     score: Optional[float] = None, current_user: dict = Depends(get_current_user)
):
#    """"""
##     Get loan offers based on credit score
#    """"""
    # If no score provided, use a default medium score
#     if score is None:
#         score = 0.7

    # Log the request (audit logging)
#     logger.info(
#         f"Loan offers request for user {current_user['sub']} with score {score}"
    )

    # Generate offers based on score
#     offers = []

#     if score >= 0.8:
        # Low risk - best offers
#         offers = [
#             LoanOffer(
#                 amount=50000, interest_rate=4.5, term_months=60, monthly_payment=932.78
            ),
#             LoanOffer(
#                 amount=25000, interest_rate=4.2, term_months=36, monthly_payment=738.99
            ),
#             LoanOffer(
#                 amount=10000, interest_rate=3.9, term_months=24, monthly_payment=434.65
            ),
        ]
#     elif score >= 0.6:
        # Medium risk
#         offers = [
#             LoanOffer(
#                 amount=25000, interest_rate=6.5, term_months=60, monthly_payment=488.75
            ),
#             LoanOffer(
#                 amount=10000, interest_rate=6.2, term_months=36, monthly_payment=304.98
            ),
#             LoanOffer(
#                 amount=5000, interest_rate=5.9, term_months=24, monthly_payment=221.24
            ),
        ]
#     else:
        # High risk - limited offers
#         offers = [
#             LoanOffer(
#                 amount=5000, interest_rate=9.9, term_months=36, monthly_payment=161.42
            ),
#             LoanOffer(
#                 amount=2500, interest_rate=8.9, term_months=24, monthly_payment=114.58
            ),
        ]

    # Create response
#     response = LoanOffersResponse(
#         credit_score=score, offers=offers, timestamp=datetime.now().isoformat()
    )

    # Log the response (audit logging)
#     logger.info(
#         f"Loan offers response for user {current_user['sub']}: {len(offers)} offers provided"
    )

#     return response


# GDPR compliance endpoints
# @app.get("/user/data", status_code=status.HTTP_200_OK)
# async def export_user_data(current_user: dict = Depends(get_current_user)):
#    """"""
##     Export all user data (GDPR compliance)
#    """"""
#     logger.info(f"Data export request for user {current_user['sub']}")

    # In production, this would query the database for all user data
    # For demo, we return sample data
#     return {
        "user_id": current_user["sub"],
        "credit_scores": [
            {
                "score": 0.75,
                "risk_category": "MEDIUM_RISK",
                "timestamp": "2025-01-15T14:30:00",
            },
            {
                "score": 0.82,
                "risk_category": "LOW_RISK",
                "timestamp": "2025-04-20T09:15:00",
            },
        ],
        "loan_applications": [
#             {"amount": 10000, "status": "APPROVED", "timestamp": "2025-01-16T10:45:00"}
        ],
    }


# @app.delete("/user/data", status_code=status.HTTP_204_NO_CONTENT)
# async def delete_user_data(current_user: dict = Depends(get_current_user)):
#    """"""
##     Delete all user data (GDPR compliance)
#    """"""
#     logger.info(f"Data deletion request for user {current_user['sub']}")

    # In production, this would delete all user data from the database
    # For demo, we just log the request
#     logger.info(f"User data deletion completed for user {current_user['sub']}")

    # Publish user_deleted event to Kafka
    # In production: await kafka_producer.send("user_deleted", {"user_id": current_user['sub']})

#     return None


# Health check endpoint
# @app.get("/health", status_code=status.HTTP_200_OK)
# async def health_check():
#    """"""
##     Health check endpoint for monitoring
#    """"""
#     return {"status": "healthy", "service": "credit-engine"}


# if __name__ == "__main__":
#     import uvicorn

#     uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
