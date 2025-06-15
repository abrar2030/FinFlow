# Compliance API Service

from flask import Flask, request, jsonify
from flask_cors import CORS
from decimal import Decimal
from datetime import datetime, date
import json
import logging
from typing import Dict, Any

from .international_compliance import (
    InternationalComplianceManager,
    ComplianceCheckType,
    ComplianceStatus,
    RiskLevel
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

compliance_app = Flask(__name__)
CORS(compliance_app)  # Enable CORS for all routes

# Global compliance manager
compliance_manager = None

def init_compliance_system():
    """Initialize the compliance system"""
    global compliance_manager
    compliance_manager = InternationalComplianceManager()
    logger.info("Compliance system initialized")

@compliance_app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'compliance-api'
    })

@compliance_app.route('/api/compliance/entity', methods=['POST'])
def create_entity_profile():
    """Create a new entity profile"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['entity_id', 'entity_type', 'full_name']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Create entity profile
        profile = compliance_manager.create_entity_profile(data)
        
        return jsonify({
            'message': 'Entity profile created successfully',
            'entity_id': profile.entity_id,
            'created_at': profile.created_at.isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error creating entity profile: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/entity/<entity_id>', methods=['GET'])
def get_entity_profile(entity_id):
    """Get entity profile by ID"""
    try:
        profile = compliance_manager.db.get_entity_profile(entity_id)
        if not profile:
            return jsonify({'error': 'Entity profile not found'}), 404
        
        response = {
            'entity_id': profile.entity_id,
            'entity_type': profile.entity_type,
            'full_name': profile.full_name,
            'date_of_birth': profile.date_of_birth.isoformat() if profile.date_of_birth else None,
            'nationality': profile.nationality,
            'country_of_residence': profile.country_of_residence,
            'address': profile.address,
            'identification_documents': profile.identification_documents,
            'business_activities': profile.business_activities,
            'source_of_funds': profile.source_of_funds,
            'expected_transaction_volume': float(profile.expected_transaction_volume) if profile.expected_transaction_volume else None,
            'risk_factors': profile.risk_factors,
            'compliance_flags': profile.compliance_flags,
            'created_at': profile.created_at.isoformat(),
            'updated_at': profile.updated_at.isoformat()
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error getting entity profile: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/check/kyc/<entity_id>', methods=['POST'])
def perform_kyc_check(entity_id):
    """Perform KYC compliance check"""
    try:
        result = compliance_manager.kyc_service.perform_kyc_check(entity_id)
        
        response = {
            'check_id': result.check_id,
            'entity_id': result.entity_id,
            'check_type': result.check_type.value,
            'status': result.status.value,
            'risk_level': result.risk_level.value,
            'details': result.details,
            'performed_at': result.performed_at.isoformat(),
            'expires_at': result.expires_at.isoformat() if result.expires_at else None,
            'notes': result.notes
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error performing KYC check: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/check/fatca/<entity_id>', methods=['POST'])
def perform_fatca_check(entity_id):
    """Perform FATCA compliance check"""
    try:
        result = compliance_manager.fatca_service.check_us_person_status(entity_id)
        
        response = {
            'check_id': result.check_id,
            'entity_id': result.entity_id,
            'check_type': result.check_type.value,
            'status': result.status.value,
            'risk_level': result.risk_level.value,
            'details': result.details,
            'performed_at': result.performed_at.isoformat(),
            'notes': result.notes
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error performing FATCA check: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/check/aml', methods=['POST'])
def monitor_transaction():
    """Monitor transaction for AML compliance"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['transaction_id', 'entity_id', 'amount', 'transaction_type', 
                          'origin_country', 'destination_country']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Monitor transaction
        result = compliance_manager.aml_service.monitor_transaction(data)
        
        response = {
            'transaction_id': result.transaction_id,
            'entity_id': result.entity_id,
            'amount': float(result.amount),
            'currency': result.currency,
            'transaction_type': result.transaction_type,
            'risk_score': result.risk_score,
            'flags': result.flags,
            'monitoring_rules_triggered': result.monitoring_rules_triggered,
            'timestamp': result.timestamp.isoformat()
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error monitoring transaction: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/check/comprehensive/<entity_id>', methods=['POST'])
def perform_comprehensive_check(entity_id):
    """Perform comprehensive compliance check"""
    try:
        results = compliance_manager.perform_comprehensive_compliance_check(entity_id)
        
        response = {}
        for check_type, result in results.items():
            response[check_type] = {
                'check_id': result.check_id,
                'status': result.status.value,
                'risk_level': result.risk_level.value,
                'details': result.details,
                'performed_at': result.performed_at.isoformat(),
                'expires_at': result.expires_at.isoformat() if result.expires_at else None,
                'notes': result.notes
            }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error performing comprehensive check: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/status/<entity_id>', methods=['GET'])
def get_compliance_status(entity_id):
    """Get overall compliance status for an entity"""
    try:
        status = compliance_manager.get_compliance_status(entity_id)
        return jsonify(status)
        
    except Exception as e:
        logger.error(f"Error getting compliance status: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/check/data-residency/<entity_id>', methods=['POST'])
def check_data_residency(entity_id):
    """Check data residency compliance"""
    try:
        data = request.get_json()
        data_location = data.get('data_location', 'US')
        
        result = compliance_manager.data_residency_service.check_data_residency_compliance(
            entity_id, data_location
        )
        
        response = {
            'check_id': result.check_id,
            'entity_id': result.entity_id,
            'check_type': result.check_type.value,
            'status': result.status.value,
            'risk_level': result.risk_level.value,
            'details': result.details,
            'performed_at': result.performed_at.isoformat()
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error checking data residency: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/risk-assessment/<entity_id>', methods=['GET'])
def get_risk_assessment(entity_id):
    """Get risk assessment for an entity"""
    try:
        # Get all compliance checks for the entity
        status = compliance_manager.get_compliance_status(entity_id)
        
        if 'error' in status:
            return jsonify(status), 500
        
        # Calculate overall risk score
        risk_scores = {
            'low': 1,
            'medium': 2,
            'high': 3,
            'critical': 4
        }
        
        total_risk = 0
        check_count = 0
        
        for check_type, check_data in status.get('compliance_checks', {}).items():
            risk_level = check_data.get('risk_level', 'low')
            total_risk += risk_scores.get(risk_level, 1)
            check_count += 1
        
        average_risk = total_risk / max(check_count, 1)
        
        # Determine overall risk category
        if average_risk >= 3.5:
            overall_risk = 'critical'
        elif average_risk >= 2.5:
            overall_risk = 'high'
        elif average_risk >= 1.5:
            overall_risk = 'medium'
        else:
            overall_risk = 'low'
        
        response = {
            'entity_id': entity_id,
            'overall_risk_level': overall_risk,
            'risk_score': round(average_risk, 2),
            'checks_performed': check_count,
            'detailed_status': status,
            'assessment_timestamp': datetime.now().isoformat()
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error getting risk assessment: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.route('/api/compliance/types', methods=['GET'])
def get_compliance_types():
    """Get list of supported compliance check types"""
    try:
        compliance_types = [check_type.value for check_type in ComplianceCheckType]
        
        return jsonify({
            'compliance_types': compliance_types,
            'count': len(compliance_types)
        })
        
    except Exception as e:
        logger.error(f"Error getting compliance types: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@compliance_app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@compliance_app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    # Initialize the compliance system
    init_compliance_system()
    
    # Run the Flask app
    compliance_app.run(host='0.0.0.0', port=5001, debug=True)

