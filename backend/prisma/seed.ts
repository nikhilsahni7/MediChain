import { PrismaClient } from "@prisma/client";
import * as bcrypt from "bcrypt";

const prisma = new PrismaClient();

async function main() {
  // Delete existing records to avoid duplicates
  await prisma.medicine.deleteMany({});
  await prisma.hospital.deleteMany({});
  await prisma.order.deleteMany({});

  // Predefined hospitals with wallet addresses
  const hospitals = [
    {
      name: "Apollo Hospital Delhi",
      email: "apollo.delhi@medileger.com",
      password: await bcrypt.hash("apollo123", 10),
      walletAddress: "0x1234567890123456789012345678901234567890",
      latitude: 28.5621,
      longitude: 77.2841,
    },
    {
      name: "Fortis Hospital Noida",
      email: "fortis.noida@medileger.com",
      password: await bcrypt.hash("fortis123", 10),
      walletAddress: "0x2345678901234567890123456789012345678901",
      latitude: 28.5355,
      longitude: 77.391,
    },
    {
      name: "Max Super Speciality Hospital Saket",
      email: "max.saket@medileger.com",
      password: await bcrypt.hash("max123", 10),
      walletAddress: "0x3456789012345678901234567890123456789012",
      latitude: 28.528,
      longitude: 77.211,
    },
    {
      name: "Medanta The Medicity Gurugram",
      email: "medanta.gurugram@medileger.com",
      password: await bcrypt.hash("medanta123", 10),
      walletAddress: "0x4567890123456789012345678901234567890123",
      latitude: 28.4391,
      longitude: 77.0405,
    },
    {
      name: "Asian Hospital Faridabad",
      email: "asian.faridabad@medileger.com",
      password: await bcrypt.hash("asian123", 10),
      walletAddress: "0x5678901234567890123456789012345678901234",
      latitude: 28.3808,
      longitude: 77.2937,
    },
    {
      name: "Indraprastha Apollo Hospital New Delhi",
      email: "ip.apollo@medileger.com",
      password: await bcrypt.hash("ipapollo123", 10),
      walletAddress: "0x6789012345678901234567890123456789012345",
      latitude: 28.5679,
      longitude: 77.2831,
    },
    {
      name: "Artemis Hospital Gurugram",
      email: "artemis.gurugram@medileger.com",
      password: await bcrypt.hash("artemis123", 10),
      walletAddress: "0x7890123456789012345678901234567890123456",
      latitude: 28.4595,
      longitude: 77.0266,
    },
    {
      name: "Jaypee Hospital Noida",
      email: "jaypee.noida@medileger.com",
      password: await bcrypt.hash("jaypee123", 10),
      walletAddress: "0x8901234567890123456789012345678901234567",
      latitude: 28.5801,
      longitude: 77.3244,
    },
    {
      name: "Metro Hospital Noida",
      email: "metro.noida@medileger.com",
      password: await bcrypt.hash("metro123", 10),
      walletAddress: "0x9012345678901234567890123456789012345678",
      latitude: 28.5728,
      longitude: 77.3615,
    },
    {
      name: "Sarvodaya Hospital Faridabad",
      email: "sarvodaya.faridabad@medileger.com",
      password: await bcrypt.hash("sarvodaya123", 10),
      walletAddress: "0xa123456789012345678901234567890123456789",
      latitude: 28.4089,
      longitude: 77.3178,
    },
  ];

  // Create hospitals
  for (const hospital of hospitals) {
    const createdHospital = await prisma.hospital.create({
      data: hospital,
    });

    console.log(`Created hospital: ${createdHospital.name}`);

    // Add sample medicines for each hospital
    const medicines = [
      {
        name: "Paracetamol",
        quantity: Math.floor(Math.random() * 100) + 50,
        expiry: new Date(
          Date.now() +
            (Math.floor(Math.random() * 365) + 30) * 24 * 60 * 60 * 1000
        ),
        priority: Math.random() > 0.7,
        hospitalId: createdHospital.id,
      },
      {
        name: "Ibuprofen",
        quantity: Math.floor(Math.random() * 100) + 30,
        expiry: new Date(
          Date.now() +
            (Math.floor(Math.random() * 365) + 30) * 24 * 60 * 60 * 1000
        ),
        priority: Math.random() > 0.7,
        hospitalId: createdHospital.id,
      },
      {
        name: "Amoxicillin",
        quantity: Math.floor(Math.random() * 50) + 20,
        expiry: new Date(
          Date.now() +
            (Math.floor(Math.random() * 365) + 30) * 24 * 60 * 60 * 1000
        ),
        priority: Math.random() > 0.5,
        hospitalId: createdHospital.id,
      },
      {
        name: "Loratadine",
        quantity: Math.floor(Math.random() * 70) + 40,
        expiry: new Date(
          Date.now() +
            (Math.floor(Math.random() * 365) + 30) * 24 * 60 * 60 * 1000
        ),
        priority: Math.random() > 0.8,
        hospitalId: createdHospital.id,
      },
      {
        name: "Insulin",
        quantity: Math.floor(Math.random() * 30) + 10,
        expiry: new Date(
          Date.now() +
            (Math.floor(Math.random() * 180) + 30) * 24 * 60 * 60 * 1000
        ),
        priority: true,
        hospitalId: createdHospital.id,
      },
    ];

    for (const medicine of medicines) {
      await prisma.medicine.create({
        data: medicine,
      });
    }

    console.log(`Added medicines to hospital: ${createdHospital.name}`);
  }

  console.log("Seeding completed successfully");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
