import express from "express";
import authController from "../controllers/auth.controller";
import { authenticate } from "../middlewares/auth.middleware";
import { validate } from "../middlewares/validation.middleware";
import {
  registerValidation,
  loginValidation,
  refreshTokenValidation,
} from "../validators/auth.validator";

const router = express.Router();

// Register a new user
router.post(
  "/register",
  validate(registerValidation),
  authController.register.bind(authController),
);

// Login user
router.post(
  "/login",
  validate(loginValidation),
  authController.login.bind(authController),
);

// Get current user
router.get("/me", authenticate, authController.me.bind(authController));

// Refresh access token
router.post(
  "/refresh",
  validate(refreshTokenValidation),
  authController.refreshToken.bind(authController),
);

// Logout user
router.post(
  "/logout",
  authenticate,
  authController.logout.bind(authController),
);

export default router;
