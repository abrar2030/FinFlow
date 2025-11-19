# import hashlib
# import json
# import logging
# import re
# from datetime import datetime, timedelta
# from typing import Any, Dict, List, Optional, Tuple

# from .models import (RiskLevel, TransactionRequest, TransactionType,
#                      ValidationError, ValidationResult)

# Configure logging
# logging.basicConfig(
#     level=logging.INFO,
#     format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
# logger = logging.getLogger("transaction-validation")


# class TransactionValidator:
#    """"""
##     Comprehensive transaction validation service that performs multiple validation checks
##     and risk assessments on financial transactions.
#    """"""

#     def __init__(self, config: Optional[Dict[str, Any]] = None):
#        """"""
##         Initialize the transaction validator with optional configuration.
#
##         Args:
##             config: Configuration dictionary with validation thresholds and settings
#        """"""
#         self.config = config or self._default_config()
#         self._transaction_history = {}  # In production, this would be a database/cache
#         logger.info("Transaction validator initialized with configuration")

#     def _default_config(self) -> Dict[str, Any]:
#        """"""
##         Default configuration for transaction validation.
#
##         Returns:
##             Dict containing default validation configuration
#        """"""
#         return {
            "amount_thresholds": {
                "high_value": 10000.0,
                "very_high_value": 50000.0,
                "max_daily_limit": 100000.0,
                "max_single_transaction": 1000000.0,
            },
            "velocity_thresholds": {
                "max_transactions_per_minute": 10,
                "max_transactions_per_hour": 50,
                "max_transactions_per_day": 200,
            },
            "risk_scoring": {
                "high_value_weight": 0.2,
                "velocity_weight": 0.3,
                "pattern_weight": 0.15,
                "account_history_weight": 0.2,
                "geographic_weight": 0.15,
            },
            "risk_levels": {
                "low_threshold": 0.3,
                "medium_threshold": 0.6,
                "high_threshold": 0.8,
            },
            "aml_checks": {
                "enabled": True,
                "check_sanctioned_countries": True,
                "check_pep_lists": True,
            },
            "fraud_detection": {
                "enabled": True,
                "check_ip_reputation": True,
                "check_device_fingerprint": True,
                "check_transaction_patterns": True,
            },
        }

#     def validate_transaction(
#         self, transaction: TransactionRequest, context: Optional[Dict[str, Any]] = None
#     ) -> ValidationResult:
#        """"""
##         Perform comprehensive validation on a transaction request.
#
##         Args:
##             transaction: The transaction request to validate
##             context: Additional context for validation (user info, device info, etc.)
#
##         Returns:
##             ValidationResult object with validation status and details
#        """"""
#         context = context or {}
#         validation_checks = {}
#         errors = []
#         warnings = []

        # Basic field validation (already done by Pydantic, but we can add custom logic)
#         validation_checks["basic_fields_valid"] = True

        # Amount validation
#         amount_valid, amount_errors, amount_warnings = self._validate_amount(
#             transaction
        )
#         validation_checks["amount_valid"] = amount_valid
#         errors.extend(amount_errors)
#         warnings.extend(amount_warnings)

        # Account validation
#         accounts_valid, account_errors, account_warnings = self._validate_accounts(
#             transaction
        )
#         validation_checks["accounts_valid"] = accounts_valid
#         errors.extend(account_errors)
#         warnings.extend(account_warnings)

        # Transaction velocity validation
#         velocity_valid, velocity_errors, velocity_warnings = (
#             self._validate_transaction_velocity(transaction, context)
        )
#         validation_checks["velocity_valid"] = velocity_valid
#         errors.extend(velocity_errors)
#         warnings.extend(velocity_warnings)

        # Business rules validation
#         business_rules_valid, business_errors, business_warnings = (
#             self._validate_business_rules(transaction)
        )
#         validation_checks["business_rules_valid"] = business_rules_valid
#         errors.extend(business_errors)
#         warnings.extend(business_warnings)

        # AML/CFT validation
#         aml_valid, aml_errors, aml_warnings = self._validate_aml_cft(
#             transaction, context
        )
#         validation_checks["aml_cft_valid"] = aml_valid
#         errors.extend(aml_errors)
#         warnings.extend(aml_warnings)

        # Fraud detection
#         fraud_valid, fraud_errors, fraud_warnings = self._detect_fraud_patterns(
#             transaction, context
        )
#         validation_checks["fraud_detection_valid"] = fraud_valid
#         errors.extend(fraud_errors)
#         warnings.extend(fraud_warnings)

        # Calculate overall risk score
#         risk_score = self._calculate_risk_score(transaction, validation_checks, context)

        # Determine risk level based on score
#         risk_level = self._determine_risk_level(risk_score)

        # Determine overall validity
#         is_valid = (
#             amount_valid
#             and accounts_valid
#             and velocity_valid
#             and business_rules_valid
#             and aml_valid
#             and fraud_valid
        )

        # Store transaction in history (in production, this would be a database write)
#         self._record_transaction(transaction)

        # Log validation result
#         logger.info(
#             f"Transaction {transaction.transaction_id} validation: valid={is_valid}, "
#             f"risk_score={risk_score:.2f}, risk_level={risk_level.value}"
        )

        # Return validation result
#         return ValidationResult(
#             is_valid=is_valid,
#             risk_score=risk_score,
#             risk_level=risk_level,
#             validation_checks=validation_checks,
#             errors=errors,
#             warnings=warnings,
#             metadata={
                "validation_timestamp": datetime.now().isoformat(),
                "validator_version": "1.0.0",
            },
        )

#     def _validate_amount(
#         self, transaction: TransactionRequest
#     ) -> Tuple[bool, List[ValidationError], List[Dict[str, Any]]]:
#        """"""
##         Validate transaction amount against configured thresholds.
#
##         Args:
##             transaction: The transaction to validate
#
##         Returns:
##             Tuple of (is_valid, errors, warnings)
#        """"""
#         errors = []
#         warnings = []

        # Check if amount is positive
#         if transaction.amount <= 0:
#             errors.append(
#                 ValidationError(
#                     code="INVALID_AMOUNT",
#                     message="Transaction amount must be greater than zero",
#                     field="amount",
                )
            )
#             return False, errors, warnings

        # Check if amount exceeds maximum single transaction limit
#         max_single = self.config["amount_thresholds"]["max_single_transaction"]
#         if transaction.amount > max_single:
#             errors.append(
#                 ValidationError(
#                     code="AMOUNT_EXCEEDS_MAX",
#                     message=f"Transaction amount exceeds maximum allowed ({max_single})",
#                     field="amount",
                )
            )
#             return False, errors, warnings

        # Check if amount is considered high value (warning only)
#         high_value = self.config["amount_thresholds"]["high_value"]
#         if transaction.amount > high_value:
#             warnings.append(
                {
                    "code": "HIGH_VALUE_TRANSACTION",
                    "message": f"Transaction amount ({transaction.amount}) exceeds high value threshold ({high_value})",
                    "field": "amount",
                }
            )

        # Check daily cumulative limit for source account
        # In production, this would query a database for today's transactions
#         daily_limit = self.config["amount_thresholds"]["max_daily_limit"]
#         daily_total = self._get_daily_total(transaction.source_account_id)

#         if daily_total + transaction.amount > daily_limit:
#             errors.append(
#                 ValidationError(
#                     code="DAILY_LIMIT_EXCEEDED",
#                     message=f"Transaction would exceed daily limit of {daily_limit}",
#                     field="amount",
                )
            )
#             return False, errors, warnings

#         return True, errors, warnings

#     def _validate_accounts(
#         self, transaction: TransactionRequest
#     ) -> Tuple[bool, List[ValidationError], List[Dict[str, Any]]]:
#        """"""
##         Validate transaction accounts.
#
##         Args:
##             transaction: The transaction to validate
#
##         Returns:
##             Tuple of (is_valid, errors, warnings)
#        """"""
#         errors = []
#         warnings = []

        # Check if source account exists and is active
        # In production, this would query a database
#         if not self._account_exists(transaction.source_account_id):
#             errors.append(
#                 ValidationError(
#                     code="INVALID_SOURCE_ACCOUNT",
#                     message="Source account does not exist or is inactive",
#                     field="source_account_id",
                )
            )
#             return False, errors, warnings

        # For transfers, check if destination account exists
#         if (
#             transaction.transaction_type == TransactionType.TRANSFER
#             and transaction.destination_account_id
#             and not self._account_exists(transaction.destination_account_id)
        ):
#             errors.append(
#                 ValidationError(
#                     code="INVALID_DESTINATION_ACCOUNT",
#                     message="Destination account does not exist or is inactive",
#                     field="destination_account_id",
                )
            )
#             return False, errors, warnings

        # Check if source has sufficient funds (for withdrawals, transfers, payments)
#         if transaction.transaction_type in [
#             TransactionType.WITHDRAWAL,
#             TransactionType.TRANSFER,
#             TransactionType.PAYMENT,
#             TransactionType.LOAN_REPAYMENT,
#             TransactionType.FEE,
        ]:
#             if not self._has_sufficient_funds(
#                 transaction.source_account_id, transaction.amount, transaction.currency
            ):
#                 errors.append(
#                     ValidationError(
#                         code="INSUFFICIENT_FUNDS",
#                         message="Source account has insufficient funds",
#                         field="source_account_id",
                    )
                )
#                 return False, errors, warnings

        # Check for same-account transfers
#         if (
#             transaction.transaction_type == TransactionType.TRANSFER
#             and transaction.source_account_id == transaction.destination_account_id
        ):
#             errors.append(
#                 ValidationError(
#                     code="SAME_ACCOUNT_TRANSFER",
#                     message="Source and destination accounts cannot be the same for transfers",
#                     field="destination_account_id",
                )
            )
#             return False, errors, warnings

#         return True, errors, warnings

#     def _validate_transaction_velocity(
#         self, transaction: TransactionRequest, context: Dict[str, Any]
#     ) -> Tuple[bool, List[ValidationError], List[Dict[str, Any]]]:
#        """"""
##         Validate transaction velocity (frequency) against thresholds.
#
##         Args:
##             transaction: The transaction to validate
##             context: Additional context for validation
#
##         Returns:
##             Tuple of (is_valid, errors, warnings)
#        """"""
#         errors = []
#         warnings = []

        # Get transaction counts for different time windows
        # In production, this would query a database with proper time filtering
#         per_minute = self._get_transaction_count(
#             transaction.source_account_id, minutes=1
        )
#         per_hour = self._get_transaction_count(transaction.source_account_id, hours=1)
#         per_day = self._get_transaction_count(transaction.source_account_id, days=1)

        # Check against thresholds
#         if (
#             per_minute
#             >= self.config["velocity_thresholds"]["max_transactions_per_minute"]
        ):
#             errors.append(
#                 ValidationError(
#                     code="VELOCITY_EXCEEDED_MINUTE",
#                     message="Transaction frequency exceeds per-minute limit",
#                     field="transaction_id",
                )
            )
#             return False, errors, warnings

#         if per_hour >= self.config["velocity_thresholds"]["max_transactions_per_hour"]:
#             errors.append(
#                 ValidationError(
#                     code="VELOCITY_EXCEEDED_HOUR",
#                     message="Transaction frequency exceeds per-hour limit",
#                     field="transaction_id",
                )
            )
#             return False, errors, warnings

#         if per_day >= self.config["velocity_thresholds"]["max_transactions_per_day"]:
#             errors.append(
#                 ValidationError(
#                     code="VELOCITY_EXCEEDED_DAY",
#                     message="Transaction frequency exceeds per-day limit",
#                     field="transaction_id",
                )
            )
#             return False, errors, warnings

        # Check for unusual velocity patterns (warning only)
#         if per_minute > 5 or per_hour > 20:
#             warnings.append(
                {
                    "code": "UNUSUAL_VELOCITY",
                    "message": "Unusual transaction frequency detected",
                    "field": "transaction_id",
                }
            )

#         return True, errors, warnings

#     def _validate_business_rules(
#         self, transaction: TransactionRequest
#     ) -> Tuple[bool, List[ValidationError], List[Dict[str, Any]]]:
#        """"""
##         Validate transaction against business rules.
#
##         Args:
##             transaction: The transaction to validate
#
##         Returns:
##             Tuple of (is_valid, errors, warnings)
#        """"""
#         errors = []
#         warnings = []

        # Check transaction type specific rules
#         if transaction.transaction_type == TransactionType.LOAN_DISBURSEMENT:
            # Check if loan has been approved
            # In production, this would query a loan management system
#             if not self._is_loan_approved(transaction):
#                 errors.append(
#                     ValidationError(
#                         code="LOAN_NOT_APPROVED",
#                         message="Loan disbursement requires approved loan",
#                         field="transaction_type",
                    )
                )
#                 return False, errors, warnings

#         elif transaction.transaction_type == TransactionType.LOAN_REPAYMENT:
            # Check if loan exists and payment is valid
            # In production, this would query a loan management system
#             if not self._is_valid_loan_repayment(transaction):
#                 errors.append(
#                     ValidationError(
#                         code="INVALID_LOAN_REPAYMENT",
#                         message="Invalid loan repayment transaction",
#                         field="transaction_type",
                    )
                )
#                 return False, errors, warnings

        # Check for required reference for certain transaction types
#         if (
#             transaction.transaction_type
#             in [
#                 TransactionType.PAYMENT,
#                 TransactionType.LOAN_REPAYMENT,
#                 TransactionType.FEE,
            ]
#             and not transaction.reference
        ):
#             errors.append(
#                 ValidationError(
#                     code="MISSING_REFERENCE",
#                     message=f"Reference is required for {transaction.transaction_type.value} transactions",
#                     field="reference",
                )
            )
#             return False, errors, warnings

        # Check currency restrictions
        # In production, this would check against a list of supported currencies
#         supported_currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF"]
#         if transaction.currency not in supported_currencies:
#             errors.append(
#                 ValidationError(
#                     code="UNSUPPORTED_CURRENCY",
#                     message=f"Currency {transaction.currency} is not supported",
#                     field="currency",
                )
            )
#             return False, errors, warnings

#         return True, errors, warnings

#     def _validate_aml_cft(
#         self, transaction: TransactionRequest, context: Dict[str, Any]
#     ) -> Tuple[bool, List[ValidationError], List[Dict[str, Any]]]:
#        """"""
##         Validate transaction against Anti-Money Laundering (AML) and
##         Counter-Financing of Terrorism (CFT) rules.
#
##         Args:
##             transaction: The transaction to validate
##             context: Additional context for validation
#
##         Returns:
##             Tuple of (is_valid, errors, warnings)
#        """"""
#         errors = []
#         warnings = []

#         if not self.config["aml_checks"]["enabled"]:
#             return True, errors, warnings

        # Check for sanctioned countries
#         if (
#             self.config["aml_checks"]["check_sanctioned_countries"]
#             and context.get("country_code")
#             and self._is_sanctioned_country(context["country_code"])
        ):
#             errors.append(
#                 ValidationError(
#                     code="SANCTIONED_COUNTRY",
#                     message="Transaction involves a sanctioned country",
#                     field="metadata",
                )
            )
#             return False, errors, warnings

        # Check for politically exposed persons (PEP)
#         if (
#             self.config["aml_checks"]["check_pep_lists"]
#             and context.get("user_id")
#             and self._is_politically_exposed_person(context["user_id"])
        ):
#             warnings.append(
                {
                    "code": "PEP_DETECTED",
                    "message": "Transaction involves a politically exposed person",
                    "field": "metadata",
                }
            )
            # This is a warning, not an error - transactions from PEPs are allowed but require enhanced due diligence

        # Check for structured transactions (multiple smaller transactions to avoid reporting)
#         if self._detect_structuring(transaction):
#             warnings.append(
                {
                    "code": "POTENTIAL_STRUCTURING",
                    "message": "Potential structuring activity detected",
                    "field": "amount",
                }
            )
            # This is a warning that might trigger a review, not an automatic rejection

        # Check for high-risk transaction patterns
#         if transaction.amount > 10000 and transaction.transaction_type in [
#             TransactionType.TRANSFER,
#             TransactionType.WITHDRAWAL,
        ]:
            # In production, this would trigger additional verification or review
#             warnings.append(
                {
                    "code": "HIGH_RISK_PATTERN",
                    "message": "High-risk transaction pattern detected",
                    "field": "transaction_type",
                }
            )

#         return True, errors, warnings

#     def _detect_fraud_patterns(
#         self, transaction: TransactionRequest, context: Dict[str, Any]
#     ) -> Tuple[bool, List[ValidationError], List[Dict[str, Any]]]:
#        """"""
##         Detect potential fraud patterns in the transaction.
#
##         Args:
##             transaction: The transaction to validate
##             context: Additional context for validation
#
##         Returns:
##             Tuple of (is_valid, errors, warnings)
#        """"""
#         errors = []
#         warnings = []

#         if not self.config["fraud_detection"]["enabled"]:
#             return True, errors, warnings

        # Check IP reputation if available
#         if (
#             self.config["fraud_detection"]["check_ip_reputation"]
#             and context.get("ip_address")
#             and self._is_suspicious_ip(context["ip_address"])
        ):
#             errors.append(
#                 ValidationError(
#                     code="SUSPICIOUS_IP",
#                     message="Transaction initiated from suspicious IP address",
#                     field="metadata",
                )
            )
#             return False, errors, warnings

        # Check device fingerprint if available
#         if (
#             self.config["fraud_detection"]["check_device_fingerprint"]
#             and context.get("device_fingerprint")
#             and self._is_suspicious_device(context["device_fingerprint"])
        ):
#             errors.append(
#                 ValidationError(
#                     code="SUSPICIOUS_DEVICE",
#                     message="Transaction initiated from suspicious device",
#                     field="metadata",
                )
            )
#             return False, errors, warnings

        # Check for unusual transaction patterns
#         if self.config["fraud_detection"]["check_transaction_patterns"]:
            # Check for account takeover patterns
#             if self._detect_account_takeover(transaction, context):
#                 errors.append(
#                     ValidationError(
#                         code="POTENTIAL_ACCOUNT_TAKEOVER",
#                         message="Potential account takeover detected",
#                         field="source_account_id",
                    )
                )
#                 return False, errors, warnings

            # Check for unusual transaction timing
#             if self._is_unusual_transaction_time(transaction, context):
#                 warnings.append(
                    {
                        "code": "UNUSUAL_TRANSACTION_TIME",
                        "message": "Transaction initiated at unusual time for this account",
                        "field": "metadata",
                    }
                )

            # Check for unusual transaction location
#             if context.get("location") and self._is_unusual_location(
#                 transaction, context["location"]
            ):
#                 warnings.append(
                    {
                        "code": "UNUSUAL_LOCATION",
                        "message": "Transaction initiated from unusual location",
                        "field": "metadata",
                    }
                )

#         return True, errors, warnings

#     def _calculate_risk_score(
#         self,
#         transaction: TransactionRequest,
#         validation_checks: Dict[str, bool],
#         context: Dict[str, Any],
#     ) -> float:
#        """"""
##         Calculate a risk score for the transaction based on various factors.
#
##         Args:
##             transaction: The transaction to score
##             validation_checks: Results of validation checks
##             context: Additional context for scoring
#
##         Returns:
##             Risk score between 0.0 (lowest risk) and 1.0 (highest risk)
#        """"""
#         risk_score = 0.0
#         weights = self.config["risk_scoring"]

        # Amount-based risk
#         amount_risk = self._calculate_amount_risk(transaction)
#         risk_score += amount_risk * weights["high_value_weight"]

        # Velocity-based risk
#         velocity_risk = self._calculate_velocity_risk(transaction)
#         risk_score += velocity_risk * weights["velocity_weight"]

        # Pattern-based risk
#         pattern_risk = self._calculate_pattern_risk(transaction, context)
#         risk_score += pattern_risk * weights["pattern_weight"]

        # Account history risk
#         history_risk = self._calculate_account_history_risk(transaction)
#         risk_score += history_risk * weights["account_history_weight"]

        # Geographic risk
#         geo_risk = self._calculate_geographic_risk(context)
#         risk_score += geo_risk * weights["geographic_weight"]

        # Ensure score is between 0 and 1
#         return max(0.0, min(1.0, risk_score))

#     def _determine_risk_level(self, risk_score: float) -> RiskLevel:
#        """"""
##         Determine risk level based on risk score.
#
##         Args:
##             risk_score: Risk score between 0.0 and 1.0
#
##         Returns:
##             RiskLevel enum value
#        """"""
#         thresholds = self.config["risk_levels"]

#         if risk_score >= thresholds["high_threshold"]:
#             return RiskLevel.CRITICAL
#         elif risk_score >= thresholds["medium_threshold"]:
#             return RiskLevel.HIGH
#         elif risk_score >= thresholds["low_threshold"]:
#             return RiskLevel.MEDIUM
#         else:
#             return RiskLevel.LOW

    # Helper methods for validation

#     def _get_daily_total(self, account_id: str) -> float:
#        """"""
##         Get total transaction amount for an account today.
##         In production, this would query a database.
#
##         Args:
##             account_id: Account identifier
#
##         Returns:
##             Total transaction amount for today
#        """"""
        # Mock implementation
#         return 0.0

#     def _account_exists(self, account_id: str) -> bool:
#        """"""
##         Check if an account exists and is active.
##         In production, this would query an account service.
#
##         Args:
##             account_id: Account identifier
#
##         Returns:
##             True if account exists and is active
#        """"""
        # Mock implementation
#         return True

#     def _has_sufficient_funds(
#         self, account_id: str, amount: float, currency: str
#     ) -> bool:
#        """"""
##         Check if an account has sufficient funds for a transaction.
##         In production, this would query an account service.
#
##         Args:
##             account_id: Account identifier
##             amount: Transaction amount
##             currency: Transaction currency
#
##         Returns:
##             True if account has sufficient funds
#        """"""
        # Mock implementation
#         return True

#     def _get_transaction_count(
#         self, account_id: str, minutes: int = 0, hours: int = 0, days: int = 0
#     ) -> int:
#        """"""
##         Get transaction count for an account within a time window.
##         In production, this would query a database.
#
##         Args:
##             account_id: Account identifier
##             minutes: Minutes to look back
##             hours: Hours to look back
##             days: Days to look back
#
##         Returns:
##             Transaction count within the time window
#        """"""
        # Mock implementation
#         return 0

#     def _is_loan_approved(self, transaction: TransactionRequest) -> bool:
#        """"""
##         Check if a loan has been approved.
##         In production, this would query a loan service.
#
##         Args:
##             transaction: Loan disbursement transaction
#
##         Returns:
##             True if loan has been approved
#        """"""
        # Mock implementation
#         return True

#     def _is_valid_loan_repayment(self, transaction: TransactionRequest) -> bool:
#        """"""
##         Check if a loan repayment is valid.
##         In production, this would query a loan service.
#
##         Args:
##             transaction: Loan repayment transaction
#
##         Returns:
##             True if loan repayment is valid
#        """"""
        # Mock implementation
#         return True

#     def _is_sanctioned_country(self, country_code: str) -> bool:
#        """"""
##         Check if a country is sanctioned.
##         In production, this would check against a sanctions database.
#
##         Args:
##             country_code: ISO country code
#
##         Returns:
##             True if country is sanctioned
#        """"""
        # Mock implementation - example sanctioned countries
#         sanctioned_countries = ["NK", "IR", "SY", "CU"]
#         return country_code in sanctioned_countries

#     def _is_politically_exposed_person(self, user_id: str) -> bool:
#        """"""
##         Check if a user is a politically exposed person (PEP).
##         In production, this would check against a PEP database.
#
##         Args:
##             user_id: User identifier
#
##         Returns:
##             True if user is a PEP
#        """"""
        # Mock implementation
#         return False

#     def _detect_structuring(self, transaction: TransactionRequest) -> bool:
#        """"""
##         Detect potential structuring activity.
##         In production, this would analyze transaction patterns.
#
##         Args:
##             transaction: Current transaction
#
##         Returns:
##             True if potential structuring is detected
#        """"""
        # Mock implementation
#         return False

#     def _is_suspicious_ip(self, ip_address: str) -> bool:
#        """"""
##         Check if an IP address is suspicious.
##         In production, this would check against IP reputation databases.
#
##         Args:
##             ip_address: IP address
#
##         Returns:
##             True if IP is suspicious
#        """"""
        # Mock implementation
#         return False

#     def _is_suspicious_device(self, device_fingerprint: str) -> bool:
#        """"""
##         Check if a device is suspicious.
##         In production, this would check against device reputation data.
#
##         Args:
##             device_fingerprint: Device fingerprint
#
##         Returns:
##             True if device is suspicious
#        """"""
        # Mock implementation
#         return False

#     def _detect_account_takeover(
#         self, transaction: TransactionRequest, context: Dict[str, Any]
#     ) -> bool:
#        """"""
##         Detect potential account takeover.
##         In production, this would analyze user behavior patterns.
#
##         Args:
##             transaction: Current transaction
##             context: Additional context
#
##         Returns:
##             True if potential account takeover is detected
#        """"""
        # Mock implementation
#         return False

#     def _is_unusual_transaction_time(
#         self, transaction: TransactionRequest, context: Dict[str, Any]
#     ) -> bool:
#        """"""
##         Check if transaction time is unusual for the account.
##         In production, this would analyze user behavior patterns.
#
##         Args:
##             transaction: Current transaction
##             context: Additional context
#
##         Returns:
##             True if transaction time is unusual
#        """"""
        # Mock implementation
#         return False

#     def _is_unusual_location(
#         self, transaction: TransactionRequest, location: str
#     ) -> bool:
#        """"""
##         Check if transaction location is unusual for the account.
##         In production, this would analyze user behavior patterns.
#
##         Args:
##             transaction: Current transaction
##             location: Transaction location
#
##         Returns:
##             True if location is unusual
#        """"""
        # Mock implementation
#         return False

#     def _calculate_amount_risk(self, transaction: TransactionRequest) -> float:
#        """"""
##         Calculate risk based on transaction amount.
#
##         Args:
##             transaction: Transaction to analyze
#
##         Returns:
##             Risk score component between 0.0 and 1.0
#        """"""
#         high_value = self.config["amount_thresholds"]["high_value"]
#         very_high_value = self.config["amount_thresholds"]["very_high_value"]

#         if transaction.amount <= high_value:
#             return 0.1
#         elif transaction.amount <= very_high_value:
            # Linear scaling between high_value and very_high_value
#             return 0.1 + 0.4 * (
#                 (transaction.amount - high_value) / (very_high_value - high_value)
            )
#         else:
#             return 0.5 + 0.5 * min(
#                 1.0, (transaction.amount - very_high_value) / very_high_value
            )

#     def _calculate_velocity_risk(self, transaction: TransactionRequest) -> float:
#        """"""
##         Calculate risk based on transaction velocity.
#
##         Args:
##             transaction: Transaction to analyze
#
##         Returns:
##             Risk score component between 0.0 and 1.0
#        """"""
        # Mock implementation
#         per_minute = self._get_transaction_count(
#             transaction.source_account_id, minutes=1
        )
#         per_hour = self._get_transaction_count(transaction.source_account_id, hours=1)

#         minute_max = self.config["velocity_thresholds"]["max_transactions_per_minute"]
#         hour_max = self.config["velocity_thresholds"]["max_transactions_per_hour"]

#         minute_risk = min(1.0, per_minute / minute_max)
#         hour_risk = min(1.0, per_hour / hour_max)

#         return max(minute_risk, hour_risk * 0.8)

#     def _calculate_pattern_risk(
#         self, transaction: TransactionRequest, context: Dict[str, Any]
#     ) -> float:
#        """"""
##         Calculate risk based on transaction patterns.
#
##         Args:
##             transaction: Transaction to analyze
##             context: Additional context
#
##         Returns:
##             Risk score component between 0.0 and 1.0
#        """"""
        # Mock implementation
#         risk = 0.0

        # High-risk transaction types
#         if transaction.transaction_type in [
#             TransactionType.WITHDRAWAL,
#             TransactionType.TRANSFER,
        ]:
#             risk += 0.2

        # Unusual time or location
#         if context.get("is_unusual_time", False):
#             risk += 0.3

#         if context.get("is_unusual_location", False):
#             risk += 0.3

#         return min(1.0, risk)

#     def _calculate_account_history_risk(self, transaction: TransactionRequest) -> float:
#        """"""
##         Calculate risk based on account history.
#
##         Args:
##             transaction: Transaction to analyze
#
##         Returns:
##             Risk score component between 0.0 and 1.0
#        """"""
        # Mock implementation - in production, this would analyze account history
#         return 0.1

#     def _calculate_geographic_risk(self, context: Dict[str, Any]) -> float:
#        """"""
##         Calculate risk based on geographic factors.
#
##         Args:
##             context: Context including geographic information
#
##         Returns:
##             Risk score component between 0.0 and 1.0
#        """"""
        # Mock implementation
#         if not context.get("country_code"):
#             return 0.5  # Default medium risk if country unknown

        # High-risk countries (would be a more comprehensive list in production)
#         high_risk_countries = ["AF", "IQ", "LY", "SO", "YE"]
#         medium_risk_countries = ["RU", "NG", "PK", "UA", "VE"]

#         country = context["country_code"]

#         if country in high_risk_countries:
#             return 0.9
#         elif country in medium_risk_countries:
#             return 0.6
#         else:
#             return 0.1

#     def _record_transaction(self, transaction: TransactionRequest) -> None:
#        """"""
##         Record transaction in history for future validation.
##         In production, this would write to a database.
#
##         Args:
##             transaction: Transaction to record
#        """"""
        # Mock implementation - in memory storage
#         account_id = transaction.source_account_id
#         if account_id not in self._transaction_history:
#             self._transaction_history[account_id] = []

#         self._transaction_history[account_id].append(
            {
                "transaction_id": transaction.transaction_id,
                "amount": transaction.amount,
                "currency": transaction.currency,
                "transaction_type": transaction.transaction_type,
                "timestamp": datetime.now().isoformat(),
            }
        )


# class BatchTransactionValidator:
#    """"""
##     Validator for processing batches of transactions with optimized validation.
#    """"""

#     def __init__(self, validator: TransactionValidator):
#        """"""
##         Initialize batch validator with a transaction validator.
#
##         Args:
##             validator: TransactionValidator instance
#        """"""
#         self.validator = validator
#         logger.info("Batch transaction validator initialized")

#     def validate_batch(
#         self,
#         transactions: List[TransactionRequest],
#         context: Optional[Dict[str, Any]] = None,
#     ) -> Dict[str, List[ValidationResult]]:
#        """"""
##         Validate a batch of transactions.
#
##         Args:
##             transactions: List of transactions to validate
##             context: Additional context for validation
#
##         Returns:
##             Dictionary mapping transaction IDs to validation results
#        """"""
#         context = context or {}
#         results = {}

#         logger.info(f"Starting batch validation of {len(transactions)} transactions")

        # Pre-process batch for optimizations
#         self._preprocess_batch(transactions)

        # Validate each transaction
#         for transaction in transactions:
            # Enrich context with batch-specific information
#             transaction_context = self._enrich_context(transaction, context)

            # Validate transaction
#             result = self.validator.validate_transaction(
#                 transaction, transaction_context
            )

            # Store result
#             results[transaction.transaction_id] = result

#         logger.info(f"Completed batch validation of {len(transactions)} transactions")
#         return results

#     def _preprocess_batch(self, transactions: List[TransactionRequest]) -> None:
#        """"""
##         Pre-process batch for optimizations.
##         In production, this would perform batch lookups and caching.
#
##         Args:
##             transactions: List of transactions to pre-process
#        """"""
        # Mock implementation
#         pass

#     def _enrich_context(
#         self, transaction: TransactionRequest, base_context: Dict[str, Any]
#     ) -> Dict[str, Any]:
#        """"""
##         Enrich context with transaction-specific information.
#
##         Args:
##             transaction: Transaction to process
##             base_context: Base context
#
##         Returns:
##             Enriched context
#        """"""
        # Clone base context
#         context = base_context.copy()

        # Add transaction-specific context
        # In production, this would add more information

#         return context
