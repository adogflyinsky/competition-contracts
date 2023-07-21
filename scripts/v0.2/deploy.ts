import { ethers, hardhatArguments } from 'hardhat';
import * as Config from '../config';

async function main() {
    await Config.initConfig();
    const network = hardhatArguments.network ? hardhatArguments.network : 'dev';
    const [owner] = await ethers.getSigners();
    console.log('deploy from address: ', owner.address);

    const CompetitionToken = await ethers.getContractFactory("CompetitionToken");
    const competitionToken = await CompetitionToken.deploy("https://old.chesstempo.com/chess-problems/");
    Config.setConfig(network + '.competitionToken', competitionToken.address);
    console.log("competitionToken", competitionToken.address)

    const RRCoordinator = await ethers.getContractFactory("RequestResponseCoordinator");
    const rrCoordinator = await RRCoordinator.deploy();
    Config.setConfig(network + '.rrCoordinator', rrCoordinator.address);
    console.log("rrCoordinator", rrCoordinator.address)

    const CompetitionV2 = await ethers.getContractFactory("CompetitionV2");
    const competitionV2 = await CompetitionV2.deploy
        (   
            "0xae6f0De8B4867A15720551F40AD6c47e735b4768",
            competitionToken.address,
            "0xE531e3Fe18922A0C1389a7B6c13D5cdEaC734ADF",
            rrCoordinator.address
        );
    Config.setConfig(network + '.competitionV2', competitionV2.address);
    console.log("competitionV2", competitionV2.address)
    await Config.updateConfig();

}

main().then(() => process.exit(0))
    .catch(err => {
        console.error(err);
        process.exit(1);
    });
