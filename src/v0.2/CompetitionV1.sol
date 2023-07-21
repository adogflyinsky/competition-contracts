// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IQuestionSet.sol";
import "./CompetitionV0.sol";

contract CompetitionV1 is CompetitionV0 {
    constructor(
        IQuestionSet _questions,
        IERC721 _competitionToken,
        IERC20 _prizeToken
    ) 
        CompetitionV0(_questions, _competitionToken, _prizeToken)
    {}  

    function fillResult(uint256 id, string memory result) external {
        uint256 index = trackingCompetition[id];
        require(msg.sender == competitions[index].owner, "You are not owner of competition.");
        _fillResult(id, result);
    } 
    

}