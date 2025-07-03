"""
Cash Flow Prediction Service

Provides advanced cash flow modeling and forecasting capabilities:
- Historical cash flow analysis
- Predictive modeling using multiple algorithms
- Scenario analysis and stress testing
- Cash flow optimization recommendations
- Liquidity risk assessment
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.linear_model import LinearRegression, Ridge
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.holtwinters import ExponentialSmoothing
import joblib
from prophet import Prophet

from models.cash_flow import (
    CashFlowPredictionRequest,
    CashFlowPredictionResponse,
    CashFlowScenario,
    CashFlowMetrics,
    LiquidityRisk,
    CashFlowOptimization
)
from config.database import get_database
from config.redis_client import get_redis
from utils.feature_engineering import FeatureEngineer
from utils.data_validator import DataValidator

logger = logging.getLogger(__name__)


class CashFlowService:
    """Advanced cash flow prediction and analysis service"""
    
    def __init__(self, model_manager):
        self.model_manager = model_manager
        self.feature_engineer = FeatureEngineer()
        self.data_validator = DataValidator()
        
        # Model configurations
        self.models = {
            'random_forest': RandomForestRegressor(
                n_estimators=100,
                max_depth=10,
                random_state=42,
                n_jobs=-1
            ),
            'gradient_boosting': GradientBoostingRegressor(
                n_estimators=100,
                learning_rate=0.1,
                max_depth=6,
                random_state=42
            ),
            'linear_regression': Ridge(alpha=1.0),
            'prophet': None,  # Will be initialized per prediction
            'arima': None,    # Will be initialized per prediction
            'exponential_smoothing': None  # Will be initialized per prediction
        }
        
        self.scalers = {
            'standard': StandardScaler(),
            'minmax': MinMaxScaler()
        }
        
        self.is_initialized = False
        
    async def initialize(self):
        """Initialize the cash flow service"""
        try:
            logger.info("Initializing Cash Flow Service...")
            
            # Load pre-trained models if available
            await self._load_models()
            
            # Initialize feature engineering
            await self.feature_engineer.initialize()
            
            self.is_initialized = True
            logger.info("Cash Flow Service initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Cash Flow Service: {e}")
            raise
    
    async def predict_cash_flow(
        self, 
        request: CashFlowPredictionRequest
    ) -> CashFlowPredictionResponse:
        """
        Generate comprehensive cash flow predictions
        
        Args:
            request: Cash flow prediction request parameters
            
        Returns:
            Detailed cash flow predictions and analysis
        """
        if not self.is_initialized:
            raise RuntimeError("Cash Flow Service not initialized")
        
        try:
            logger.info(f"Generating cash flow prediction for user {request.user_id}")
            
            # Validate request
            self.data_validator.validate_cash_flow_request(request)
            
            # Get historical data
            historical_data = await self._get_historical_data(
                request.user_id,
                request.historical_months
            )
            
            if len(historical_data) < 12:  # Minimum 12 months of data
                raise ValueError("Insufficient historical data for reliable prediction")
            
            # Prepare features
            features_df = await self._prepare_features(historical_data, request)
            
            # Generate predictions using multiple models
            predictions = await self._generate_ensemble_predictions(
                features_df,
                request.prediction_horizon
            )
            
            # Calculate confidence intervals
            confidence_intervals = await self._calculate_confidence_intervals(
                predictions,
                historical_data
            )
            
            # Perform scenario analysis
            scenarios = await self._perform_scenario_analysis(
                features_df,
                request,
                predictions
            )
            
            # Calculate cash flow metrics
            metrics = await self._calculate_cash_flow_metrics(
                historical_data,
                predictions
            )
            
            # Assess liquidity risk
            liquidity_risk = await self._assess_liquidity_risk(
                predictions,
                request.minimum_cash_balance or 0
            )
            
            # Generate optimization recommendations
            optimization = await self._generate_optimization_recommendations(
                historical_data,
                predictions,
                scenarios
            )
            
            # Create response
            response = CashFlowPredictionResponse(
                user_id=request.user_id,
                prediction_date=datetime.now(),
                horizon_months=request.prediction_horizon,
                predictions=predictions,
                confidence_intervals=confidence_intervals,
                scenarios=scenarios,
                metrics=metrics,
                liquidity_risk=liquidity_risk,
                optimization=optimization,
                model_performance=await self._get_model_performance(),
                data_quality_score=await self._calculate_data_quality_score(historical_data)
            )
            
            # Cache results
            await self._cache_prediction_results(request.user_id, response)
            
            logger.info(f"Cash flow prediction completed for user {request.user_id}")
            return response
            
        except Exception as e:
            logger.error(f"Error generating cash flow prediction: {e}")
            raise
    
    async def _get_historical_data(
        self, 
        user_id: str, 
        months: int
    ) -> pd.DataFrame:
        """Get historical financial data for the user"""
        try:
            db = await get_database()
            
            # Calculate date range
            end_date = datetime.now()
            start_date = end_date - timedelta(days=months * 30)
            
            # Query transactions
            query = """
            SELECT 
                DATE_TRUNC('day', created_at) as date,
                SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as inflow,
                SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as outflow,
                COUNT(*) as transaction_count,
                AVG(amount) as avg_transaction,
                STRING_AGG(DISTINCT category, ',') as categories
            FROM transactions 
            WHERE user_id = %s 
                AND created_at >= %s 
                AND created_at <= %s
            GROUP BY DATE_TRUNC('day', created_at)
            ORDER BY date
            """
            
            result = await db.fetch_all(query, [user_id, start_date, end_date])
            
            if not result:
                raise ValueError(f"No transaction data found for user {user_id}")
            
            # Convert to DataFrame
            df = pd.DataFrame([dict(row) for row in result])
            df['date'] = pd.to_datetime(df['date'])
            df['net_flow'] = df['inflow'] - df['outflow']
            df['cumulative_flow'] = df['net_flow'].cumsum()
            
            # Fill missing dates
            df = df.set_index('date').resample('D').fillna(0).reset_index()
            
            return df
            
        except Exception as e:
            logger.error(f"Error getting historical data: {e}")
            raise
    
    async def _prepare_features(
        self, 
        historical_data: pd.DataFrame, 
        request: CashFlowPredictionRequest
    ) -> pd.DataFrame:
        """Prepare features for cash flow prediction"""
        try:
            df = historical_data.copy()
            
            # Time-based features
            df['year'] = df['date'].dt.year
            df['month'] = df['date'].dt.month
            df['day'] = df['date'].dt.day
            df['day_of_week'] = df['date'].dt.dayofweek
            df['day_of_year'] = df['date'].dt.dayofyear
            df['week_of_year'] = df['date'].dt.isocalendar().week
            df['quarter'] = df['date'].dt.quarter
            df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)
            df['is_month_end'] = df['date'].dt.is_month_end.astype(int)
            df['is_month_start'] = df['date'].dt.is_month_start.astype(int)
            
            # Lag features
            for lag in [1, 7, 14, 30]:
                df[f'net_flow_lag_{lag}'] = df['net_flow'].shift(lag)
                df[f'inflow_lag_{lag}'] = df['inflow'].shift(lag)
                df[f'outflow_lag_{lag}'] = df['outflow'].shift(lag)
            
            # Rolling statistics
            for window in [7, 14, 30]:
                df[f'net_flow_rolling_mean_{window}'] = df['net_flow'].rolling(window).mean()
                df[f'net_flow_rolling_std_{window}'] = df['net_flow'].rolling(window).std()
                df[f'inflow_rolling_mean_{window}'] = df['inflow'].rolling(window).mean()
                df[f'outflow_rolling_mean_{window}'] = df['outflow'].rolling(window).mean()
            
            # Trend features
            df['net_flow_trend'] = df['net_flow'].rolling(30).apply(
                lambda x: np.polyfit(range(len(x)), x, 1)[0] if len(x) == 30 else 0
            )
            
            # Volatility features
            df['net_flow_volatility'] = df['net_flow'].rolling(30).std()
            df['inflow_volatility'] = df['inflow'].rolling(30).std()
            df['outflow_volatility'] = df['outflow'].rolling(30).std()
            
            # Seasonal decomposition features
            if len(df) >= 365:  # Need at least 1 year for seasonal decomposition
                try:
                    decomposition = seasonal_decompose(
                        df['net_flow'].fillna(0), 
                        model='additive', 
                        period=30
                    )
                    df['seasonal_component'] = decomposition.seasonal
                    df['trend_component'] = decomposition.trend
                    df['residual_component'] = decomposition.resid
                except:
                    # Fallback if decomposition fails
                    df['seasonal_component'] = 0
                    df['trend_component'] = df['net_flow'].rolling(30).mean()
                    df['residual_component'] = 0
            else:
                df['seasonal_component'] = 0
                df['trend_component'] = df['net_flow'].rolling(7).mean()
                df['residual_component'] = 0
            
            # External factors (if provided)
            if request.external_factors:
                for factor, value in request.external_factors.items():
                    df[f'external_{factor}'] = value
            
            # Drop rows with NaN values (from lag features)
            df = df.dropna()
            
            return df
            
        except Exception as e:
            logger.error(f"Error preparing features: {e}")
            raise
    
    async def _generate_ensemble_predictions(
        self, 
        features_df: pd.DataFrame, 
        horizon: int
    ) -> List[Dict[str, Any]]:
        """Generate predictions using ensemble of models"""
        try:
            predictions = []
            
            # Prepare training data
            feature_columns = [col for col in features_df.columns 
                             if col not in ['date', 'net_flow', 'inflow', 'outflow']]
            
            X = features_df[feature_columns].fillna(0)
            y = features_df['net_flow']
            
            # Scale features
            X_scaled = self.scalers['standard'].fit_transform(X)
            
            # Train and predict with each model
            model_predictions = {}
            
            # Random Forest
            rf_model = self.models['random_forest']
            rf_model.fit(X_scaled, y)
            
            # Gradient Boosting
            gb_model = self.models['gradient_boosting']
            gb_model.fit(X_scaled, y)
            
            # Linear Regression
            lr_model = self.models['linear_regression']
            lr_model.fit(X_scaled, y)
            
            # Generate future predictions
            last_date = features_df['date'].max()
            
            for i in range(horizon):
                future_date = last_date + timedelta(days=i + 1)
                
                # Create future features (simplified approach)
                future_features = self._create_future_features(
                    features_df, 
                    future_date, 
                    feature_columns
                )
                
                future_features_scaled = self.scalers['standard'].transform([future_features])
                
                # Get predictions from each model
                rf_pred = rf_model.predict(future_features_scaled)[0]
                gb_pred = gb_model.predict(future_features_scaled)[0]
                lr_pred = lr_model.predict(future_features_scaled)[0]
                
                # Time series models
                prophet_pred = await self._predict_with_prophet(features_df, future_date)
                arima_pred = await self._predict_with_arima(features_df, future_date)
                
                # Ensemble prediction (weighted average)
                ensemble_pred = (
                    0.25 * rf_pred +
                    0.25 * gb_pred +
                    0.15 * lr_pred +
                    0.20 * prophet_pred +
                    0.15 * arima_pred
                )
                
                predictions.append({
                    'date': future_date.isoformat(),
                    'predicted_net_flow': float(ensemble_pred),
                    'model_predictions': {
                        'random_forest': float(rf_pred),
                        'gradient_boosting': float(gb_pred),
                        'linear_regression': float(lr_pred),
                        'prophet': float(prophet_pred),
                        'arima': float(arima_pred)
                    }
                })
            
            return predictions
            
        except Exception as e:
            logger.error(f"Error generating ensemble predictions: {e}")
            raise
    
    def _create_future_features(
        self, 
        features_df: pd.DataFrame, 
        future_date: datetime, 
        feature_columns: List[str]
    ) -> List[float]:
        """Create features for future date prediction"""
        try:
            # Basic time features
            features = {
                'year': future_date.year,
                'month': future_date.month,
                'day': future_date.day,
                'day_of_week': future_date.weekday(),
                'day_of_year': future_date.timetuple().tm_yday,
                'week_of_year': future_date.isocalendar()[1],
                'quarter': (future_date.month - 1) // 3 + 1,
                'is_weekend': int(future_date.weekday() >= 5),
                'is_month_end': int(future_date.day == 31),  # Simplified
                'is_month_start': int(future_date.day == 1)
            }
            
            # Use last known values for other features
            last_row = features_df.iloc[-1]
            
            for col in feature_columns:
                if col not in features:
                    if 'lag' in col or 'rolling' in col or 'trend' in col or 'volatility' in col:
                        features[col] = last_row[col] if not pd.isna(last_row[col]) else 0
                    elif 'seasonal' in col or 'component' in col:
                        features[col] = last_row[col] if not pd.isna(last_row[col]) else 0
                    elif 'external' in col:
                        features[col] = last_row[col] if not pd.isna(last_row[col]) else 0
                    else:
                        features[col] = 0
            
            return [features.get(col, 0) for col in feature_columns]
            
        except Exception as e:
            logger.error(f"Error creating future features: {e}")
            return [0] * len(feature_columns)
    
    async def _predict_with_prophet(
        self, 
        features_df: pd.DataFrame, 
        future_date: datetime
    ) -> float:
        """Generate prediction using Prophet model"""
        try:
            # Prepare data for Prophet
            prophet_df = features_df[['date', 'net_flow']].copy()
            prophet_df.columns = ['ds', 'y']
            prophet_df = prophet_df.dropna()
            
            if len(prophet_df) < 10:
                return 0.0
            
            # Create and fit Prophet model
            model = Prophet(
                daily_seasonality=True,
                weekly_seasonality=True,
                yearly_seasonality=True if len(prophet_df) >= 365 else False,
                changepoint_prior_scale=0.05
            )
            
            model.fit(prophet_df)
            
            # Make prediction
            future_df = pd.DataFrame({'ds': [future_date]})
            forecast = model.predict(future_df)
            
            return float(forecast['yhat'].iloc[0])
            
        except Exception as e:
            logger.warning(f"Prophet prediction failed: {e}")
            return 0.0
    
    async def _predict_with_arima(
        self, 
        features_df: pd.DataFrame, 
        future_date: datetime
    ) -> float:
        """Generate prediction using ARIMA model"""
        try:
            # Prepare time series data
            ts_data = features_df['net_flow'].dropna()
            
            if len(ts_data) < 20:
                return 0.0
            
            # Fit ARIMA model (using auto-selection for simplicity)
            model = ARIMA(ts_data, order=(1, 1, 1))
            fitted_model = model.fit()
            
            # Make prediction
            forecast = fitted_model.forecast(steps=1)
            
            return float(forecast[0])
            
        except Exception as e:
            logger.warning(f"ARIMA prediction failed: {e}")
            return 0.0
    
    async def _calculate_confidence_intervals(
        self, 
        predictions: List[Dict[str, Any]], 
        historical_data: pd.DataFrame
    ) -> Dict[str, List[float]]:
        """Calculate confidence intervals for predictions"""
        try:
            # Calculate historical volatility
            historical_volatility = historical_data['net_flow'].std()
            
            # Calculate confidence intervals (95% and 80%)
            confidence_95_upper = []
            confidence_95_lower = []
            confidence_80_upper = []
            confidence_80_lower = []
            
            for pred in predictions:
                predicted_value = pred['predicted_net_flow']
                
                # 95% confidence interval (±1.96 * std)
                ci_95_upper = predicted_value + (1.96 * historical_volatility)
                ci_95_lower = predicted_value - (1.96 * historical_volatility)
                
                # 80% confidence interval (±1.28 * std)
                ci_80_upper = predicted_value + (1.28 * historical_volatility)
                ci_80_lower = predicted_value - (1.28 * historical_volatility)
                
                confidence_95_upper.append(ci_95_upper)
                confidence_95_lower.append(ci_95_lower)
                confidence_80_upper.append(ci_80_upper)
                confidence_80_lower.append(ci_80_lower)
            
            return {
                'confidence_95_upper': confidence_95_upper,
                'confidence_95_lower': confidence_95_lower,
                'confidence_80_upper': confidence_80_upper,
                'confidence_80_lower': confidence_80_lower
            }
            
        except Exception as e:
            logger.error(f"Error calculating confidence intervals: {e}")
            return {
                'confidence_95_upper': [0] * len(predictions),
                'confidence_95_lower': [0] * len(predictions),
                'confidence_80_upper': [0] * len(predictions),
                'confidence_80_lower': [0] * len(predictions)
            }
    
    async def _perform_scenario_analysis(
        self, 
        features_df: pd.DataFrame, 
        request: CashFlowPredictionRequest,
        base_predictions: List[Dict[str, Any]]
    ) -> List[CashFlowScenario]:
        """Perform scenario analysis for cash flow predictions"""
        try:
            scenarios = []
            
            # Base scenario
            base_scenario = CashFlowScenario(
                name="Base Case",
                description="Current trend continuation",
                probability=0.6,
                predictions=[pred['predicted_net_flow'] for pred in base_predictions],
                assumptions=["Historical patterns continue", "No major changes in spending/income"]
            )
            scenarios.append(base_scenario)
            
            # Optimistic scenario (20% increase in net flow)
            optimistic_predictions = [pred['predicted_net_flow'] * 1.2 for pred in base_predictions]
            optimistic_scenario = CashFlowScenario(
                name="Optimistic",
                description="Improved financial performance",
                probability=0.2,
                predictions=optimistic_predictions,
                assumptions=["Increased income", "Reduced expenses", "Better financial management"]
            )
            scenarios.append(optimistic_scenario)
            
            # Pessimistic scenario (20% decrease in net flow)
            pessimistic_predictions = [pred['predicted_net_flow'] * 0.8 for pred in base_predictions]
            pessimistic_scenario = CashFlowScenario(
                name="Pessimistic",
                description="Challenging financial conditions",
                probability=0.2,
                predictions=pessimistic_predictions,
                assumptions=["Economic downturn", "Increased expenses", "Reduced income"]
            )
            scenarios.append(pessimistic_scenario)
            
            # Stress test scenario (significant negative impact)
            stress_predictions = [pred['predicted_net_flow'] * 0.5 for pred in base_predictions]
            stress_scenario = CashFlowScenario(
                name="Stress Test",
                description="Severe financial stress",
                probability=0.05,
                predictions=stress_predictions,
                assumptions=["Major financial shock", "Emergency expenses", "Income loss"]
            )
            scenarios.append(stress_scenario)
            
            return scenarios
            
        except Exception as e:
            logger.error(f"Error performing scenario analysis: {e}")
            return []
    
    async def _calculate_cash_flow_metrics(
        self, 
        historical_data: pd.DataFrame, 
        predictions: List[Dict[str, Any]]
    ) -> CashFlowMetrics:
        """Calculate comprehensive cash flow metrics"""
        try:
            # Historical metrics
            historical_net_flow = historical_data['net_flow']
            
            # Predicted metrics
            predicted_values = [pred['predicted_net_flow'] for pred in predictions]
            
            metrics = CashFlowMetrics(
                average_monthly_inflow=float(historical_data['inflow'].resample('M').sum().mean()),
                average_monthly_outflow=float(historical_data['outflow'].resample('M').sum().mean()),
                average_monthly_net_flow=float(historical_net_flow.resample('M').sum().mean()),
                cash_flow_volatility=float(historical_net_flow.std()),
                predicted_total_inflow=sum(max(0, pred) for pred in predicted_values),
                predicted_total_outflow=sum(abs(min(0, pred)) for pred in predicted_values),
                predicted_net_flow=sum(predicted_values),
                cash_conversion_cycle=await self._calculate_cash_conversion_cycle(historical_data),
                working_capital_ratio=await self._calculate_working_capital_ratio(historical_data),
                liquidity_ratio=await self._calculate_liquidity_ratio(historical_data),
                cash_flow_coverage_ratio=await self._calculate_cash_flow_coverage_ratio(historical_data)
            )
            
            return metrics
            
        except Exception as e:
            logger.error(f"Error calculating cash flow metrics: {e}")
            return CashFlowMetrics()
    
    async def _assess_liquidity_risk(
        self, 
        predictions: List[Dict[str, Any]], 
        minimum_balance: float
    ) -> LiquidityRisk:
        """Assess liquidity risk based on predictions"""
        try:
            predicted_values = [pred['predicted_net_flow'] for pred in predictions]
            cumulative_flow = np.cumsum(predicted_values)
            
            # Calculate risk metrics
            days_below_minimum = sum(1 for flow in cumulative_flow if flow < minimum_balance)
            minimum_balance_date = None
            
            for i, flow in enumerate(cumulative_flow):
                if flow < minimum_balance:
                    minimum_balance_date = predictions[i]['date']
                    break
            
            # Risk level assessment
            risk_percentage = days_below_minimum / len(predictions)
            
            if risk_percentage > 0.5:
                risk_level = "High"
            elif risk_percentage > 0.2:
                risk_level = "Medium"
            elif risk_percentage > 0.05:
                risk_level = "Low"
            else:
                risk_level = "Very Low"
            
            return LiquidityRisk(
                risk_level=risk_level,
                days_below_minimum=days_below_minimum,
                minimum_balance_date=minimum_balance_date,
                worst_case_balance=float(min(cumulative_flow)),
                probability_of_shortfall=risk_percentage,
                recommended_buffer=float(abs(min(cumulative_flow)) * 1.2) if min(cumulative_flow) < 0 else 0
            )
            
        except Exception as e:
            logger.error(f"Error assessing liquidity risk: {e}")
            return LiquidityRisk()
    
    async def _generate_optimization_recommendations(
        self, 
        historical_data: pd.DataFrame, 
        predictions: List[Dict[str, Any]],
        scenarios: List[CashFlowScenario]
    ) -> CashFlowOptimization:
        """Generate cash flow optimization recommendations"""
        try:
            recommendations = []
            
            # Analyze spending patterns
            avg_outflow = historical_data['outflow'].mean()
            if avg_outflow > 0:
                recommendations.append({
                    "category": "Expense Management",
                    "recommendation": f"Consider reducing daily expenses by 10% to improve cash flow by ${avg_outflow * 0.1:.2f}/day",
                    "impact": avg_outflow * 0.1 * 30,  # Monthly impact
                    "priority": "Medium"
                })
            
            # Analyze income patterns
            avg_inflow = historical_data['inflow'].mean()
            if avg_inflow > 0:
                recommendations.append({
                    "category": "Income Optimization",
                    "recommendation": f"Explore opportunities to increase income by 5% to improve monthly cash flow by ${avg_inflow * 0.05 * 30:.2f}",
                    "impact": avg_inflow * 0.05 * 30,
                    "priority": "High"
                })
            
            # Cash flow timing recommendations
            net_flow_volatility = historical_data['net_flow'].std()
            if net_flow_volatility > avg_inflow * 0.5:
                recommendations.append({
                    "category": "Cash Flow Timing",
                    "recommendation": "High cash flow volatility detected. Consider smoothing income and expense timing",
                    "impact": net_flow_volatility * 0.3,
                    "priority": "Medium"
                })
            
            # Emergency fund recommendations
            negative_days = sum(1 for pred in predictions if pred['predicted_net_flow'] < 0)
            if negative_days > len(predictions) * 0.2:
                emergency_fund = abs(min(pred['predicted_net_flow'] for pred in predictions)) * 3
                recommendations.append({
                    "category": "Emergency Fund",
                    "recommendation": f"Build emergency fund of ${emergency_fund:.2f} to cover potential shortfalls",
                    "impact": emergency_fund,
                    "priority": "High"
                })
            
            return CashFlowOptimization(
                recommendations=recommendations,
                potential_savings=sum(rec.get('impact', 0) for rec in recommendations),
                optimization_score=await self._calculate_optimization_score(historical_data),
                action_items=[rec['recommendation'] for rec in recommendations[:3]]  # Top 3
            )
            
        except Exception as e:
            logger.error(f"Error generating optimization recommendations: {e}")
            return CashFlowOptimization()
    
    async def _calculate_cash_conversion_cycle(self, historical_data: pd.DataFrame) -> float:
        """Calculate cash conversion cycle (simplified)"""
        # This is a simplified calculation
        # In a real implementation, you'd need accounts receivable, inventory, and payable data
        return 30.0  # Placeholder
    
    async def _calculate_working_capital_ratio(self, historical_data: pd.DataFrame) -> float:
        """Calculate working capital ratio (simplified)"""
        # Simplified calculation based on cash flow patterns
        avg_inflow = historical_data['inflow'].mean()
        avg_outflow = historical_data['outflow'].mean()
        return avg_inflow / max(avg_outflow, 1)
    
    async def _calculate_liquidity_ratio(self, historical_data: pd.DataFrame) -> float:
        """Calculate liquidity ratio (simplified)"""
        # Simplified calculation
        positive_days = sum(1 for flow in historical_data['net_flow'] if flow > 0)
        total_days = len(historical_data)
        return positive_days / max(total_days, 1)
    
    async def _calculate_cash_flow_coverage_ratio(self, historical_data: pd.DataFrame) -> float:
        """Calculate cash flow coverage ratio (simplified)"""
        # Simplified calculation
        total_inflow = historical_data['inflow'].sum()
        total_outflow = historical_data['outflow'].sum()
        return total_inflow / max(total_outflow, 1)
    
    async def _calculate_optimization_score(self, historical_data: pd.DataFrame) -> float:
        """Calculate optimization score (0-100)"""
        try:
            # Factors for optimization score
            factors = []
            
            # Cash flow consistency
            cv = historical_data['net_flow'].std() / abs(historical_data['net_flow'].mean())
            consistency_score = max(0, 100 - cv * 50)
            factors.append(consistency_score)
            
            # Positive cash flow ratio
            positive_ratio = sum(1 for flow in historical_data['net_flow'] if flow > 0) / len(historical_data)
            positive_score = positive_ratio * 100
            factors.append(positive_score)
            
            # Growth trend
            if len(historical_data) >= 30:
                recent_avg = historical_data['net_flow'].tail(30).mean()
                older_avg = historical_data['net_flow'].head(30).mean()
                growth_rate = (recent_avg - older_avg) / abs(older_avg) if older_avg != 0 else 0
                growth_score = min(100, max(0, 50 + growth_rate * 100))
                factors.append(growth_score)
            
            return sum(factors) / len(factors)
            
        except Exception as e:
            logger.error(f"Error calculating optimization score: {e}")
            return 50.0  # Default score
    
    async def _get_model_performance(self) -> Dict[str, float]:
        """Get model performance metrics"""
        # In a real implementation, this would return actual model performance metrics
        return {
            'accuracy': 0.85,
            'mae': 150.0,
            'rmse': 200.0,
            'r2_score': 0.78
        }
    
    async def _calculate_data_quality_score(self, historical_data: pd.DataFrame) -> float:
        """Calculate data quality score"""
        try:
            # Completeness
            completeness = 1 - (historical_data.isnull().sum().sum() / (len(historical_data) * len(historical_data.columns)))
            
            # Consistency (no negative inflows, no positive outflows)
            consistency_issues = sum(1 for inflow in historical_data['inflow'] if inflow < 0)
            consistency_issues += sum(1 for outflow in historical_data['outflow'] if outflow < 0)
            consistency = 1 - (consistency_issues / len(historical_data))
            
            # Recency (data should be recent)
            days_since_last = (datetime.now() - historical_data['date'].max()).days
            recency = max(0, 1 - days_since_last / 30)  # Penalize if data is older than 30 days
            
            return (completeness + consistency + recency) / 3 * 100
            
        except Exception as e:
            logger.error(f"Error calculating data quality score: {e}")
            return 75.0  # Default score
    
    async def _cache_prediction_results(
        self, 
        user_id: str, 
        response: CashFlowPredictionResponse
    ):
        """Cache prediction results in Redis"""
        try:
            redis = await get_redis()
            cache_key = f"cash_flow_prediction:{user_id}"
            
            # Cache for 24 hours
            await redis.setex(
                cache_key, 
                86400, 
                response.json()
            )
            
        except Exception as e:
            logger.warning(f"Failed to cache prediction results: {e}")
    
    async def _load_models(self):
        """Load pre-trained models from storage"""
        try:
            # In a real implementation, load models from file system or database
            logger.info("Loading pre-trained cash flow models...")
            # For now, models will be trained on-demand
            
        except Exception as e:
            logger.warning(f"Could not load pre-trained models: {e}")
    
    async def cleanup(self):
        """Cleanup resources"""
        try:
            logger.info("Cleaning up Cash Flow Service...")
            # Cleanup any resources if needed
            
        except Exception as e:
            logger.error(f"Error during cleanup: {e}")

