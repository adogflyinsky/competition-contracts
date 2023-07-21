
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Prize", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [deployer, acc1, acc2, acc3] = await ethers.getSigners();
    const VToken = await ethers.getContractFactory("VToken");
    const vToken = await VToken.deploy();
    const Prize = await ethers.getContractFactory("Prize");
    const prize = await Prize.deploy(vToken.address);

    return { prize, deployer, vToken, acc1, acc2 , acc3};
  }

  describe("Happy path", function () {
    it("mint + fund + active function", async function () {
        // mint
        const { prize, deployer, vToken, acc1, acc2, acc3 } = await loadFixture(deployFixture);
        const init_deployer_balance = await vToken.balanceOf(deployer.address);
        await vToken.approve(prize.address, 50000);
        await prize.mintTo(deployer.address, 1, 10000, [40, 40, 20]);
        await prize.mintTo(deployer.address, 2, 20000, [50, 30, 20]);

        // fund
        await prize.fund(1, 10000);
        await prize.fund(2, 10000);

        // active
        await prize.active(1, 1, [acc1.address, acc2.address, acc3.address]); // spend all: no refund to deployer
        expect(await vToken.balanceOf(acc2.address)).equal(20000 * 40 / 100);
        expect((await vToken.balanceOf(deployer.address)).toBigInt() + 50000n).equal(init_deployer_balance.toBigInt());
        await prize.active(2, 2, [acc1.address, acc2.address]); // spend for 2/3 accounts: refund `30000 * 20 / 100 = 6000` to deployer
        expect(await vToken.balanceOf(acc2.address)).equal(20000 * 40 / 100 + 30000 * 30 / 100);
        expect((await vToken.balanceOf(deployer.address)).toBigInt() + 44000n).equal(init_deployer_balance.toBigInt());
    })
  })
  
});
