import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const HypeNFTModule = buildModule("HypeNFTModule", (m) => {
  const nft = m.contract("HypeNFT", []);
  return { nft };
});

export default HypeNFTModule;
