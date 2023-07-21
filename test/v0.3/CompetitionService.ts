
import { time, loadFixture, reset } from "@nomicfoundation/hardhat-network-helpers";
import { expect, util } from "chai";
import { ethers } from "hardhat";

describe("CompetitionServiceV3", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {

    const [owner, acc1, acc2, acc3] = await ethers.getSigners();

    const ProofSet = await ethers.getContractFactory("ChessProofSet");
    const proofSet = await ProofSet.deploy();

    const CompetitionData = await ethers.getContractFactory("CompetitionData");
    const competitionData = await CompetitionData.deploy();

    const CompetitionService = await ethers.getContractFactory("CompetitionService");
    const competitionService = await CompetitionService.deploy(proofSet.address, competitionData.address);

    return { competitionData, competitionService, owner, acc1, acc2, acc3 };
  }

  describe("Happy path", function () {

    it("Get winners", async function () {
        const { competitionData, competitionService, owner, acc1, acc2, acc3 } = await loadFixture(deployFixture);
        const result = 1000;
        await competitionService.register(owner.address);
        await competitionService.assignParticipants(1, [acc1.address, acc2.address, acc3.address]);

        const indexAndProof1 = await competitionService.connect(acc1).getIndexAndProof(1, result);
        const data1 = await competitionData.getData(await competitionService.getCompetitionHash(1), indexAndProof1[0], indexAndProof1[1]);
        const hash_data1 = ethers.utils.keccak256(data1)
        const s1 = acc1.signMessage(ethers.utils.arrayify(hash_data1));
        const tx1 = await competitionData.getTx(await competitionService.getCompetitionHash(1), indexAndProof1[0], indexAndProof1[1], s1);

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
        const winners = await competitionService.getWinners(1);
        console.log(`winners: `, winners);
        // console.log(await competitionService.getProofs(1));
    })
    

    it.skip("Report changed data", async function () {
      const { competitionData, competitionService, owner, acc1, acc2, acc3 } = await loadFixture(deployFixture);
      const result = 1000;
      await competitionService.register(owner.address);
      await competitionService.assignParticipants(1, [acc1.address, acc2.address, acc3.address]);

      const indexAndProof1 = await competitionService.connect(acc1).getIndexAndProof(1, result);
      const data1 = await competitionData.getData(await competitionService.getCompetitionHash(1), indexAndProof1[0], indexAndProof1[1]);
      const hash_data1 = ethers.utils.keccak256(data1)
      const s1 = acc1.signMessage(ethers.utils.arrayify(hash_data1));
      const tx1 = await competitionData.getTx(await competitionService.getCompetitionHash(1), indexAndProof1[0], indexAndProof1[1], s1);
      const m1 = await competitionData.getMessage(indexAndProof1[0], indexAndProof1[1]);

      const indexAndProof2 = await competitionService.connect(acc2).getIndexAndProof(1, 1);
      const data2 = await competitionData.getData(hash_data1, 2, indexAndProof2[1]);
      const hash_data2 = ethers.utils.keccak256(data2)
      const s2 = acc2.signMessage(ethers.utils.arrayify(hash_data2));
      const tx2 = await competitionData.getTx(hash_data1, 2, indexAndProof2[1], s2);
      const m2 = await competitionData.getMessage(indexAndProof2[0], indexAndProof2[1]);

      const _indexAndProof3 = await competitionService.connect(acc3).getIndexAndProof(1, 200);
      const _data3 = await competitionData.getData(hash_data2, 3, _indexAndProof3[1]);
      const _hash_data3 = ethers.utils.keccak256(_data3)
      const _s3 = acc3.signMessage(ethers.utils.arrayify(_hash_data3));
      const _tx3 = await competitionData.getTx(hash_data2, 3, _indexAndProof3[1], _s3);
      const m3 = await competitionData.getMessage(_indexAndProof3[0], _indexAndProof3[1]);
      const confirmation = owner.signMessage(ethers.utils.arrayify(_hash_data3));

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
      await competitionService.report(1, [m1, m2, m3], confirmation);
      expect(await competitionService.inCompetition(1)).equal(false);
    })

    it.skip("Report order", async function () {
      const { competitionData, competitionService, owner, acc1, acc2, acc3 } = await loadFixture(deployFixture);
      const result = 1000;
      await competitionService.register(owner.address);
      await competitionService.assignParticipants(1, [acc1.address, acc2.address, acc3.address]);

      const indexAndProof1 = await competitionService.connect(acc1).getIndexAndProof(1, result);
      const data1 = await competitionData.getData(await competitionService.getCompetitionHash(1), indexAndProof1[0], indexAndProof1[1]);
      const hash_data1 = ethers.utils.keccak256(data1)
      const s1 = acc1.signMessage(ethers.utils.arrayify(hash_data1));
      const tx1 = await competitionData.getTx(await competitionService.getCompetitionHash(1), indexAndProof1[0], indexAndProof1[1], s1);
      const m1 = await competitionData.getMessage(indexAndProof1[0], indexAndProof1[1]);

      const indexAndProof2 = await competitionService.connect(acc2).getIndexAndProof(1, 1);
      const data2 = await competitionData.getData(hash_data1, 2, indexAndProof2[1]);
      const hash_data2 = ethers.utils.keccak256(data2)
      const s2 = acc2.signMessage(ethers.utils.arrayify(hash_data2));
      const tx2 = await competitionData.getTx(hash_data1, 2, indexAndProof2[1], s2);
      const m2 = await competitionData.getMessage(indexAndProof2[0], indexAndProof2[1]);


      const indexAndProof3 = await competitionService.connect(acc3).getIndexAndProof(1, result);
      const data3 = await competitionData.getData(hash_data1, 3, indexAndProof3[1]);
      const hash_data3 = ethers.utils.keccak256(data3)
      const s3 = acc3.signMessage(ethers.utils.arrayify(hash_data3));
      const tx3 = await competitionData.getTx(hash_data1, 3, indexAndProof3[1], s3);
      const m3 = await competitionData.getMessage(indexAndProof3[0], indexAndProof3[1]);
      const confirmation = owner.signMessage(ethers.utils.arrayify(hash_data3));

      const data = await competitionData.getData(hash_data2, 0, result);
      const hash_data = ethers.utils.keccak256(data)
      const s_owner = owner.signMessage(ethers.utils.arrayify(hash_data));
      const tx_final = await competitionData.getTx(hash_data2, 0, result, s_owner);

      await competitionService.fill(1, [tx1, tx2, tx_final]);
      await competitionService.report(1, [m1, m3], confirmation);
      expect(await competitionService.inCompetition(1)).equal(false);
    })
  })
});
