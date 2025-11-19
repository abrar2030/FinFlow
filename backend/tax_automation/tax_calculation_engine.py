# Tax Calculation Engine

# import json
# import logging
# from dataclasses import dataclass, field
# from datetime import date, datetime
# from decimal import ROUND_HALF_UP, Decimal
# from enum import Enum
# from typing import Any, Dict, List, Optional

# Configure logging
# logging.basicConfig(level=logging.INFO)
# logger = logging.getLogger(__name__)


# class TaxType(Enum):
#    """Enumeration of supported tax types"""
#
##     VAT = "vat"
##     SALES_TAX = "sales_tax"
##     INCOME_TAX = "income_tax"
##     WITHHOLDING_TAX = "withholding_tax"
##     CAPITAL_GAINS_TAX = "capital_gains_tax"
##     CORPORATE_TAX = "corporate_tax"
#
#
## class CalculationMethod(Enum):
#    """Enumeration of tax calculation methods"""

#     PERCENTAGE = "percentage"
#     FIXED_AMOUNT = "fixed_amount"
#     TIERED = "tiered"
#     PROGRESSIVE = "progressive"


# @dataclass
# class TaxRule:
#    """Data model for tax rules"""
#
##     rule_id: str
##     jurisdiction: str
##     tax_type: TaxType
##     effective_date: date
##     expiration_date: Optional[date]
##     rate: Decimal
##     calculation_method: CalculationMethod
##     conditions: Dict[str, Any] = field(default_factory=dict)
##     description: str = ""
#
##     def is_active(self, check_date: date = None) -> bool:
#        """Check if the tax rule is active on a given date"""
#         if check_date is None:
#             check_date = date.today()

#         if check_date < self.effective_date:
#             return False

#         if self.expiration_date and check_date > self.expiration_date:
#             return False

#         return True


# @dataclass
# class TaxProfile:
#    """Data model for entity tax profiles"""
#
##     entity_id: str
##     tax_identification_number: Optional[str]
##     tax_residency: str
##     exemptions: List[str] = field(default_factory=list)
##     entity_type: str = "individual"  # individual, corporation, partnership
##     additional_data: Dict[str, Any] = field(default_factory=dict)
#
#
## @dataclass
## class Transaction:
#    """Data model for financial transactions"""

#     transaction_id: str
#     amount: Decimal
#     transaction_type: str
#     origin_jurisdiction: str
#     destination_jurisdiction: str
#     product_service_code: Optional[str]
#     timestamp: datetime
#     payer_entity_id: str
#     payee_entity_id: str
#     additional_data: Dict[str, Any] = field(default_factory=dict)


# @dataclass
# class TaxCalculationResult:
#    """Result of tax calculation"""
#
##     transaction_id: str
##     total_tax_amount: Decimal
##     tax_breakdown: List[Dict[str, Any]]
##     applied_rules: List[str]
##     calculation_timestamp: datetime
##     errors: List[str] = field(default_factory=list)
##     warnings: List[str] = field(default_factory=list)
#
#
## class TaxRuleEngine:
#    """Rule engine for evaluating tax rule conditions"""

#     @staticmethod
#     def evaluate_conditions(
#         conditions: Dict[str, Any], transaction: Transaction, tax_profile: TaxProfile
#     ) -> bool:
#        """Evaluate if conditions are met for applying a tax rule"""
##         try:
##             for condition_key, condition_value in conditions.items():
##                 if condition_key == "min_amount":
##                     if transaction.amount < Decimal(str(condition_value)):
##                         return False
##                 elif condition_key == "max_amount":
##                     if transaction.amount > Decimal(str(condition_value)):
##                         return False
##                 elif condition_key == "transaction_types":
##                     if transaction.transaction_type not in condition_value:
##                         return False
##                 elif condition_key == "entity_types":
##                     if tax_profile.entity_type not in condition_value:
##                         return False
##                 elif condition_key == "product_codes":
##                     if transaction.product_service_code not in condition_value:
##                         return False
##                 elif condition_key == "exemptions":
#                    # Check if any exemption applies
##                     for exemption in condition_value:
##                         if exemption in tax_profile.exemptions:
##                             return False
#                # Add more condition types as needed
#
##             return True
##         except Exception as e:
##             logger.error(f"Error evaluating conditions: {e}")
##             return False
#
#
## class TaxCalculationEngine:
#    """Main tax calculation engine"""

#     def __init__(self):
#         self.tax_rules: List[TaxRule] = []
#         self.tax_profiles: Dict[str, TaxProfile] = {}
#         self.rule_engine = TaxRuleEngine()

#     def add_tax_rule(self, tax_rule: TaxRule) -> None:
#        """Add a tax rule to the engine"""
##         self.tax_rules.append(tax_rule)
##         logger.info(f"Added tax rule: {tax_rule.rule_id}")
#
##     def add_tax_profile(self, tax_profile: TaxProfile) -> None:
#        """Add a tax profile to the engine"""
#         self.tax_profiles[tax_profile.entity_id] = tax_profile
#         logger.info(f"Added tax profile for entity: {tax_profile.entity_id}")

#     def get_applicable_rules(
#         self, transaction: Transaction, tax_profile: TaxProfile
#     ) -> List[TaxRule]:
#        """Get all tax rules applicable to a transaction"""
##         applicable_rules = []
##         transaction_date = transaction.timestamp.date()
#
##         for rule in self.tax_rules:
#            # Check if rule is active
##             if not rule.is_active(transaction_date):
##                 continue
#
#            # Check jurisdiction match
##             if (
##                 rule.jurisdiction != transaction.origin_jurisdiction
##                 and rule.jurisdiction != transaction.destination_jurisdiction
##                 and rule.jurisdiction != tax_profile.tax_residency
#            ):
##                 continue
#
#            # Evaluate conditions
##             if self.rule_engine.evaluate_conditions(
##                 rule.conditions, transaction, tax_profile
#            ):
##                 applicable_rules.append(rule)
#
##         return applicable_rules
#
##     def calculate_tax_amount(self, rule: TaxRule, base_amount: Decimal) -> Decimal:
#        """Calculate tax amount based on rule and base amount"""
#         try:
#             if rule.calculation_method == CalculationMethod.PERCENTAGE:
#                 return (base_amount * rule.rate / Decimal("100")).quantize(
#                     Decimal("0.01"), rounding=ROUND_HALF_UP
                )

#             elif rule.calculation_method == CalculationMethod.FIXED_AMOUNT:
#                 return rule.rate

#             elif rule.calculation_method == CalculationMethod.TIERED:
                # Implement tiered calculation logic
                # This would require additional configuration in the rule
                # For now, default to percentage
#                 return (base_amount * rule.rate / Decimal("100")).quantize(
#                     Decimal("0.01"), rounding=ROUND_HALF_UP
                )

#             elif rule.calculation_method == CalculationMethod.PROGRESSIVE:
                # Implement progressive calculation logic
                # This would require additional configuration in the rule
                # For now, default to percentage
#                 return (base_amount * rule.rate / Decimal("100")).quantize(
#                     Decimal("0.01"), rounding=ROUND_HALF_UP
                )

#             else:
#                 logger.warning(f"Unknown calculation method: {rule.calculation_method}")
#                 return Decimal("0")

#         except Exception as e:
#             logger.error(f"Error calculating tax amount: {e}")
#             return Decimal("0")

#     def calculate_taxes(self, transaction: Transaction) -> TaxCalculationResult:
#        """Calculate taxes for a given transaction"""
##         result = TaxCalculationResult(
##             transaction_id=transaction.transaction_id,
##             total_tax_amount=Decimal("0"),
##             tax_breakdown=[],
##             applied_rules=[],
##             calculation_timestamp=datetime.now(),
#        )
#
##         try:
#            # Get tax profiles for payer and payee
##             payer_profile = self.tax_profiles.get(transaction.payer_entity_id)
##             payee_profile = self.tax_profiles.get(transaction.payee_entity_id)
#
##             if not payer_profile:
##                 result.errors.append(
##                     f"Tax profile not found for payer: {transaction.payer_entity_id}"
#                )
##                 return result
#
##             if not payee_profile:
##                 result.warnings.append(
##                     f"Tax profile not found for payee: {transaction.payee_entity_id}"
#                )
#                # Use a default profile or continue with payer profile only
##                 payee_profile = TaxProfile(
##                     entity_id=transaction.payee_entity_id,
##                     tax_identification_number=None,
##                     tax_residency=transaction.destination_jurisdiction,
#                )
#
#            # Get applicable rules for payer
##             applicable_rules = self.get_applicable_rules(transaction, payer_profile)
#
#            # Calculate taxes for each applicable rule
##             for rule in applicable_rules:
##                 tax_amount = self.calculate_tax_amount(rule, transaction.amount)
#
##                 if tax_amount > 0:
##                     result.total_tax_amount += tax_amount
##                     result.applied_rules.append(rule.rule_id)
##                     result.tax_breakdown.append(
#                        {
#                            "rule_id": rule.rule_id,
#                            "tax_type": rule.tax_type.value,
#                            "jurisdiction": rule.jurisdiction,
#                            "rate": float(rule.rate),
#                            "tax_amount": float(tax_amount),
#                            "description": rule.description,
#                        }
#                    )
#
##             logger.info(
##                 f"Calculated taxes for transaction {transaction.transaction_id}: "
##                 f"Total tax amount: {result.total_tax_amount}"
#            )
#
##         except Exception as e:
##             logger.error(
##                 f"Error calculating taxes for transaction {transaction.transaction_id}: {e}"
#            )
##             result.errors.append(f"Calculation error: {str(e)}")
#
##         return result
#
##     def get_tax_rules_by_jurisdiction(self, jurisdiction: str) -> List[TaxRule]:
#        """Get all tax rules for a specific jurisdiction"""
#         return [rule for rule in self.tax_rules if rule.jurisdiction == jurisdiction]

#     def get_tax_rules_by_type(self, tax_type: TaxType) -> List[TaxRule]:
#        """Get all tax rules for a specific tax type"""
##         return [rule for rule in self.tax_rules if rule.tax_type == tax_type]
#
##     def validate_transaction(self, transaction: Transaction) -> List[str]:
#        """Validate transaction data for tax calculation"""
#         errors = []

#         if transaction.amount <= 0:
#             errors.append("Transaction amount must be positive")

#         if not transaction.origin_jurisdiction:
#             errors.append("Origin jurisdiction is required")

#         if not transaction.destination_jurisdiction:
#             errors.append("Destination jurisdiction is required")

#         if not transaction.payer_entity_id:
#             errors.append("Payer entity ID is required")

#         if not transaction.payee_entity_id:
#             errors.append("Payee entity ID is required")

#         return errors


# Example usage and test data
# def create_sample_data():
#    """Create sample tax rules and profiles for testing"""
##     engine = TaxCalculationEngine()
#
#    # Sample tax rules
##     vat_rule = TaxRule(
##         rule_id="VAT_UK_STANDARD",
##         jurisdiction="UK",
##         tax_type=TaxType.VAT,
##         effective_date=date(2024, 1, 1),
##         expiration_date=None,
##         rate=Decimal("20.0"),
##         calculation_method=CalculationMethod.PERCENTAGE,
##         conditions={"min_amount": 0.01},
##         description="UK Standard VAT Rate",
#    )
#
##     sales_tax_rule = TaxRule(
##         rule_id="SALES_TAX_NY",
##         jurisdiction="NY",
##         tax_type=TaxType.SALES_TAX,
##         effective_date=date(2024, 1, 1),
##         expiration_date=None,
##         rate=Decimal("8.25"),
##         calculation_method=CalculationMethod.PERCENTAGE,
##         conditions={"transaction_types": ["purchase", "service"]},
##         description="New York State Sales Tax",
#    )
#
##     engine.add_tax_rule(vat_rule)
##     engine.add_tax_rule(sales_tax_rule)
#
#    # Sample tax profiles
##     individual_profile = TaxProfile(
##         entity_id="user_001",
##         tax_identification_number="123456789",
##         tax_residency="UK",
##         entity_type="individual",
#    )
#
##     corporate_profile = TaxProfile(
##         entity_id="corp_001",
##         tax_identification_number="987654321",
##         tax_residency="NY",
##         entity_type="corporation",
#    )
#
##     engine.add_tax_profile(individual_profile)
##     engine.add_tax_profile(corporate_profile)
#
##     return engine
#
#
## if __name__ == "__main__":
#    # Example usage
##     engine = create_sample_data()
#
#    # Sample transaction
##     transaction = Transaction(
##         transaction_id="txn_001",
##         amount=Decimal("1000.00"),
##         transaction_type="purchase",
##         origin_jurisdiction="UK",
##         destination_jurisdiction="UK",
##         product_service_code="GOODS",
##         timestamp=datetime.now(),
##         payer_entity_id="user_001",
##         payee_entity_id="corp_001",
#    )
#
#    # Calculate taxes
##     result = engine.calculate_taxes(transaction)
#
##     print(f"Transaction ID: {result.transaction_id}")
##     print(f"Total Tax Amount: {result.total_tax_amount}")
##     print(f"Tax Breakdown: {json.dumps(result.tax_breakdown, indent=2)}")
##     print(f"Applied Rules: {result.applied_rules}")
##     if result.errors:
##         print(f"Errors: {result.errors}")
##     if result.warnings:
##         print(f"Warnings: {result.warnings}")
