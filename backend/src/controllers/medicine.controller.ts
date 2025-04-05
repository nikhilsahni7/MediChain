import { GoogleGenerativeAI } from "@google/generative-ai";
import { PrismaClient } from "@prisma/client";
import { NextFunction, Request, Response } from "express";
import { AppError } from "../middleware/error.middleware";

const prisma = new PrismaClient();

// Initialize Gemini API with fallback for testing
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

// Check if API key is properly set
const isGeminiConfigured =
  GEMINI_API_KEY && GEMINI_API_KEY !== "YOUR_GEMINI_API_KEY";

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

// Process medicine image and add to database
export const processMedicineImage = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      throw new AppError("Not authenticated", 401);
    }

    // Check if file exists
    if (!req.file) {
      throw new AppError("Please provide a medicine image", 400);
    }

    // Check if API key is configured
    if (!isGeminiConfigured) {
      console.log("Gemini API key not configured. Using fallback method.");
      return createMedicineFromFallback(req, res);
    }

    try {
      // Get file buffer and convert to base64
      const base64Image = req.file.buffer.toString("base64");

      // Configure Gemini model
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

      // System prompt for medicine identification with simplified output
      const systemPrompt = `
      You are a pharmaceutical expert.
      Given an image of a tablet, capsule, or medicine strip, identify the medicine.

      Return ONLY a simple JSON object with this structure:
      {"brandName": "Medicine Name", "genericName": "Active Ingredient", "quantity": 10}

      Use a realistic brand name. Quantity must be a number.

      If you can't identify the medicine, return:
      {"error": "Cannot identify medicine"}
      `;

      // Generate content from Gemini
      const result = await model.generateContent([
        systemPrompt,
        {
          inlineData: {
            mimeType: "image/jpeg",
            data: base64Image,
          },
        },
      ]);

      // Extract response text and clean it
      let responseText = result.response.text().trim();
      console.log("Raw Gemini response:", responseText);

      // Clean any formatting from the response
      responseText = responseText
        .replace(/```json/g, "")
        .replace(/```/g, "")
        .trim();

      // Create a default medicine object in case parsing fails
      let medicineData = {
        brandName: "Unknown Medicine",
        genericName: "Unknown",
        quantity: 10,
      };

      // Try to parse JSON response, but use fallback if it fails
      try {
        const parsed = JSON.parse(responseText);
        medicineData = parsed;
      } catch (parseError) {
        console.error("JSON parsing error:", parseError);
        console.log("Using default medicine data");
      }

      // Default date for expiry (30 days from now)
      const defaultExpiry = new Date();
      defaultExpiry.setDate(defaultExpiry.getDate() + 30);

      // Create medicine with the data we have
      const medicine = await prisma.medicine.create({
        data: {
          name: `${medicineData.brandName}`,
          quantity: Number(medicineData.quantity) || 10,
          expiry: defaultExpiry,
          priority: false,
          hospitalId: req.user.id,
        },
      });

      return res.status(201).json({
        status: "success",
        data: {
          analysis: medicineData,
          createdMedicines: [medicine],
        },
      });
    } catch (geminiError) {
      console.error("Gemini API error:", geminiError);
      return createMedicineFromFallback(req, res);
    }
  } catch (error) {
    next(error);
  }
};

// Helper function for fallback medicine creation
const createMedicineFromFallback = async (req: Request, res: Response) => {
  // Extract filename from request file
  const filename = req.file?.originalname || "unknown";

  // Extract potential medicine name from filename
  const potentialName = filename
    .replace(/\.[^/.]+$/, "") // Remove file extension
    .replace(/_/g, " ") // Replace underscores with spaces
    .replace(/-/g, " "); // Replace dashes with spaces

  // Default medicine data based on file metadata
  const defaultMedicineData = {
    brandName: potentialName || "Sample Medicine",
    genericName: "Sample Generic",
    quantity: 10,
  };

  // Default date for expiry (30 days from now)
  const defaultExpiry = new Date();
  defaultExpiry.setDate(defaultExpiry.getDate() + 30);

  // Create medicine with default data
  const medicine = await prisma.medicine.create({
    data: {
      name: `${defaultMedicineData.brandName})`,
      quantity: defaultMedicineData.quantity,
      expiry: defaultExpiry,
      priority: false,
      hospitalId: req.user?.id || "", // Fallback should only be called when req.user exists
    },
  });

  return res.status(201).json({
    status: "success",
    data: {
      analysis: {
        ...defaultMedicineData,
        note: "Created with fallback system. Please update details manually.",
      },
      createdMedicines: [medicine],
    },
  });
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
        hospitalId: {
          not: req.user.id, // Exclude the requesting hospital's own medicines
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
      .filter(
        (medicine) =>
          medicine.hospital.latitude !== null &&
          medicine.hospital.longitude !== null
      )
      .map((medicine) => {
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
      .filter((medicine) => medicine.distance <= maxDistance)
      .sort((a, b) => a.distance - b.distance);

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
