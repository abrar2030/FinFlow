import unittest
from unittest.mock import patch, MagicMock
import sys
import os
import json
from datetime import datetime

# Add src directory to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '../src'))

from database import TransactionDatabase

class TestTransactionDatabase(unittest.TestCase):
    """Test suite for the TransactionDatabase class"""
    
    def setUp(self):
        """Set up test fixtures"""
        # Mock SQLAlchemy components
        self.mock_engine = MagicMock()
        self.mock_session = MagicMock()
        self.mock_session_maker = MagicMock(return_value=self.mock_session)
        
        # Patch create_engine and sessionmaker
        with patch('database.create_engine', return_value=self.mock_engine), \
             patch('database.sessionmaker', return_value=self.mock_session_maker):
            self.db = TransactionDatabase("sqlite:///:memory:")
        
        # Sample transaction data
        self.transaction_data = {
            "transaction_id": "tx-12345",
            "source_account_id": "account-123",
            "destination_account_id": "account-456",
            "amount": 1000.0,
            "currency": "USD",
            "transaction_type": "TRANSFER",
            "status": "COMPLETED",
            "reference": "REF123",
            "description": "Test transaction",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "risk_score": 0.2,
            "risk_level": "LOW",
            "metadata": {"test": True}
        }
    
    def test_create_transaction(self):
        """Test creating a transaction in the database"""
        # Configure mock session
        self.mock_session.__enter__.return_value = self.mock_session
        
        # Create transaction
        result = self.db.create_transaction(self.transaction_data)
        
        # Verify session was used correctly
        self.mock_session.execute.assert_called_once()
        self.mock_session.commit.assert_called_once()
        
        # Verify result
        self.assertEqual(result, "tx-12345")
    
    def test_get_transaction(self):
        """Test getting a transaction from the database"""
        # Configure mock session and result
        self.mock_session.__enter__.return_value = self.mock_session
        mock_result = MagicMock()
        mock_result.fetchone.return_value = self.transaction_data
        self.mock_session.execute.return_value = mock_result
        
        # Get transaction
        result = self.db.get_transaction("tx-12345")
        
        # Verify session was used correctly
        self.mock_session.execute.assert_called_once()
        
        # Verify result
        self.assertEqual(result, self.transaction_data)
    
    def test_get_transaction_not_found(self):
        """Test getting a transaction that doesn't exist"""
        # Configure mock session and result
        self.mock_session.__enter__.return_value = self.mock_session
        mock_result = MagicMock()
        mock_result.fetchone.return_value = None
        self.mock_session.execute.return_value = mock_result
        
        # Get transaction
        result = self.db.get_transaction("tx-nonexistent")
        
        # Verify session was used correctly
        self.mock_session.execute.assert_called_once()
        
        # Verify result is None
        self.assertIsNone(result)
    
    def test_update_transaction_status(self):
        """Test updating a transaction status"""
        # Configure mock session and result
        self.mock_session.__enter__.return_value = self.mock_session
        mock_result = MagicMock()
        mock_result.rowcount = 1
        self.mock_session.execute.return_value = mock_result
        
        # Update transaction status
        result = self.db.update_transaction_status("tx-12345", "COMPLETED")
        
        # Verify session was used correctly
        self.mock_session.execute.assert_called_once()
        self.mock_session.commit.assert_called_once()
        
        # Verify result
        self.assertTrue(result)
    
    def test_update_transaction_status_not_found(self):
        """Test updating a transaction status for non-existent transaction"""
        # Configure mock session and result
        self.mock_session.__enter__.return_value = self.mock_session
        mock_result = MagicMock()
        mock_result.rowcount = 0
        self.mock_session.execute.return_value = mock_result
        
        # Update transaction status
        result = self.db.update_transaction_status("tx-nonexistent", "COMPLETED")
        
        # Verify session was used correctly
        self.mock_session.execute.assert_called_once()
        self.mock_session.commit.assert_called_once()
        
        # Verify result
        self.assertFalse(result)
    
    def test_query_transactions(self):
        """Test querying transactions with filters"""
        # Configure mock session and results
        self.mock_session.__enter__.return_value = self.mock_session
        
        # Mock count query result
        mock_count_result = MagicMock()
        mock_count_result.scalar.return_value = 2
        
        # Mock main query result
        mock_query_result = MagicMock()
        mock_query_result.fetchall.return_value = [
            self.transaction_data,
            {**self.transaction_data, "transaction_id": "tx-67890"}
        ]
        
        # Configure session to return different results for different queries
        self.mock_session.execute.side_effect = [mock_count_result, mock_query_result]
        
        # Query transactions
        filters = {
            "account_id": "account-123",
            "transaction_type": "TRANSFER",
            "min_amount": 500.0,
            "max_amount": 2000.0
        }
        transactions, total = self.db.query_transactions(filters, limit=10, offset=0)
        
        # Verify session was used correctly
        self.assertEqual(self.mock_session.execute.call_count, 2)
        
        # Verify results
        self.assertEqual(len(transactions), 2)
        self.assertEqual(total, 2)
        self.assertEqual(transactions[0]["transaction_id"], "tx-12345")
        self.assertEqual(transactions[1]["transaction_id"], "tx-67890")
    
    def test_create_transaction_batch(self):
        """Test creating a batch of transactions"""
        # Configure mock session
        self.mock_session.__enter__.return_value = self.mock_session
        
        # Create batch of transactions
        transactions = [
            self.transaction_data,
            {**self.transaction_data, "transaction_id": "tx-67890"}
        ]
        batch_id, count = self.db.create_transaction_batch(transactions)
        
        # Verify session was used correctly
        self.mock_session.execute.assert_called_once()
        self.mock_session.commit.assert_called_once()
        
        # Verify results
        self.assertIsNotNone(batch_id)
        self.assertEqual(count, 2)
    
    def test_get_transaction_statistics(self):
        """Test getting transaction statistics"""
        # Configure mock session and results
        self.mock_session.__enter__.return_value = self.mock_session
        
        # Mock count query result
        mock_count_result = MagicMock()
        mock_count_result.total_count = 100
        mock_count_result.total_amount = 50000.0
        mock_count_result.average_amount = 500.0
        
        # Mock status query result
        mock_status_results = [
            MagicMock(status="COMPLETED", count=80),
            MagicMock(status="PENDING", count=20)
        ]
        
        # Mock type query result
        mock_type_results = [
            MagicMock(transaction_type="TRANSFER", count=60),
            MagicMock(transaction_type="PAYMENT", count=40)
        ]
        
        # Configure session to return different results for different queries
        self.mock_session.execute.side_effect = [
            MagicMock(fetchone=lambda: mock_count_result),
            MagicMock(fetchall=lambda: mock_status_results),
            MagicMock(fetchall=lambda: mock_type_results)
        ]
        
        # Get statistics
        stats = self.db.get_transaction_statistics(
            account_id="account-123",
            start_date="2025-01-01",
            end_date="2025-05-31"
        )
        
        # Verify session was used correctly
        self.assertEqual(self.mock_session.execute.call_count, 3)
        
        # Verify results
        self.assertEqual(stats["total_count"], 100)
        self.assertEqual(stats["total_amount"], 50000.0)
        self.assertEqual(stats["average_amount"], 500.0)
        self.assertEqual(stats["by_status"]["COMPLETED"], 80)
        self.assertEqual(stats["by_status"]["PENDING"], 20)
        self.assertEqual(stats["by_type"]["TRANSFER"], 60)
        self.assertEqual(stats["by_type"]["PAYMENT"], 40)
        self.assertEqual(stats["period_start"], "2025-01-01")
        self.assertEqual(stats["period_end"], "2025-05-31")
    
    def test_database_error_handling(self):
        """Test handling database errors"""
        # Configure mock session to raise an exception
        self.mock_session.__enter__.return_value = self.mock_session
        self.mock_session.execute.side_effect = Exception("Database error")
        
        # Attempt to create transaction
        with self.assertRaises(Exception):
            self.db.create_transaction(self.transaction_data)
        
        # Verify session was rolled back
        self.mock_session.rollback.assert_called_once()


if __name__ == '__main__':
    unittest.main()
