-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "paymentMethod" TEXT,
ADD COLUMN     "paymentStatus" TEXT,
ADD COLUMN     "razorpayOrderId" TEXT,
ADD COLUMN     "razorpayPaymentId" TEXT;
