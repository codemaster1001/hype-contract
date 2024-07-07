import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * @notice Before deploying you have to set the correct HypeCoin address as a parameter in contructor function
 */
const HypeNFTV2Module = buildModule("HypeNFTV2Module", (m) => {
  const HypeCoinAddress = "0xE936844Dfe217f79A5F8f1E5D29f5c3AEb809116"; // This is a temparary address of deployed HypeCoin Address.
  const nftV2 = m.contract("HypeNFTV2", [HypeCoinAddress]);
  return { nftV2 };
});

export default HypeNFTV2Module;
