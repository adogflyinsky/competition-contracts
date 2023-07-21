// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CompetitionBase.sol";
import "./interfaces/IQuestionSet.sol";

abstract contract CompetitionV0 is CompetitionBase {
    
    IQuestionSet public questions;
    IERC721 public competitionToken;
    IERC20 public prizeToken;

    mapping(uint256 => uint256) internal prizes;
    
    constructor(
        IQuestionSet _questions,
        IERC721 _competitionToken,
        IERC20 _prizeToken
        ) {
        questions = _questions;
        competitionToken = _competitionToken;
        prizeToken = _prizeToken;
    }   

    function create(uint256 id, uint256 prizeAmount, uint256 endTime) external {
        require(competitionToken.ownerOf(id) == msg.sender, "You are not owner of competitionToken");
        competitionToken.transferFrom(msg.sender, address(this), id);
        prizeToken.transferFrom(msg.sender, address(this), prizeAmount);
        prizes[id] = prizeAmount;
        _create(id, endTime);
    }

    function remove(uint256 id) external {
        uint256 index = trackingCompetition[id];
        require(msg.sender == competitions[index].owner, "You are not owner of the competition");
        competitionToken.transferFrom(address(this), competitions[index].owner, id);
        prizeToken.transfer(msg.sender, prizes[id]);
        prizes[id] = 0;
        _remove(id);
    }

    function start(uint256 id, uint256[] memory prizeRatio, address[] memory participants) external {
        uint256 index = trackingCompetition[id];
        require(msg.sender == competitions[index].owner, "You are not owner of the competition");
        _start(id, prizeRatio, participants);
    }

    function fillData(uint256 id, uint256 data) external {
        _fillData(id, data);
    }

    function _getWinners(uint256 id) internal override { 
        uint256 index = trackingCompetition[id];
        require(bytes(competitions[index].result).length != 0, "Result is not filled");
        for (uint256 i=0; i < competitions[index].encodedDataList.length; i++) {
            if (competitions[index].winners.length < competitions[index].prizeRatio.length) {
                (address participant, uint256 participantIndex, uint256 data) = abi.decode(competitions[index].encodedDataList[i], (address, uint256, uint256));
                if (questions.verify(data, competitions[index].result, competitions[index].participants.length, participantIndex)) {
                    competitions[index].winners.push(participant);
                }
            }
        }
        address[] memory winners = competitions[index].winners;
        uint256 spend = 0;
        for (uint256 i=0; i < winners.length; i++) {
            uint256 rate = competitions[index].prizeRatio[i];
            uint256 amount = (prizes[id] * rate) / 100;
            prizeToken.transfer(winners[i], amount);
            spend += amount;
        }
        if (spend < prizes[id]) {
            prizeToken.transfer(competitions[index].owner, prizes[id] - spend);
        }
        prizes[id] = 0;
    }

    function finish(uint256 id) external {
        uint256 index = trackingCompetition[id];
        competitionToken.transferFrom(address(this), competitions[index].owner, id);
        _finish(id);
    }


    function getProof(uint256 id, string memory data) external view returns (uint256) {
        uint256 index = trackingCompetition[id];
        for (uint256 i=0; i < competitions[index].participants.length; i++) {
            if (msg.sender == competitions[index].participants[i]) {
                return questions.getProof(data, competitions[index].participants.length , i);
            }
        }
        revert IsNotParticipant();
    }
}