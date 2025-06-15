# Tax Automation Module Initialization

"""
Tax Automation Module for Finflow

This module provides comprehensive tax calculation and automation capabilities
for the Finflow financial platform, including:

- Advanced tax calculation engine
- Tax rule management system
- International compliance features
- RESTful API for integration

Author: Manus AI
Version: 1.0.0
"""

from .tax_calculation_engine import (
    TaxCalculationEngine,
    TaxRule,
    TaxProfile,
    Transaction,
    TaxCalculationResult,
    TaxType,
    CalculationMethod,
    TaxRuleEngine
)

from .tax_rule_management import (
    TaxRuleManager,
    TaxRuleDatabase,
    SAMPLE_TAX_RULES
)

from .tax_api_service import app as tax_api_app, init_tax_system

__version__ = "1.0.0"
__author__ = "Manus AI"

__all__ = [
    'TaxCalculationEngine',
    'TaxRule',
    'TaxProfile', 
    'Transaction',
    'TaxCalculationResult',
    'TaxType',
    'CalculationMethod',
    'TaxRuleEngine',
    'TaxRuleManager',
    'TaxRuleDatabase',
    'SAMPLE_TAX_RULES',
    'tax_api_app',
    'init_tax_system'
]

