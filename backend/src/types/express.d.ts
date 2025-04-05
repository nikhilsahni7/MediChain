import { Hospital } from "@prisma/client";

declare global {
  namespace Express {
    interface Request {
      user?: Hospital;
      file?: Express.Multer.File;
    }
  }
}

export {};
