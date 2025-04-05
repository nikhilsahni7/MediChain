// much cleaner than vanilla scripts/deploy.js 
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MediChainModule = buildModule("MediChainModule", (m) => {
  const mediChain = m.contract("MediChain");

  return { mediChain };
});

export default MediChainModule;
