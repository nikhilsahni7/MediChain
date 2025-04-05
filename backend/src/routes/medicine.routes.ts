import express from "express";
import multer from "multer";
import * as medicineController from "../controllers/medicine.controller";
import { authenticate } from "../middleware/auth.middleware";

const router = express.Router();

// Configure multer for in-memory storage with error handling
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10 MB limit
  },
}).single("medicineImage"); // Moved the single() call here to avoid field name errors

// Custom middleware to handle multer errors
const handleMulterUpload = (
  req: express.Request,
  res: express.Response,
  next: express.NextFunction
) => {
  upload(req, res, (err) => {
    if (err) {
      console.error("Multer error:", err);

      if (err instanceof multer.MulterError) {
        // A Multer error occurred when uploading
        if (err.code === "LIMIT_FILE_SIZE") {
          return res.status(400).json({
            status: "error",
            message: "File size too large. Maximum size is 10MB.",
          });
        }
        if (err.code === "LIMIT_UNEXPECTED_FILE") {
          return res.status(400).json({
            status: "error",
            message: `Wrong field name. Use "medicineImage" instead of "${err.field}"`,
          });
        }
        return res.status(400).json({
          status: "error",
          message: `File upload error: ${err.message}`,
        });
      } else {
        // An unknown error occurred
        return res.status(500).json({
          status: "error",
          message: "Unknown file upload error",
        });
      }
    }

    // Everything went fine
    next();
  });
};

// Public routes
router.get("/", medicineController.getAllMedicines);
// Specific routes before dynamic routes
router.get("/hospital/:hospitalId", medicineController.getMedicinesByHospital);

// Protected routes
router.use(authenticate);
// Specific routes must come before dynamic routes
router.get("/low-stock/:threshold", medicineController.getLowStockMedicines);
router.get("/expiring-soon/:days", medicineController.getExpiringSoonMedicines);
router.post("/search", medicineController.searchMedicinesByName);
router.post("/", medicineController.createMedicine);
router.post(
  "/process-image",
  handleMulterUpload,
  medicineController.processMedicineImage
);

// Dynamic ID routes must be at the end to avoid capturing other routes
router.get("/:id", medicineController.getMedicineById);
router.put("/:id", medicineController.updateMedicine);
router.delete("/:id", medicineController.deleteMedicine);

export default router;
