import * as tf from "tensorflow.js";
import { logger } from "../utils/logger";
import transactionModel from "../models/transaction.model";
import forecastModel from "../models/forecast.model";
import userPreferenceModel from "../models/user-preference.model";
import { ForecastCreateInput } from "../types/forecast.types";
import config from "../config";

class ForecastService {
  // Generate cash flow forecast for a user
  async generateForecast(userId: string, months: number = 3): Promise<any[]> {
    try {
      // Get user preferences
      const userPreference = await userPreferenceModel.findByUserId(userId);
      const forecastPeriod = userPreference?.forecastPeriod || months;

      // Get historical transaction data
      const endDate = new Date();
      const startDate = new Date();
      startDate.setMonth(
        startDate.getMonth() - config.transactionHistoryMonths,
      );

      const transactions = await transactionModel.findByUserIdAndDateRange(
        userId,
        startDate,
        endDate,
      );

      if (transactions.length < 3) {
        throw new Error("Insufficient transaction data for forecast");
      }

      // Prepare data for model
      const processedData = this.preprocessTransactions(transactions);

      // Generate forecast
      const forecast = await this.runForecastModel(
        userId,
        processedData,
        forecastPeriod,
      );

      // Save forecast results to database
      await this.saveForecastResults(userId, forecast);

      return forecast;
    } catch (error) {
      logger.error(`Error generating forecast: ${error}`);
      throw error;
    }
  }

  // Preprocess transactions for model input
  private preprocessTransactions(transactions: any[]): any {
    // Group transactions by month
    const monthlyData: { [key: string]: number } = {};

    transactions.forEach((transaction) => {
      const date = new Date(transaction.date);
      const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;

      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = 0;
      }

      monthlyData[monthKey] += transaction.amount;
    });

    // Convert to array sorted by date
    const sortedKeys = Object.keys(monthlyData).sort();
    const timeSeriesData = sortedKeys.map((key) => ({
      date: key,
      amount: monthlyData[key],
    }));

    return timeSeriesData;
  }

  // Run forecast model
  private async runForecastModel(
    userId: string,
    data: any[],
    months: number,
  ): Promise<any[]> {
    try {
      // Simple time series forecasting using moving average
      // In a real implementation, this would use TensorFlow.js for more sophisticated forecasting

      // Calculate average monthly change
      let sum = 0;
      for (let i = 1; i < data.length; i++) {
        sum += data[i].amount - data[i - 1].amount;
      }
      const avgChange = sum / (data.length - 1);

      // Generate forecast
      const forecast = [];
      const lastDate = new Date();
      const lastAmount = data[data.length - 1].amount;

      for (let i = 1; i <= months; i++) {
        const forecastDate = new Date();
        forecastDate.setMonth(lastDate.getMonth() + i);

        const forecastAmount = lastAmount + avgChange * i;
        const confidence = Math.max(0.5, 1 - i * 0.1); // Confidence decreases with time

        forecast.push({
          userId,
          month: forecastDate.getMonth() + 1,
          year: forecastDate.getFullYear(),
          amount: forecastAmount,
          confidence,
        });
      }

      return forecast;
    } catch (error) {
      logger.error(`Error running forecast model: ${error}`);
      throw error;
    }
  }

  // Save forecast results to database
  private async saveForecastResults(
    userId: string,
    forecast: any[],
  ): Promise<void> {
    try {
      // Delete existing forecasts for this user
      await forecastModel.deleteByUserId(userId);

      // Save new forecasts
      for (const item of forecast) {
        const forecastInput: ForecastCreateInput = {
          userId: item.userId,
          month: item.month,
          year: item.year,
          amount: item.amount,
          confidence: item.confidence,
        };

        await forecastModel.create(forecastInput);
      }
    } catch (error) {
      logger.error(`Error saving forecast results: ${error}`);
      throw error;
    }
  }

  // Get saved forecasts for a user
  async getForecastsByUserId(userId: string): Promise<any[]> {
    try {
      return await forecastModel.findByUserId(userId);
    } catch (error) {
      logger.error(`Error getting forecasts by user ID: ${error}`);
      throw error;
    }
  }
}

export default new ForecastService();
