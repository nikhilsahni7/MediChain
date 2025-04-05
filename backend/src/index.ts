import { PrismaClient } from "@prisma/client";
import cors from "cors";
import dotenv from "dotenv";
import express from "express";

// Import routes
import { errorHandler } from "./middleware/error.middleware";
import authRoutes from "./routes/auth.routes";
import hospitalRoutes from "./routes/hospital.routes";
import medicineRoutes from "./routes/medicine.routes";
import orderRoutes from "./routes/order.routes";

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/hospitals", hospitalRoutes);
app.use("/api/medicines", medicineRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/auth", authRoutes);

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", message: "MediChain API is running" });
});

// Error handling middleware
app.use(errorHandler);

// Start server
app.listen(PORT as any, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});

// Handle graceful shutdown
process.on("SIGINT", async () => {
  await prisma.$disconnect();
  console.log("Database connection closed");
  process.exit(0);
});

export default app;
