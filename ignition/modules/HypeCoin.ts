import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const HypeCoinModule = buildModule("HypeCoinModule", (m) => {
  const totalSupply = m.getParameter("totalSupply", 1000000n * 10n ** 18n);
  const coin = m.contract("HypeCoin", [totalSupply]);
  return { coin };
});

export default HypeCoinModule;
