import logging

import joblib
import numpy as np
from sklearn.datasets import make_classification
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("credit-model-training")


def train_credit_model():
    """
    Train a credit scoring model using synthetic data
    """
    logger.info("Starting credit model training")

    # Generate synthetic features: income, numInvoices, avgCashflow, paymentDelinquencies
    logger.info("Generating synthetic training data")
    X, y = make_classification(
        n_samples=1000, n_features=4, n_classes=3, random_state=42
    )

    # Scale features to realistic ranges
    X[:, 0] = X[:, 0] * 50000 + 50000  # income: $0-100k
    X[:, 1] = np.abs(X[:, 1] * 20 + 10).astype(int)  # numInvoices: 0-30
    X[:, 2] = X[:, 2] * 5000 + 5000  # avgCashflow: $0-10k
    X[:, 3] = np.abs(X[:, 3] * 2).astype(int)  # delinquencies: 0-2

    # Convert classification target to regression (credit score 0.1-0.9)
    y = (y + 1) / 4 + 0.1  # Map to 0.1-0.9 range

    logger.info(f"Data generated: {X.shape[0]} samples with {X.shape[1]} features")

    # Split data into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    logger.info(
        f"Training set: {X_train.shape[0]} samples, Test set: {X_test.shape[0]} samples"
    )

    # Train a Random Forest Regressor
    logger.info("Training Random Forest Regressor model")
    clf = RandomForestRegressor(n_estimators=100, random_state=42)
    clf.fit(X_train, y_train)

    # Evaluate model
    train_score = clf.score(X_train, y_train)
    test_score = clf.score(X_test, y_test)
    logger.info(f"Model R² score - Training: {train_score:.4f}, Test: {test_score:.4f}")

    # Save model
    model_path = "../models/credit_score_model.pkl"
    logger.info(f"Saving model to {model_path}")
    joblib.dump(clf, model_path)

    logger.info("Credit model training completed successfully")
    return clf


if __name__ == "__main__":
    # Create models directory if it doesn't exist
    import os

    os.makedirs("../models", exist_ok=True)

    # Train and save the model
    train_credit_model()
