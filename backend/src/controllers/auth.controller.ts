import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";
import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { AppError } from "../middleware/error.middleware";

const prisma = new PrismaClient();

// Generate JWT token
const generateToken = (id: string, email: string): string => {
  return jwt.sign({ id, email }, process.env.JWT_SECRET!, {
    expiresIn: "30d",
  });
};

// Login hospital
export const login = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { email, password } = req.body;

    // Validate fields
    if (!email || !password) {
      throw new AppError("Please provide email and password", 400);
    }

    // Find hospital by email
    const hospital = await prisma.hospital.findUnique({
      where: { email },
    });

    if (!hospital) {
      throw new AppError("Invalid credentials", 401);
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, hospital.password);

    if (!isPasswordValid) {
      throw new AppError("Invalid credentials", 401);
    }

    // Generate token
    const token = generateToken(hospital.id, hospital.email);

    // Return response
    res.status(200).json({
      status: "success",
      data: {
        id: hospital.id,
        name: hospital.name,
        email: hospital.email,
        walletAddress: hospital.walletAddress,
        reputation: hospital.reputation,
        latitude: hospital.latitude,
        longitude: hospital.longitude,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Register new hospital
export const register = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { name, email, password, walletAddress, latitude, longitude } =
      req.body;

    // Validate fields
    if (
      !name ||
      !email ||
      !password ||
      !walletAddress ||
      !latitude ||
      !longitude
    ) {
      throw new AppError("Please provide all required fields", 400);
    }

    // Check if hospital already exists
    const existingHospital = await prisma.hospital.findUnique({
      where: { email },
    });

    if (existingHospital) {
      throw new AppError("Hospital with this email already exists", 400);
    }

    // Check if wallet address already exists
    const existingWallet = await prisma.hospital.findUnique({
      where: { walletAddress },
    });

    if (existingWallet) {
      throw new AppError("Wallet address already in use", 400);
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create hospital
    const hospital = await prisma.hospital.create({
      data: {
        name,
        email,
        password: hashedPassword,
        walletAddress,
        latitude,
        longitude,
      },
    });

    // Generate token
    const token = generateToken(hospital.id, hospital.email);

    // Return response
    res.status(201).json({
      status: "success",
      data: {
        id: hospital.id,
        name: hospital.name,
        email: hospital.email,
        walletAddress: hospital.walletAddress,
        reputation: hospital.reputation,
        latitude: hospital.latitude,
        longitude: hospital.longitude,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};
