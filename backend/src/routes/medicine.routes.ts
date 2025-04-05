import express from "express";
import * as medicineController from "../controllers/medicine.controller";
import { authenticate } from "../middleware/auth.middleware";

const router = express.Router();

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

// Dynamic ID routes must be at the end to avoid capturing other routes
// router.get("/:id", medicineController.getMedicineById);
// router.put("/:id", medicineController.updateMedicine);
router.delete("/:id", medicineController.deleteMedicine);

export default router;
