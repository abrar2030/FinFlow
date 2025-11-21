import dotenv from "dotenv";

dotenv.config();

const config = {
  jwt: {
    secret: process.env.JWT_SECRET || "default_jwt_secret_fallback",
    expiresIn: process.env.JWT_EXPIRES_IN || "1h",
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "7d",
  },
  stripe: {
    apiKey: process.env.STRIPE_API_KEY || "default_stripe_api_key_fallback",
  },
  // Add other common configurations here
};

export default config;
