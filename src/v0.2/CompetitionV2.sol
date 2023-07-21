// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IQuestionSet.sol";
import "./CompetitionV0.sol";
import "./RequestResponseCompetition.sol";


contract CompetitionV2 is CompetitionV0, RequestResponseCompetition {
    constructor(
        IQuestionSet _questions,
        IERC721 _competitionToken,
        IERC20 _prizeToken,
        address _oracleAddress
    ) 
        CompetitionV0(_questions, _competitionToken, _prizeToken) 
        RequestResponseCompetition(_oracleAddress)
        {}
        
        
    function fillResult(bytes32 _requestId, uint256 id, string memory _respone) public override ICNResponseFulfilled(_requestId) {
        _fillResult(id, _respone);
    }
    

}