import express from "express";
import * as medicineController from "../controllers/medicine.controller";
import { authenticate } from "../middleware/auth.middleware";

const router = express.Router();

// Public routes
router.get("/", medicineController.getAllMedicines);
router.get("/:id", medicineController.getMedicineById);
router.get("/hospital/:hospitalId", medicineController.getMedicinesByHospital);

// Protected routes
router.use(authenticate);
router.post("/", medicineController.createMedicine);
router.put("/:id", medicineController.updateMedicine);
router.delete("/:id", medicineController.deleteMedicine);
router.get("/low-stock/:threshold", medicineController.getLowStockMedicines);
router.get("/expiring-soon/:days", medicineController.getExpiringSoonMedicines);

export default router;
