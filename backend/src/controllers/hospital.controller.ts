import { PrismaClient } from "@prisma/client";
import { NextFunction, Request, Response } from "express";
import { AppError } from "../middleware/error.middleware";

const prisma = new PrismaClient();

// Calculate distance between two coordinates using Haversine formula
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

// Get all hospitals
export const getAllHospitals = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const hospitals = await prisma.hospital.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        walletAddress: true,
        reputation: true,
        latitude: true,
        longitude: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    res.status(200).json({
      status: "success",
      results: hospitals.length,
      data: hospitals,
    });
  } catch (error) {
    next(error);
  }
};

// Get hospital by ID
export const getHospitalById = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { id } = req.params;

    const hospital = await prisma.hospital.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        walletAddress: true,
        reputation: true,
        latitude: true,
        longitude: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!hospital) {
      throw new AppError("Hospital not found", 404);
    }

    res.status(200).json({
      status: "success",
      data: hospital,
    });
  } catch (error) {
    next(error);
  }
};

// Get my profile
export const getMyProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const hospital = await prisma.hospital.findUnique({
      where: { id: req.user.id },
      include: {
        medicines: true,
      },
    });

    if (!hospital) {
      throw new AppError("Hospital not found", 404);
    }

    // Remove password from response
    const { password, ...hospitalData } = hospital;

    res.status(200).json({
      status: "success",
      data: hospitalData,
    });
  } catch (error) {
    next(error);
  }
};

// Update my profile
export const updateMyProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    const { name, email, latitude, longitude } = req.body;

    // Validate fields
    if (!name && !email && !latitude && !longitude) {
      throw new AppError("Please provide at least one field to update", 400);
    }

    // Check if email already exists
    if (email) {
      const existingHospital = await prisma.hospital.findUnique({
        where: { email },
      });

      if (existingHospital && existingHospital.id !== req.user.id) {
        throw new AppError("Email already in use", 400);
      }
    }

    // Update hospital
    const updatedHospital = await prisma.hospital.update({
      where: { id: req.user.id },
      data: {
        name: name || undefined,
        email: email || undefined,
        latitude: latitude || undefined,
        longitude: longitude || undefined,
      },
      select: {
        id: true,
        name: true,
        email: true,
        walletAddress: true,
        reputation: true,
        latitude: true,
        longitude: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    res.status(200).json({
      status: "success",
      data: updatedHospital,
    });
  } catch (error) {
    next(error);
  }
};

// Get nearby hospitals
export const getNearbyHospitals = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { latitude, longitude, distance } = req.params;

    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);
    const maxDistance = parseFloat(distance);

    if (isNaN(lat) || isNaN(lon) || isNaN(maxDistance)) {
      throw new AppError("Invalid coordinates or distance", 400);
    }

    // Get all hospitals
    const allHospitals = await prisma.hospital.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        walletAddress: true,
        reputation: true,
        latitude: true,
        longitude: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    // Filter hospitals by distance
    const nearbyHospitals = allHospitals.filter((hospital) => {
      const distanceToHospital = calculateDistance(
        lat,
        lon,
        hospital.latitude!,
        hospital.longitude!
      );
      return distanceToHospital <= maxDistance;
    });

    // Sort by distance
    nearbyHospitals.sort((a, b) => {
      const distanceA = calculateDistance(lat, lon, a.latitude! , a.longitude!);
      const distanceB = calculateDistance(lat, lon, b.latitude!, b.longitude!);
      return distanceA - distanceB;
    });

    // Add distance to each hospital
    const hospitalsWithDistance = nearbyHospitals.map((hospital) => {
      const distance = calculateDistance(
        lat,
        lon,
        hospital.latitude!,
        hospital.longitude!
      );
      return {
        ...hospital,
        distance: parseFloat(distance.toFixed(2)),
      };
    });

    res.status(200).json({
      status: "success",
      results: hospitalsWithDistance.length,
      data: hospitalsWithDistance,
    });
  } catch (error) {
    next(error);
  }
};
