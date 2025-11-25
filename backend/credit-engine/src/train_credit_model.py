import logging
import os

import joblib
import numpy as np
from sklearn.datasets import make_classification
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score

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
    # Improvement: Use make_regression for a regression task, or adjust make_classification
    # to better suit the problem. Since the target is converted to a score (regression),
    # I will stick with make_classification and adjust the target, but note the potential
    # for using make_regression.
    X, y = make_classification(
        n_samples=1000,
        n_features=4,
        n_classes=3,
        n_informative=4,
        n_redundant=0,
        random_state=42,
    )

    # Scale features to realistic ranges
    # Feature 0: income
    X[:, 0] = np.abs(X[:, 0] * 50000 + 50000)  # income: $50k-150k (approx)
    # Feature 1: numInvoices
    X[:, 1] = np.abs(X[:, 1] * 20 + 10).astype(int)  # numInvoices: 10-30 (approx)
    # Feature 2: avgCashflow
    X[:, 2] = np.abs(X[:, 2] * 5000 + 5000)  # avgCashflow: $5k-15k (approx)
    # Feature 3: delinquencies
    X[:, 3] = np.abs(X[:, 3] * 2).astype(int)  # delinquencies: 0-2 (approx)

    # Convert classification target to regression (credit score 0.1-0.9)
    # The original mapping was: 0 -> 0.35, 1 -> 0.6, 2 -> 0.85
    # y = (y + 1) / 4 + 0.1  # Map to 0.1-0.9 range
    # Let's use a cleaner mapping:
    # Class 0 (low risk) -> high score (0.8-0.9)
    # Class 1 (medium risk) -> medium score (0.5-0.7)
    # Class 2 (high risk) -> low score (0.1-0.4)
    # Since make_classification generates classes 0, 1, 2, we can map them.
    # A simple linear map is fine for synthetic data.
    # y_score = 0.9 - (y / (np.max(y) + 1)) * 0.8 # Simple inverse mapping
    # Let's stick to the original logic for minimal change, but ensure it's correct.
    # Original: y=0 -> 0.35, y=1 -> 0.6, y=2 -> 0.85. This is an inverse risk-score.
    # I will reverse it to match standard credit score logic (higher score = lower risk).
    y_adjusted = np.max(y) - y  # Reverse the class order: 2->0, 1->1, 0->2
    y_score = (y_adjusted + 1) / 4 + 0.1  # Map to 0.35, 0.6, 0.85

    logger.info(f"Data generated: {X.shape[0]} samples with {X.shape[1]} features")

    # Split data into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(
        X, y_score, test_size=0.2, random_state=42
    )
    logger.info(
        f"Training set: {X_train.shape[0]} samples, Test set: {X_test.shape[0]} samples"
    )

    # Train a Random Forest Regressor
    logger.info("Training Random Forest Regressor model")
    # Improvement: Increase n_estimators for better performance
    clf = RandomForestRegressor(n_estimators=200, random_state=42, n_jobs=-1)
    clf.fit(X_train, y_train)

    # Evaluate model
    y_pred = clf.predict(X_test)
    r2_score(y_test, y_pred)
    mse = mean_squared_error(y_test, y_pred)

    train_score = clf.score(X_train, y_train)
    test_score = clf.score(X_test, y_test)

    logger.info(f"Model R² score - Training: {train_score:.4f}, Test: {test_score:.4f}")
    logger.info(f"Model Mean Squared Error (MSE) on Test Set: {mse:.4f}")

    # Save model
    # Fix: The path was relative to the current directory, but the intent was likely to save
    # it in a 'models' directory at the project root. Using a relative path from the current
    # execution context is safer. I will use a local 'models' directory.
    model_dir = "models"
    os.makedirs(model_dir, exist_ok=True)
    model_path = os.path.join(model_dir, "credit_score_model.pkl")

    logger.info(f"Saving model to {model_path}")
    joblib.dump(clf, model_path)

    logger.info("Credit model training completed successfully")
    return clf


if __name__ == "__main__":
    # Create models directory if it doesn't exist
    # This is redundant as it's done inside the function, but kept for robustness
    # if the function is called externally.
    if not os.path.exists("models"):
        os.makedirs("models")

    # Train and save the model
    train_credit_model()
