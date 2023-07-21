// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./CompetitionV0.sol";

contract CompetitionV1 is CompetitionV0 {

    constructor(IERC721 _competitionToken, address _prizeAddress, IQuestionSet _questions) 
    CompetitionV0(_competitionToken, _prizeAddress, _questions)
    {}  
    
    function join(uint256 id) external {
        address[] memory participants = new address[](1);
        participants[0] = msg.sender;
        _start(id, participants, 0);
    }

    function fillResult(uint256 id, string memory result) external {
        uint256 index = trackingCompetition[id];
        require(msg.sender == competitions[index].owner, "You are not owner of competition.");
        _fillResult(id, result);
    } 
    

}