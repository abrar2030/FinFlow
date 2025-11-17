# Tax Automation API Service

import json
import logging
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Dict

from flask import Flask, jsonify, request
from flask_cors import CORS

from .tax_calculation_engine import (CalculationMethod, TaxCalculationEngine,
                                     TaxProfile, TaxType, Transaction,
                                     create_sample_data)
from .tax_rule_management import SAMPLE_TAX_RULES, TaxRuleManager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Global instances
tax_engine = None
rule_manager = None


def init_tax_system():
    """Initialize the tax system with sample data"""
    global tax_engine, rule_manager

    # Initialize rule manager
    rule_manager = TaxRuleManager()

    # Import sample rules if database is empty
    existing_rules = rule_manager.db.get_active_tax_rules()
    if not existing_rules:
        logger.info("Importing sample tax rules...")
        for rule_data in SAMPLE_TAX_RULES:
            rule_manager.create_tax_rule(rule_data, "system_init")

    # Initialize tax engine with rules from database
    tax_engine = TaxCalculationEngine()
    active_rules = rule_manager.db.get_active_tax_rules()
    for rule in active_rules:
        tax_engine.add_tax_rule(rule)

    logger.info(f"Tax system initialized with {len(active_rules)} active rules")


@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint"""
    return jsonify(
        {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "service": "tax-automation-api",
        }
    )


@app.route("/api/tax/calculate", methods=["POST"])
def calculate_tax():
    """Calculate tax for a transaction"""
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = [
            "transaction_id",
            "amount",
            "transaction_type",
            "origin_jurisdiction",
            "destination_jurisdiction",
            "payer_entity_id",
            "payee_entity_id",
        ]

        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # Create transaction object
        transaction = Transaction(
            transaction_id=data["transaction_id"],
            amount=Decimal(str(data["amount"])),
            transaction_type=data["transaction_type"],
            origin_jurisdiction=data["origin_jurisdiction"],
            destination_jurisdiction=data["destination_jurisdiction"],
            product_service_code=data.get("product_service_code"),
            timestamp=datetime.fromisoformat(
                data.get("timestamp", datetime.now().isoformat())
            ),
            payer_entity_id=data["payer_entity_id"],
            payee_entity_id=data["payee_entity_id"],
            additional_data=data.get("additional_data", {}),
        )

        # Validate transaction
        validation_errors = tax_engine.validate_transaction(transaction)
        if validation_errors:
            return (
                jsonify(
                    {
                        "error": "Transaction validation failed",
                        "details": validation_errors,
                    }
                ),
                400,
            )

        # Calculate taxes
        result = tax_engine.calculate_taxes(transaction)

        # Convert result to JSON-serializable format
        response = {
            "transaction_id": result.transaction_id,
            "total_tax_amount": float(result.total_tax_amount),
            "tax_breakdown": result.tax_breakdown,
            "applied_rules": result.applied_rules,
            "calculation_timestamp": result.calculation_timestamp.isoformat(),
            "errors": result.errors,
            "warnings": result.warnings,
        }

        return jsonify(response)

    except Exception as e:
        logger.error(f"Error calculating tax: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.route("/api/tax/profile", methods=["POST"])
def create_tax_profile():
    """Create or update a tax profile"""
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = ["entity_id", "tax_residency"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # Create tax profile
        tax_profile = TaxProfile(
            entity_id=data["entity_id"],
            tax_identification_number=data.get("tax_identification_number"),
            tax_residency=data["tax_residency"],
            exemptions=data.get("exemptions", []),
            entity_type=data.get("entity_type", "individual"),
            additional_data=data.get("additional_data", {}),
        )

        # Add to tax engine
        tax_engine.add_tax_profile(tax_profile)

        return jsonify(
            {
                "message": "Tax profile created successfully",
                "entity_id": tax_profile.entity_id,
            }
        )

    except Exception as e:
        logger.error(f"Error creating tax profile: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.route("/api/tax/profile/<entity_id>", methods=["GET"])
def get_tax_profile(entity_id):
    """Get a tax profile by entity ID"""
    try:
        tax_profile = tax_engine.tax_profiles.get(entity_id)
        if not tax_profile:
            return jsonify({"error": "Tax profile not found"}), 404

        response = {
            "entity_id": tax_profile.entity_id,
            "tax_identification_number": tax_profile.tax_identification_number,
            "tax_residency": tax_profile.tax_residency,
            "exemptions": tax_profile.exemptions,
            "entity_type": tax_profile.entity_type,
            "additional_data": tax_profile.additional_data,
        }

        return jsonify(response)

    except Exception as e:
        logger.error(f"Error getting tax profile: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.route("/api/tax/rules", methods=["GET"])
def get_tax_rules():
    """Get tax rules with optional filtering"""
    try:
        jurisdiction = request.args.get("jurisdiction")
        tax_type = request.args.get("tax_type")

        if jurisdiction:
            rules = rule_manager.get_applicable_rules(jurisdiction)
        else:
            rules = rule_manager.db.get_active_tax_rules()

        if tax_type:
            try:
                tax_type_enum = TaxType(tax_type)
                rules = [rule for rule in rules if rule.tax_type == tax_type_enum]
            except ValueError:
                return jsonify({"error": f"Invalid tax type: {tax_type}"}), 400

        # Convert rules to JSON-serializable format
        rules_data = []
        for rule in rules:
            rule_data = {
                "rule_id": rule.rule_id,
                "jurisdiction": rule.jurisdiction,
                "tax_type": rule.tax_type.value,
                "effective_date": rule.effective_date.isoformat(),
                "expiration_date": (
                    rule.expiration_date.isoformat() if rule.expiration_date else None
                ),
                "rate": float(rule.rate),
                "calculation_method": rule.calculation_method.value,
                "conditions": rule.conditions,
                "description": rule.description,
            }
            rules_data.append(rule_data)

        return jsonify({"rules": rules_data, "count": len(rules_data)})

    except Exception as e:
        logger.error(f"Error getting tax rules: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.route("/api/tax/rules", methods=["POST"])
def create_tax_rule():
    """Create a new tax rule"""
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = [
            "rule_id",
            "jurisdiction",
            "tax_type",
            "effective_date",
            "rate",
            "calculation_method",
        ]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # Create tax rule
        rule = rule_manager.create_tax_rule(data, "api_user")
        if not rule:
            return jsonify({"error": "Failed to create tax rule"}), 500

        # Add to tax engine
        tax_engine.add_tax_rule(rule)

        return jsonify(
            {"message": "Tax rule created successfully", "rule_id": rule.rule_id}
        )

    except Exception as e:
        logger.error(f"Error creating tax rule: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.route("/api/tax/rules/<rule_id>", methods=["PUT"])
def update_tax_rule(rule_id):
    """Update an existing tax rule"""
    try:
        data = request.get_json()

        success = rule_manager.update_tax_rule(rule_id, data, "api_user")
        if not success:
            return jsonify({"error": "Failed to update tax rule"}), 500

        # Reload rules in tax engine
        tax_engine.tax_rules.clear()
        active_rules = rule_manager.db.get_active_tax_rules()
        for rule in active_rules:
            tax_engine.add_tax_rule(rule)

        return jsonify({"message": "Tax rule updated successfully", "rule_id": rule_id})

    except Exception as e:
        logger.error(f"Error updating tax rule: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.route("/api/tax/rules/<rule_id>", methods=["DELETE"])
def deactivate_tax_rule(rule_id):
    """Deactivate a tax rule"""
    try:
        success = rule_manager.db.deactivate_tax_rule(rule_id, "api_user")
        if not success:
            return jsonify({"error": "Failed to deactivate tax rule"}), 500

        # Reload rules in tax engine
        tax_engine.tax_rules.clear()
        active_rules = rule_manager.db.get_active_tax_rules()
        for rule in active_rules:
            tax_engine.add_tax_rule(rule)

        return jsonify(
            {"message": "Tax rule deactivated successfully", "rule_id": rule_id}
        )

    except Exception as e:
        logger.error(f"Error deactivating tax rule: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.route("/api/tax/jurisdictions", methods=["GET"])
def get_jurisdictions():
    """Get list of supported jurisdictions"""
    try:
        rules = rule_manager.db.get_active_tax_rules()
        jurisdictions = list(set(rule.jurisdiction for rule in rules))
        jurisdictions.sort()

        return jsonify({"jurisdictions": jurisdictions, "count": len(jurisdictions)})

    except Exception as e:
        logger.error(f"Error getting jurisdictions: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.route("/api/tax/types", methods=["GET"])
def get_tax_types():
    """Get list of supported tax types"""
    try:
        tax_types = [tax_type.value for tax_type in TaxType]

        return jsonify({"tax_types": tax_types, "count": len(tax_types)})

    except Exception as e:
        logger.error(f"Error getting tax types: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500


@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500


if __name__ == "__main__":
    # Initialize the tax system
    init_tax_system()

    # Run the Flask app
    app.run(host="0.0.0.0", port=5000, debug=True)
