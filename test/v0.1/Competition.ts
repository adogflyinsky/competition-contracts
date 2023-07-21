
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("CompetitionV1", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {

    const [owner, acc1, acc2, acc3] = await ethers.getSigners();
    const CustomMath = await ethers.getContractFactory("CustomMath");
    const customMath = await CustomMath.deploy();
    const QuestionSet = await ethers.getContractFactory("QuestionSetV1", {
        libraries: {
            CustomMath: customMath.address,
        }
    });
    const questionSet = await QuestionSet.deploy();
    const VToken = await ethers.getContractFactory("VToken");
    const vToken = await VToken.deploy();
    const Prize = await ethers.getContractFactory("Prize");
    const prize = await Prize.deploy(vToken.address);
    const CompetitionToken = await ethers.getContractFactory("CompetitionToken");
    const competitionToken = await CompetitionToken.deploy("https://old.chesstempo.com/chess-problems/");
   
    const CompetitionV1 = await ethers.getContractFactory("CompetitionV1");
    const competitionV1 = await CompetitionV1.deploy(competitionToken.address, prize.address, questionSet.address);

    return { prize, competitionToken, competitionV1, vToken, owner, acc1, acc2, acc3};
  }

  describe("Happy path", function () {
    it("Get correct participants", async function () {
      const { prize, competitionToken, competitionV1, vToken, owner, acc1, acc2, acc3} = await loadFixture(deployOneYearLockFixture);
      await vToken.approve(prize.address, 20000);
      await prize.mintTo(competitionV1.address, 1, 10000, [40, 40, 20]);
      // fund prize
      await prize.fund(1, 10000);
      // mint 
      await competitionToken.mintTo(owner.address);
      // create 
      await competitionToken.connect(owner).approve(competitionV1.address, 1);
      await competitionV1.connect(owner).create(1, 1);
      expect((await competitionV1.getParticipants(1)).length).equal(0);
      await competitionV1.connect(owner).start(1, [acc1.address, acc2.address, acc3.address], 100);
      expect(await competitionV1.getParticipants(1)).to.have.all.members([acc1.address, acc2.address, acc3.address]);


    })
    it("Success flow of competition", async function () {
        const { prize, competitionToken, competitionV1, vToken, owner, acc1, acc2, acc3} = await loadFixture(deployOneYearLockFixture);
        const result = "Happy path"
        // mint prize
        await vToken.approve(prize.address, 20000);
        await prize.mintTo(competitionV1.address, 1, 10000, [40, 40, 20]);
        // fund prize
        await prize.fund(1, 10000);
        // mint 
        await competitionToken.mintTo(owner.address);
        // create 
        await competitionToken.connect(owner).approve(competitionV1.address, 1);
        await competitionV1.connect(owner).create(1, 1);
        // remove
        await competitionV1.connect(owner).remove(1);
        // create
        await competitionToken.connect(owner).approve(competitionV1.address, 1);
        await competitionV1.connect(owner).create(1, 1);
        // start
        await competitionV1.connect(owner).start(1, [acc1.address, acc2.address, acc3.address], 100);
        // fillData
        await time.increase(100);
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
        // check balances
        expect(await vToken.balanceOf(acc2.address)).equal(20000 * 40 / 100);
        expect(await vToken.balanceOf(acc1.address)).equal(20000 * 40 / 100);
        expect(await vToken.balanceOf(acc3.address)).equal(20000 * 20 / 100);
    })

    it("Demo", async function () {
      const { prize, competitionToken, competitionV1, vToken, owner, acc1 } = await loadFixture(deployOneYearLockFixture);
      const result = "Happy path"
      // mint prize
      await vToken.approve(prize.address, 20000);
      await prize.mintTo(competitionV1.address, 1, 10000, [50, 50]);
      // fund prize
      await prize.fund(1, 10000);
      // mint 
      await competitionToken.mintTo(owner.address);
      // create 
      await competitionToken.approve(competitionV1.address, 1);
      await competitionV1.create(1, 1);
      // start
      await competitionV1.connect(acc1).join(1);
      // check partiticipants
      expect(await competitionV1.getParticipants(1)).to.have.all.members([acc1.address]);
      // fillData
      await time.increase(100);
      const proof = await competitionV1.connect(acc1.address).getProof(1, result);
      await competitionV1.connect(acc1).fillData(1, proof);
      // fillResult
      await competitionV1.fillResult(1, result);
      // finish
      await competitionV1.finish(1);
      // check balance
      expect(await vToken.balanceOf(acc1.address)).equal(20000 * 50 / 100);
    })
  })
  
});
