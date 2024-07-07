import { expect } from "chai";
import hre from "hardhat";

describe("HypeNFT Contract", function () {
  let hypeNFT: any;
  let owner: any, otherAccount: any;
  const mintPrice = hre.ethers.parseEther("0.1");

  beforeEach(async function () {
    hypeNFT = await hre.ethers.deployContract("HypeNFT");
    [owner, otherAccount] = await hre.ethers.getSigners();
  });

  it("should inialize the contract", async function () {
    expect(await hypeNFT.nextTokenId()).to.equal(1);
  });

  it("should mint 5 tokens for the caller, with tokenIds from 1 to 5", async function () {
    const amount = 5n;
    const totalCost = mintPrice * amount;

    await hypeNFT.connect(otherAccount).mint(amount, { value: totalCost });

    for (let i = 1; i <= amount; i++) {
      expect(await hypeNFT.ownerOf(i)).to.equal(otherAccount.address);
    }
    expect(await hypeNFT.nextTokenId()).to.equal(6);
    const tokens = await hypeNFT.tokensOwnedByAddr(otherAccount.address);
    await expect(tokens[3]).to.equal(4);
  });

  it("funds the contract owner's wallet with ETH on successful mints", async function () {
    const amount = 5n;
    const totalCost = mintPrice * amount;
    expect(
      await hypeNFT.connect(otherAccount).mint(amount, { value: totalCost })
    ).to.changeEtherBalance(owner, totalCost);
  });
});
