import { expect } from "chai";
import hre from "hardhat";
import { time } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("HypeNFTV2 Contract", function () {
  let hypeNFTV2: any;
  let hypeCoin: any;
  let owner: any, otherAccount: any;
  let totalSupply = hre.ethers.parseUnits("1000000", 18);
  const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;

  beforeEach(async function () {
    hypeCoin = await hre.ethers.deployContract("HypeCoin", [totalSupply]);
    hypeNFTV2 = await hre.ethers.deployContract("HypeNFTV2", [hypeCoin.target]);
    [owner, otherAccount] = await hre.ethers.getSigners();
    // await hypeNFTV2.connect(otherAccount).mint(amount, { value: totalCost });
    await hypeCoin
      .connect(otherAccount)
      .buy(10n ** 19n, { value: hre.ethers.parseEther("0.1") });

    await hypeCoin.transfer(hypeNFTV2.target, 10n ** 23n); //send 100000 HypeCoin from owner to contract for rewards...
  });

  it("mint 2 HypeNFT with 10 HypeCoin and after 30 days, collect rewards.", async function () {
    const collectTime = (await time.latest()) + ONE_MONTH_IN_SECS + 1;

    await hypeCoin.connect(otherAccount).approve(hypeNFTV2.target, 10n ** 19n);
    expect(
      await hypeCoin.allowance(otherAccount.address, hypeNFTV2.target)
    ).to.equal(10n ** 19n);
    await hypeNFTV2.connect(otherAccount).mintWithHypeCoin(10n ** 19n);
    const tokenCount = await hypeNFTV2.balanceOf(otherAccount.address);
    expect(tokenCount).to.equal(2);

    await time.increaseTo(collectTime);
    const beforeBalance = await hypeCoin.balanceOf(otherAccount.address);
    expect(beforeBalance).to.equal(0);
    await hypeNFTV2.connect(otherAccount).collect();
    const afterBalance = await hypeCoin.balanceOf(otherAccount.address);
    expect(afterBalance).to.equal(60n * 10n ** 18n); //after 30 days, user can earn 60 coins as rewards from 2 NFT.
  });
});
