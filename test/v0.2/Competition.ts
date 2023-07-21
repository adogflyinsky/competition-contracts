
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("competitionV1", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {

    const [owner, acc1, acc2, acc3] = await ethers.getSigners();
    const CustomMath = await ethers.getContractFactory("CustomMath");
    const customMath = await CustomMath.deploy();
    const QuestionSet = await ethers.getContractFactory("QuestionSet", {
      libraries: {
        CustomMath: customMath.address,
      }
    });
    const questionSet = await QuestionSet.deploy();
    const VToken = await ethers.getContractFactory("VToken");
    const vToken = await VToken.deploy();

    const CompetitionToken = await ethers.getContractFactory("CompetitionToken");
    const competitionToken = await CompetitionToken.deploy("https://old.chesstempo.com/chess-problems/");

    const CompetitionV1 = await ethers.getContractFactory("CompetitionV1");
    const competitionV1 = await CompetitionV1.deploy(
      questionSet.address,
      competitionToken.address,
      vToken.address,
      // rrCoordinator.address
    );

    return { competitionToken, competitionV1, vToken, owner, acc1, acc2, acc3 };
  }

  describe("Happy path", function () {
    it("Get correct participants", async function () {
      const { competitionToken, competitionV1, vToken, owner, acc1, acc2, acc3 } = await loadFixture(deployFixture);
      const prizeAmount = 100000;
      await competitionToken.mintTo(owner.address);
      await competitionToken.approve(competitionV1.address, 1);
      await vToken.approve(competitionV1.address, prizeAmount);
      await competitionV1.create(1, prizeAmount, 100);
      await competitionV1.start(1, [50, 25, 25], [acc1.address, acc2.address, acc3.address]);
      expect(await competitionV1.getParticipants(1)).to.have.all.members([acc1.address, acc2.address, acc3.address]);

    })
    it("Success flow", async function () {
      const {  competitionToken, competitionV1, vToken, owner, acc1, acc2, acc3 } = await loadFixture(deployFixture);
      const prizeAmount = 100000;
      const result = "anything"
      // mint competition token
      await competitionToken.mintTo(owner.address);
      // create
      await competitionToken.approve(competitionV1.address, 1);
      await vToken.approve(competitionV1.address, prizeAmount);
      await competitionV1.create(1, prizeAmount, 100);
      // remove
      await time.increase(100);
      await competitionV1.remove(1);
      // create
      await competitionToken.approve(competitionV1.address, 1);
      await vToken.approve(competitionV1.address, prizeAmount);
      await competitionV1.create(1, prizeAmount, 100);
      // start
      await competitionV1.start(1, [50, 25, 25], [acc1.address, acc2.address, acc3.address]);
      // fillData
      const proof1 = await competitionV1.connect(acc2.address).getProof(1, result);
      await competitionV1.connect(acc2).fillData(1, proof1);
      const proof2 = await competitionV1.connect(acc1.address).getProof(1, result);
      await competitionV1.connect(acc1).fillData(1, proof2);
      const proof3 = await competitionV1.connect(acc3.address).getProof(1, result);
      await competitionV1.connect(acc3).fillData(1, proof3);
      // fillResult
      await competitionV1.fillResult(1, result);
      // finish
      await competitionV1.finish(1);
      // check refund
      expect(await competitionToken.ownerOf(1)).equal(owner.address);
      // check balances
      expect(await vToken.balanceOf(acc2.address)).equal(prizeAmount * 50 / 100);
      expect(await vToken.balanceOf(acc1.address)).equal(prizeAmount * 25 / 100);
      expect(await vToken.balanceOf(acc3.address)).equal(prizeAmount * 25 / 100);
      console.log(await vToken.balanceOf(owner.address));
    })
  })

});
