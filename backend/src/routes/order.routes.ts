import express from "express";
import * as orderController from "../controllers/order.controller";
import { authenticate } from "../middleware/auth.middleware";

const router = express.Router();

// All order routes require authentication
router.use(authenticate);

router.post("/", orderController.createOrder);
router.get("/", orderController.getAllOrders);
router.get("/my-orders", orderController.getMyOrders);
router.get("/:id", orderController.getOrderById);
router.put("/:id/status", orderController.updateOrderStatus);
router.post("/emergency", orderController.createEmergencyOrder);
router.put("/:id/complete", orderController.completeOrder);

export default router;
