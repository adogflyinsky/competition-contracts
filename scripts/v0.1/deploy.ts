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

    const VToken = await ethers.getContractFactory("VToken");
    const vToken = await VToken.deploy();
    Config.setConfig(network + '.vToken', vToken.address);

    const Prize = await ethers.getContractFactory("Prize");
    const prize = await Prize.deploy(vToken.address);
    Config.setConfig(network + '.prize', prize.address);

    const CustomMath = await ethers.getContractFactory("CustomMath");
    const customMath = await CustomMath.deploy();
    Config.setConfig(network + '.customMath', customMath.address);

    const QuestionSet = await ethers.getContractFactory("QuestionSetV1",
        {
            libraries: {
                CustomMath: customMath.address,
            }
        });
    const questionSet = await QuestionSet.deploy();
    Config.setConfig(network + '.questionSet', questionSet.address);

    const CompetitionV1 = await ethers.getContractFactory("CompetitionV1");
    const competitionV1 = await CompetitionV1.deploy
        (
            competitionToken.address,
            prize.address,
            questionSet.address
        );
    Config.setConfig(network + '.competitionV1', competitionV1.address);

    await Config.updateConfig();

}

main().then(() => process.exit(0))
    .catch(err => {
        console.error(err);
        process.exit(1);
    });
