import { PrismaClient } from "@prisma/client";
import { NextFunction, Request, Response } from "express";
import { AppError } from "../middleware/error.middleware";

const prisma = new PrismaClient();

// Get all medicines
export const getAllMedicines = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const medicines = await prisma.medicine.findMany({
      include: {
        hospital: {
          select: {
            id: true,
            name: true,
            email: true,
            walletAddress: true,
            reputation: true,
            latitude: true,
            longitude: true,
          },
        },
      },
    });

    res.status(200).json({
      status: "success",
      results: medicines.length,
      data: medicines,
    });
  } catch (error) {
    next(error);
  }
};

// Get medicine by ID
export const getMedicineById = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { id } = req.params;

    const medicine = await prisma.medicine.findUnique({
      where: { id },
      include: {
        hospital: {
          select: {
            id: true,
            name: true,
            email: true,
            walletAddress: true,
            reputation: true,
            latitude: true,
            longitude: true,
          },
        },
      },
    });

    if (!medicine) {
      throw new AppError("Medicine not found", 404);
    }

    res.status(200).json({
      status: "success",
      data: medicine,
    });
  } catch (error) {
    next(error);
  }
};

// Get medicines by hospital
export const getMedicinesByHospital = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { hospitalId } = req.params;

    const medicines = await prisma.medicine.findMany({
      where: { hospitalId },
      include: {
        hospital: {
          select: {
            id: true,
            name: true,
            email: true,
            walletAddress: true,
            reputation: true,
            latitude: true,
            longitude: true,
          },
        },
      },
    });

    res.status(200).json({
      status: "success",
      results: medicines.length,
      data: medicines,
    });
  } catch (error) {
    next(error);
  }
};

// Create medicine
export const createMedicine = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { name, quantity, expiry, priority } = req.body;

    // Validate fields
    if (!name || !quantity || !expiry) {
      throw new AppError("Please provide all required fields", 400);
    }

    const medicine = await prisma.medicine.create({
      data: {
        name,
        quantity,
        expiry: new Date(expiry),
        priority: priority || false,
        hospitalId: req.user.id,
      },
    });

    res.status(201).json({
      status: "success",
      data: medicine,
    });
  } catch (error) {
    next(error);
  }
};

// Update medicine
export const updateMedicine = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { id } = req.params;
    const { name, quantity, expiry, priority } = req.body;

    // Validate fields
    if (!name && !quantity && !expiry && priority === undefined) {
      throw new AppError("Please provide at least one field to update", 400);
    }

    // Check if medicine exists
    const existingMedicine = await prisma.medicine.findUnique({
      where: { id },
    });

    if (!existingMedicine) {
      throw new AppError("Medicine not found", 404);
    }

    // Check if medicine belongs to user
    if (existingMedicine.hospitalId !== req.user.id) {
      throw new AppError("Not authorized to update this medicine", 403);
    }

    // Update medicine
    const medicine = await prisma.medicine.update({
      where: { id },
      data: {
        name: name || undefined,
        quantity: quantity !== undefined ? quantity : undefined,
        expiry: expiry ? new Date(expiry) : undefined,
        priority: priority !== undefined ? priority : undefined,
      },
    });

    res.status(200).json({
      status: "success",
      data: medicine,
    });
  } catch (error) {
    next(error);
  }
};

// Delete medicine
export const deleteMedicine = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { id } = req.params;

    // Check if medicine exists
    const existingMedicine = await prisma.medicine.findUnique({
      where: { id },
    });

    if (!existingMedicine) {
      throw new AppError("Medicine not found", 404);
    }

    // Check if medicine belongs to user
    if (existingMedicine.hospitalId !== req.user.id) {
      throw new AppError("Not authorized to delete this medicine", 403);
    }

    // Delete medicine
    await prisma.medicine.delete({
      where: { id },
    });

    res.status(204).json({
      status: "success",
      data: null,
    });
  } catch (error) {
    next(error);
  }
};

// Get low stock medicines
export const getLowStockMedicines = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { threshold } = req.params;
    const thresholdValue = parseInt(threshold);

    if (isNaN(thresholdValue)) {
      throw new AppError("Invalid threshold value", 400);
    }

    const medicines = await prisma.medicine.findMany({
      where: {
        hospitalId: req.user.id,
        quantity: {
          lte: thresholdValue,
        },
      },
      orderBy: {
        quantity: "asc",
      },
    });

    res.status(200).json({
      status: "success",
      results: medicines.length,
      data: medicines,
    });
  } catch (error) {
    next(error);
  }
};

// Get expiring soon medicines
export const getExpiringSoonMedicines = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { days } = req.params;
    const daysValue = parseInt(days);

    if (isNaN(daysValue)) {
      throw new AppError("Invalid days value", 400);
    }

    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + daysValue);

    const medicines = await prisma.medicine.findMany({
      where: {
        hospitalId: req.user.id,
        expiry: {
          lte: futureDate,
        },
      },
      orderBy: {
        expiry: "asc",
      },
    });

    res.status(200).json({
      status: "success",
      results: medicines.length,
      data: medicines,
    });
  } catch (error) {
    next(error);
  }
};
