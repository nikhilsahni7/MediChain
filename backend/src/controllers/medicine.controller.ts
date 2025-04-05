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

// Search for medicines by name with nearby hospitals
export const searchMedicinesByName = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { name, quantity, maxDistance = 50 } = req.body; // maxDistance in kilometers

    // Validate fields
    if (!name || !quantity) {
      throw new AppError("Please provide medicine name and quantity", 400);
    }

    // Get current hospital location
    const currentHospital = await prisma.hospital.findUnique({
      where: { id: req.user.id },
      select: { latitude: true, longitude: true },
    });

    if (
      !currentHospital ||
      !currentHospital.latitude ||
      !currentHospital.longitude
    ) {
      throw new AppError("Hospital location not available", 400);
    }

    // Get all medicines with matching name and sufficient quantity
    const medicines = await prisma.medicine.findMany({
      where: {
        name: {
          contains: name,
          mode: "insensitive", // Case-insensitive search
        },
        quantity: {
          gte: quantity,
        },
      },
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

    // Calculate distance and filter nearby hospitals
    const nearbyMedicines = medicines
      .map((medicine) => {
        // Skip if hospital doesn't have location data
        if (!medicine.hospital.latitude || !medicine.hospital.longitude) {
          return null;
        }

        // Calculate distance using Haversine formula
        const distance = calculateDistance(
          currentHospital.latitude!,
          currentHospital.longitude!,
          medicine.hospital.latitude!,
          medicine.hospital.longitude!
        );

        return {
          ...medicine,
          distance: Math.round(distance * 10) / 10, // Round to 1 decimal place
          paymentOptions: {
            crypto: !!medicine.hospital.walletAddress,
            razorpay: true,
          },
        };
      })
      .filter(
        (medicine) => medicine !== null && medicine.distance <= maxDistance
      )
      .sort((a, b) => a!.distance - b!.distance);

    res.status(200).json({
      status: "success",
      results: nearbyMedicines.length,
      data: nearbyMedicines,
    });
  } catch (error) {
    next(error);
  }
};

// Helper function to calculate distance between two coordinates using Haversine formula
const calculateDistance = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number => {
  const R = 6371; // Radius of the Earth in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in km
  return distance;
};
