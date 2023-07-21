
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("competitionV3", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {

    const [owner, acc1, acc2, acc3] = await ethers.getSigners();

    const VToken = await ethers.getContractFactory("VToken");
    const vToken = await VToken.deploy();

    const CompetitionToken = await ethers.getContractFactory("CompetitionToken");
    const competitionToken = await CompetitionToken.deploy("https://old.chesstempo.com/chess-problems/");

    const ProofSet = await ethers.getContractFactory("ChessProofSet");
    const proofSet = await ProofSet.deploy();

    const CompetitionData = await ethers.getContractFactory("CompetitionData");
    const competitionData = await CompetitionData.deploy();

    const CompetitionService = await ethers.getContractFactory("CompetitionService");
    const competitionService = await CompetitionService.deploy(proofSet.address, competitionData.address);

    const Competition = await ethers.getContractFactory("Competition");
    const competition = await Competition.deploy(
      competitionToken.address,
      vToken.address,
      competitionService.address
    );

    return { competitionData, competitionToken, competitionService, competition, vToken, owner, acc1, acc2, acc3 };
  }

  describe("Happy path", function () {
    it("Winners", async function () {
        const { competitionData, competitionToken, competitionService, competition, vToken, owner, acc1, acc2, acc3 } = await loadFixture(deployFixture);
        
        const prizeAmount = 100000;
        await competitionToken.mintTo(owner.address, 5);
        await competitionToken.approve(competition.address, 1);
        await vToken.approve(competition.address, prizeAmount);

        await competition.create(1, prizeAmount,[50, 25, 25]);
        await competition.setParticipants(1, [acc1.address, acc2.address, acc3.address]);

        const result = 1000;
        const indexAndProof1 = await competitionService.connect(acc1).getIndexAndProof(1, result);
        const data1 = await competitionData.getData(await competitionService.getCompetitionHash(1), indexAndProof1[0], indexAndProof1[1]);
        const hash_data1 = ethers.utils.keccak256(data1)
        const s1 = acc1.signMessage(ethers.utils.arrayify(hash_data1));
        const tx1 = await competitionData.getTx(await competitionService.getCompetitionHash(1), indexAndProof1[0], indexAndProof1[1], s1);

        // Wrong answer
        const indexAndProof2 = await competitionService.connect(acc2).getIndexAndProof(1, 1);
        const data2 = await competitionData.getData(hash_data1, 2, indexAndProof2[1]);
        const hash_data2 = ethers.utils.keccak256(data2)
        const s2 = acc2.signMessage(ethers.utils.arrayify(hash_data2));
        const tx2 = await competitionData.getTx(hash_data1, 2, indexAndProof2[1], s2);

        const indexAndProof3 = await competitionService.connect(acc3).getIndexAndProof(1, result);
        const data3 = await competitionData.getData(hash_data2, 3, indexAndProof3[1]);
        const hash_data3 = ethers.utils.keccak256(data3)
        const s3 = acc3.signMessage(ethers.utils.arrayify(hash_data3));
        const tx3 = await competitionData.getTx(hash_data2, 3, indexAndProof3[1], s3);

        const data = await competitionData.getData(hash_data3, 0, result);
        const hash_data = ethers.utils.keccak256(data)
        const s_owner = owner.signMessage(ethers.utils.arrayify(hash_data));
        const tx_final = await competitionData.getTx(hash_data3, 0, result, s_owner);

        await competitionService.fill(1, [tx1, tx2, tx3, tx_final]);

        await competition.finish(1);

        expect(await vToken.balanceOf(acc1.address)).equal(prizeAmount * 50 / 100);
        expect(await vToken.balanceOf(acc2.address)).equal(prizeAmount * 0 / 100);
        expect(await vToken.balanceOf(acc3.address)).equal(prizeAmount * 25 / 100);



    })
   
  })

});
