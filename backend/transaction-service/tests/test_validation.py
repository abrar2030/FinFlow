# import json
# import os
# import sys
# import unittest
# from datetime import datetime
# from unittest.mock import MagicMock, patch

# Add src directory to path for imports
# sys.path.append(os.path.join(os.path.dirname(__file__), "../src"))

# from models import RiskLevel, TransactionRequest, TransactionType
# from validation import BatchTransactionValidator, TransactionValidator


# class TestTransactionValidator(unittest.TestCase):
#    """Test suite for the TransactionValidator class"""
#
##     def setUp(self):
#        """Set up test fixtures"""
#         self.validator = TransactionValidator()

# Create a valid transaction request for testing
#         self.valid_transaction = TransactionRequest(
#             transaction_id="tx-12345",
#             source_account_id="account-123",
#             destination_account_id="account-456",
#             amount=1000.0,
#             currency="USD",
#             transaction_type=TransactionType.TRANSFER,
#             reference="REF123",
#             description="Test transaction",
#        )

# Context for validation
#         self.context = {
#            "user_id": "user-123",
#           "ip_address": "192.168.1.1",
#           "device_fingerprint": "device-123",
#           "country_code": "US",
#       }

#     def test_validate_valid_transaction(self):
#        """Test validation of a valid transaction"""
##         result = self.validator.validate_transaction(
##             self.valid_transaction, self.context
#        )
#
##         self.assertTrue(result.is_valid)
##         self.assertLess(
##             result.risk_score, 0.5
##         )  # Assuming low risk for this transaction
##         self.assertEqual(result.risk_level, RiskLevel.LOW)
##         self.assertTrue(result.validation_checks["basic_fields_valid"])
##         self.assertTrue(result.validation_checks["amount_valid"])
##         self.assertTrue(result.validation_checks["accounts_valid"])
##         self.assertEqual(len(result.errors), 0)
#
##     def test_validate_invalid_amount(self):
#        """Test validation of a transaction with invalid amount"""
# Create transaction with negative amount
#         invalid_transaction = self.valid_transaction.copy()
#         invalid_transaction.amount = -100.0

# Mock the _validate_amount method to simulate failure
#         with patch.object(self.validator, "_validate_amount") as mock_validate:
#             mock_validate.return_value = (
#                 False,
#                [
#                    {
#                        "code": "INVALID_AMOUNT",
#                        "message": "Amount must be positive",
#                        "field": "amount",
#                    }
#                ],
#                [],
#            )

#             result = self.validator.validate_transaction(
#                 invalid_transaction, self.context
#            )

#             self.assertFalse(result.is_valid)
#             self.assertFalse(result.validation_checks["amount_valid"])
#             self.assertTrue(any(e.code == "INVALID_AMOUNT" for e in result.errors))

#     def test_validate_high_risk_transaction(self):
#        """Test validation of a high-risk transaction"""
#        # Create high-value transaction
##         high_risk_transaction = self.valid_transaction.copy()
##         high_risk_transaction.amount = 100000.0
#
#        # Mock the risk calculation to ensure high risk
##         with patch.object(self.validator, "_calculate_risk_score") as mock_risk:
##             mock_risk.return_value = 0.85  # High risk score
#
##             result = self.validator.validate_transaction(
##                 high_risk_transaction, self.context
#            )
#
##             self.assertTrue(result.is_valid)  # Still valid, just high risk
##             self.assertGreater(result.risk_score, 0.8)
##             self.assertEqual(result.risk_level, RiskLevel.CRITICAL)
#
##     def test_validate_transaction_velocity(self):
#        """Test validation of transaction velocity"""
# Mock the velocity validation to simulate exceeding limits
#         with patch.object(
#             self.validator, "_validate_transaction_velocity"
#         ) as mock_velocity:
#             mock_velocity.return_value = (
#                 False,
#                [
#                    {
#                        "code": "VELOCITY_EXCEEDED",
#                        "message": "Transaction frequency exceeds limits",
#                        "field": "transaction_id",
#                    }
#                ],
#                [],
#            )

#             result = self.validator.validate_transaction(
#                 self.valid_transaction, self.context
#            )

#             self.assertFalse(result.is_valid)
#             self.assertFalse(result.validation_checks["velocity_valid"])
#             self.assertTrue(any(e.code == "VELOCITY_EXCEEDED" for e in result.errors))

#     def test_batch_validation(self):
#        """Test batch validation of transactions"""
##         batch_validator = BatchTransactionValidator(self.validator)
#
#        # Create a batch of transactions
##         transactions = [
##             self.valid_transaction,
##             TransactionRequest(
##                 transaction_id="tx-67890",
##                 source_account_id="account-123",
##                 destination_account_id="account-789",
##                 amount=500.0,
##                 currency="USD",
##                 transaction_type=TransactionType.TRANSFER,
##                 reference="REF456",
##                 description="Another test transaction",
#            ),
#        ]
#
##         results = batch_validator.validate_batch(transactions, self.context)
#
##         self.assertEqual(len(results), 2)
##         self.assertTrue(all(r.is_valid for r in results.values()))
#
#
## class TestBatchTransactionValidator(unittest.TestCase):
#    """Test suite for the BatchTransactionValidator class"""

#     def setUp(self):
#        """Set up test fixtures"""
##         self.mock_validator = MagicMock()
##         self.batch_validator = BatchTransactionValidator(self.mock_validator)
#
#        # Create test transactions
##         self.transactions = [
##             TransactionRequest(
##                 transaction_id=f"tx-{i}",
##                 source_account_id="account-123",
##                 destination_account_id="account-456",
##                 amount=1000.0 * (i + 1),
##                 currency="USD",
##                 transaction_type=TransactionType.TRANSFER,
##                 reference=f"REF{i}",
##                 description=f"Test transaction {i}",
#            )
##             for i in range(3)
#        ]
#
##         self.context = {"user_id": "user-123"}
#
##     def test_validate_batch(self):
#        """Test batch validation with mock validator"""
# Configure mock validator to return valid results
#         self.mock_validator.validate_transaction.side_effect = (
#             lambda tx, ctx: MagicMock(
#                 is_valid=True,
#                 risk_score=0.2,
#                 risk_level=RiskLevel.LOW,
#                 validation_checks={"basic_fields_valid": True},
#                 errors=[],
#            )
#        )

#         results = self.batch_validator.validate_batch(self.transactions, self.context)

# Verify results
#         self.assertEqual(len(results), 3)
#         self.assertEqual(self.mock_validator.validate_transaction.call_count, 3)

# Verify each transaction was validated
#         for tx in self.transactions:
#             self.assertIn(tx.transaction_id, results)
#             self.assertTrue(results[tx.transaction_id].is_valid)

#     def test_batch_with_mixed_results(self):
#        """Test batch validation with mixed valid/invalid results"""
#
#        # Configure mock validator to return mixed results
##         def side_effect(tx, ctx):
#            # Make the second transaction invalid
##             if tx.transaction_id == "tx-1":
##                 return MagicMock(
##                     is_valid=False,
##                     risk_score=0.7,
##                     risk_level=RiskLevel.HIGH,
##                     validation_checks={"amount_valid": False},
##                     errors=[MagicMock(code="INVALID_AMOUNT")],
#                )
##             return MagicMock(
##                 is_valid=True,
##                 risk_score=0.2,
##                 risk_level=RiskLevel.LOW,
##                 validation_checks={"basic_fields_valid": True},
##                 errors=[],
#            )
#
##         self.mock_validator.validate_transaction.side_effect = side_effect
#
##         results = self.batch_validator.validate_batch(self.transactions, self.context)
#
#        # Verify results
##         self.assertEqual(len(results), 3)
##         self.assertTrue(results["tx-0"].is_valid)
##         self.assertFalse(results["tx-1"].is_valid)
##         self.assertTrue(results["tx-2"].is_valid)
#
#
## if __name__ == "__main__":
##     unittest.main()
