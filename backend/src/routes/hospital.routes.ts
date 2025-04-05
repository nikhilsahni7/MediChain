import express from "express";
import * as hospitalController from "../controllers/hospital.controller";
import { authenticate } from "../middleware/auth.middleware";

const router = express.Router();

// Public routes
router.get("/", hospitalController.getAllHospitals);
router.get("/:id", hospitalController.getHospitalById);

// Protected routes
router.use(authenticate);
router.get("/me/profile", hospitalController.getMyProfile);
router.put("/me/profile", hospitalController.updateMyProfile);
router.get(
  "/nearby/:latitude/:longitude/:distance",
  hospitalController.getNearbyHospitals
);

export default router;
