// much cleaner than vanilla scripts/deploy.js
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MedilegerModule = buildModule("MedilegerModule", (m) => {
  const mediChain = m.contract("Medileger");

  return { mediChain };
});

export default MedilegerModule;
