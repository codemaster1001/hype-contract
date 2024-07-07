import { expect } from "chai";
import hre from "hardhat";

describe("HypeCoin", function () {
  let hypeCoin: any;
  let totalSupply = hre.ethers.parseUnits("1000000", 18);
  let owner: any, otherAccount: any;

  beforeEach(async function () {
    hypeCoin = await hre.ethers.deployContract("HypeCoin", [totalSupply]);
    [owner, otherAccount] = await hre.ethers.getSigners();
  });

  describe("Deployment", function () {
    it("Should set the total Supply to 1,000,000 with decimals 18", async function () {
      expect(await hypeCoin.totalSupply()).to.equal(totalSupply);
    });

    it("Balance of the owner should be 1,000,000 with decimals 18", async function () {
      expect(await hypeCoin.balanceOf(owner)).to.equal(totalSupply);
    });
  });

  describe("Buy", function () {
    const tokenAmount = 10n ** 20n;
    const requiredETH = 10n ** 18n;

    it("Should buy 100 token for 1ETH and refund the remaining ETH to buyer", async function () {
      await hypeCoin
        .connect(otherAccount)
        .buy(tokenAmount, { value: hre.ethers.parseEther("30.0") });
      expect(await hypeCoin.balanceOf(otherAccount)).to.equal(tokenAmount);
      expect(await hre.ethers.provider.getBalance(hypeCoin.target)).to.equal(
        requiredETH
      );
    });

    it("Should fail if the ETH is not enough", async function () {
      await expect(
        hypeCoin
          .connect(otherAccount)
          .buy(tokenAmount, { value: hre.ethers.parseEther("0.1") })
      ).to.be.reverted;
    });
  });

  describe("Claim", function () {
    it("Owner claims ETH", async function () {
      await hypeCoin
        .connect(otherAccount)
        .buy(10n ** 20n, { value: hre.ethers.parseEther("1.0") });
      const contractBalance = await hre.ethers.provider.getBalance(
        hypeCoin.target
      );

      await expect(hypeCoin.claim()).to.changeEtherBalances(
        [owner, hypeCoin],
        [contractBalance, -contractBalance]
      );
    });
    it("If user is not owner calls claim, it reverts with error", async function () {
      await hypeCoin
        .connect(otherAccount)
        .buy(10n ** 20n, { value: hre.ethers.parseEther("1.0") });
      await expect(hypeCoin.connect(otherAccount).claim()).to.be.reverted;
    });
  });
});
