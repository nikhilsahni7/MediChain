import { PrismaClient } from "@prisma/client";
import crypto from "crypto";
import { NextFunction, Request, Response } from "express";
import Razorpay from "razorpay";
import { AppError } from "../middleware/error.middleware";

const prisma = new PrismaClient();

// Initialize Razorpay
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || "",
  key_secret: process.env.RAZORPAY_KEY_SECRET || "",
});

// Create order
export const createOrder = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const {
      medicineName,
      quantity,
      toHospitalId,
      emergency = false,
    } = req.body;

    // Validate fields
    if (!medicineName || !quantity || !toHospitalId) {
      throw new AppError("Please provide all required fields", 400);
    }

    // Check if destination hospital exists
    const toHospital = await prisma.hospital.findUnique({
      where: { id: toHospitalId },
    });

    if (!toHospital) {
      throw new AppError("Destination hospital not found", 404);
    }

    // Create order
    const order = await prisma.order.create({
      data: {
        medicineName,
        quantity,
        fromHospitalId: req.user.id,
        toHospitalId,
        emergency,
        status: "pending",
      },
    });

    // If emergency, emit an event (mock implementation for now)
    if (emergency) {
      console.log(
        `EMERGENCY ORDER: Hospital ${req.user.id} needs ${quantity} of ${medicineName} urgently!`
      );
      // In a real implementation, we would emit an event to the blockchain and send FCM notifications
    }

    res.status(201).json({
      status: "success",
      data: order,
    });
  } catch (error) {
    next(error);
  }
};

// Get all orders
export const getAllOrders = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const orders = await prisma.order.findMany({
      orderBy: {
        createdAt: "desc",
      },
    });

    res.status(200).json({
      status: "success",
      results: orders.length,
      data: orders,
    });
  } catch (error) {
    next(error);
  }
};

// Get my orders (as sender or receiver)
export const getMyOrders = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const orders = await prisma.order.findMany({
      where: {
        OR: [{ fromHospitalId: req.user.id }, { toHospitalId: req.user.id }],
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    res.status(200).json({
      status: "success",
      results: orders.length,
      data: orders,
    });
  } catch (error) {
    next(error);
  }
};

// Get order by ID
export const getOrderById = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { id } = req.params;

    const order = await prisma.order.findUnique({
      where: { id },
    });

    if (!order) {
      throw new AppError("Order not found", 404);
    }

    res.status(200).json({
      status: "success",
      data: order,
    });
  } catch (error) {
    next(error);
  }
};

// Update order status
export const updateOrderStatus = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { id } = req.params;
    const { status } = req.body;

    // Validate status
    if (!status || !["pending", "completed", "cancelled"].includes(status)) {
      throw new AppError("Invalid status", 400);
    }

    // Check if order exists
    const existingOrder = await prisma.order.findUnique({
      where: { id },
    });

    if (!existingOrder) {
      throw new AppError("Order not found", 404);
    }

    // Check if user is authorized to update this order
    if (
      existingOrder.fromHospitalId !== req.user.id &&
      existingOrder.toHospitalId !== req.user.id
    ) {
      throw new AppError("Not authorized to update this order", 403);
    }

    // Update order
    const order = await prisma.order.update({
      where: { id },
      data: { status },
    });

    // If status is completed, update reputation
    if (status === "completed") {
      // Increase reputation of the hospital that fulfilled the order
      await prisma.hospital.update({
        where: { id: existingOrder.toHospitalId },
        data: {
          reputation: {
            increment: 1,
          },
        },
      });
    }

    res.status(200).json({
      status: "success",
      data: order,
    });
  } catch (error) {
    next(error);
  }
};

// Create emergency order
export const createEmergencyOrder = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { medicineName, quantity, toHospitalId } = req.body;

    // Validate fields
    if (!medicineName || !quantity || !toHospitalId) {
      throw new AppError("Please provide all required fields", 400);
    }

    // Check if destination hospital exists
    const toHospital = await prisma.hospital.findUnique({
      where: { id: toHospitalId },
    });

    if (!toHospital) {
      throw new AppError("Destination hospital not found", 404);
    }

    // Create emergency order
    const order = await prisma.order.create({
      data: {
        medicineName,
        quantity,
        fromHospitalId: req.user.id,
        toHospitalId,
        emergency: true,
        status: "pending",
      },
    });

    // Emit an emergency event (mock implementation for now)
    console.log(
      `SOS BROADCAST: Hospital ${req.user.id} needs ${quantity} of ${medicineName} urgently!`
    );
    // In a real implementation, we would emit an event to the blockchain and send FCM notifications

    res.status(201).json({
      status: "success",
      data: order,
    });
  } catch (error) {
    next(error);
  }
};

// Complete order with blockchain transaction hash and NFT certificate
export const completeOrder = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { id } = req.params;
    const { transactionHash, nftCertificateId } = req.body;

    // Validate fields
    if (!transactionHash) {
      throw new AppError("Please provide transaction hash", 400);
    }

    // Check if order exists
    const existingOrder = await prisma.order.findUnique({
      where: { id },
    });

    if (!existingOrder) {
      throw new AppError("Order not found", 404);
    }

    // Check if user is the receiver of the order
    if (existingOrder.toHospitalId !== req.user.id) {
      throw new AppError("Not authorized to complete this order", 403);
    }

    // Complete order with blockchain transaction hash and optional NFT certificate
    const order = await prisma.order.update({
      where: { id },
      data: {
        status: "completed",
        transactionHash,
        nftCertificateId: nftCertificateId || undefined,
      },
    });

    // Increase reputation of the hospital that fulfilled the order
    await prisma.hospital.update({
      where: { id: existingOrder.toHospitalId },
      data: {
        reputation: {
          increment: 1,
        },
      },
    });

    res.status(200).json({
      status: "success",
      data: order,
    });
  } catch (error) {
    next(error);
  }
};

// Create payment order with Razorpay
export const createPaymentOrder = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { orderId, amount, currency = "INR" } = req.body;

    // Validate fields
    if (!orderId || !amount) {
      throw new AppError("Please provide orderId and amount", 400);
    }

    // Check if order exists
    const existingOrder = await prisma.order.findUnique({
      where: { id: orderId },
    });

    if (!existingOrder) {
      throw new AppError("Order not found", 404);
    }

    // Create Razorpay order
    try {
      const razorpayOrder = await razorpay.orders.create({
        amount: amount * 100, // amount in smallest currency unit (paise for INR)
        currency,
        receipt: orderId,
        notes: {
          orderId: orderId,
          hospitalId: req.user.id,
        },
      });

      // Update order with razorpayOrderId
      await prisma.order.update({
        where: { id: orderId },
        data: {
          razorpayOrderId: razorpayOrder.id,
          paymentMethod: "razorpay",
        },
      });

      res.status(200).json({
        status: "success",
        data: {
          razorpayOrderId: razorpayOrder.id,
          amount: razorpayOrder.amount,
          currency: razorpayOrder.currency,
          orderId: orderId,
        },
      });
    } catch (error: any) {
      console.error("Razorpay API error:", error);

      // Handle Razorpay specific errors
      if (error.statusCode === 401) {
        throw new AppError(
          "Razorpay authentication failed. Please check API keys.",
          500
        );
      } else {
        throw new AppError(
          `Razorpay error: ${error.message || "Unknown error"}`,
          500
        );
      }
    }
  } catch (error) {
    next(error);
  }
};

// Verify Razorpay payment
export const verifyRazorpayPayment = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { orderId, razorpayPaymentId, razorpaySignature } = req.body;

    // Validate fields
    if (!orderId || !razorpayPaymentId || !razorpaySignature) {
      throw new AppError("Please provide all required fields", 400);
    }

    // Get order details
    const order = await prisma.order.findUnique({
      where: { id: orderId },
    });

    if (!order) {
      throw new AppError("Order not found", 404);
    }

    // Verify signature
    const generatedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET || "")
      .update(`${order.razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (generatedSignature !== razorpaySignature) {
      throw new AppError("Invalid payment signature", 400);
    }

    // Update order with payment details
    const updatedOrder = await prisma.order.update({
      where: { id: orderId },
      data: {
        status: "completed",
        razorpayPaymentId,
        paymentStatus: "paid",
      },
    });

    // Increase reputation of the hospital that fulfilled the order
    await prisma.hospital.update({
      where: { id: order.toHospitalId },
      data: {
        reputation: {
          increment: 1,
        },
      },
    });

    res.status(200).json({
      status: "success",
      data: updatedOrder,
    });
  } catch (error) {
    next(error);
  }
};

// Razorpay webhook handler
export const razorpayWebhook = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
    const shasum = crypto.createHmac("sha256", webhookSecret || "");
    shasum.update(JSON.stringify(req.body));
    const digest = shasum.digest("hex");

    // Verify webhook signature
    if (digest !== req.headers["x-razorpay-signature"]) {
      throw new AppError("Invalid webhook signature", 400);
    }

    const event = req.body;

    // Handle payment success event
    if (event.event === "payment.captured") {
      const payment = event.payload.payment.entity;
      const orderId = payment.notes.orderId;

      // Update order status
      await prisma.order.update({
        where: { id: orderId },
        data: {
          status: "completed",
          razorpayPaymentId: payment.id,
          paymentStatus: "paid",
        },
      });
    }

    res.status(200).json({ received: true });
  } catch (error) {
    next(error);
  }
};
