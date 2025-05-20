import express from 'express';
import forecastController from '../controllers/forecast.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validation.middleware';
import { createForecastRequestValidation } from '../validators/forecast.validator';

const router = express.Router();

// Generate forecast
router.post(
  '/',
  authenticate,
  validate(createForecastRequestValidation),
  forecastController.generateForecast.bind(forecastController)
);

// Get forecasts by user ID
router.get(
  '/',
  authenticate,
  forecastController.getForecastsByUserId.bind(forecastController)
);

export default router;
