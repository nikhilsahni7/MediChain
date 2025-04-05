import dotenv from "dotenv";

// Load environment variables
dotenv.config();

const config = {
  env: process.env.NODE_ENV || "development",
  port: process.env.PORT || 3000,
  jwtSecret: process.env.JWT_SECRET || "medileger-secret-key",
  db: {
    url:
      process.env.DATABASE_URL ||
      "postgresql://postgres:postgres@localhost:5432/medileger?schema=public",
  },
};

export default config;
