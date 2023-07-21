// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CompetitionForm.sol";
import "../RequestResponseAnyApi/RequestResponseParticipant.sol";
import "../CompetitionService/interfaces/ICompetitionService.sol";

contract Competition is 
    Ownable,
    CompetitionForm
    {
    
    IERC721 public competitionToken;
    IERC20 public prize;
    ICompetitionService public competitionService;
    address immutable public burnNFT = 0xbfc80c13503A879c8B5FA1F64eE53479F6169a18;
    
    mapping(uint256 => uint256) public CompetitionServiceId; 

    constructor(
        IERC721 _competitionToken,
        IERC20 _prize,
        ICompetitionService _competitionService
        ) {
        competitionToken = _competitionToken;
        prize = _prize;
        competitionService = _competitionService;
    }   
    
    // function setUrl(string memory _url) external onlyOwner {
    //     url = _url;
    // }

    function create(uint256 id, uint256 prizeAmount, uint256[] memory prizeRatio) external {
        require(competitionToken.ownerOf(id) == msg.sender, "You are not owner of competitionToken");

        uint256 totalRatio = 0;
        for (uint256 i = 0; i < prizeRatio.length; i ++) {
            totalRatio += prizeRatio[i];
        }
        require(totalRatio == 100, "Sum of prize ratio should be equal 100");

        competitionToken.transferFrom(msg.sender, address(this), id);
        prize.transferFrom(msg.sender, address(this), prizeAmount);

        _initialize(id, prizeAmount, prizeRatio);
        CompetitionServiceId[id] = competitionService.register(msg.sender);
    }

    // function responseParticpants(bytes32 _requestId, uint256 _id, address[] memory _participants) public override ICNResponseFulfilled(_requestId) {
    //     competitionService.setParticipants(CompetitionServiceId(_id), _participants);
    // }

    function setParticipants(uint256 id, address[] memory participants) public {
        require(msg.sender == getForm(id).owner, "You are not owner of the competition");
        competitionService.assignParticipants(CompetitionServiceId[id], participants);
    }
    
    function remove(uint256 id) external {
        require(msg.sender == getForm(id).owner, "You are not owner of the competition");
        competitionToken.transferFrom(address(this), getForm(id).owner, id);
        prize.transfer(msg.sender, getForm(id).prizeAmount);
        _remove(id);
    }

    function finish(uint256 id) external {
        uint256 index = trackingForm[id];
        address[] memory winners = competitionService.getWinners(CompetitionServiceId[id]);

        uint256 spend = 0;
        for (uint256 i=0; i < winners.length; i++) {
            uint256 rate = forms[index].prizeRatio[i];
            uint256 amount = (forms[index].prizeAmount * rate) / 100;
            prize.transfer(winners[i], amount);
            spend += amount;
        }
        if (spend < forms[index].prizeAmount) {
            prize.transfer(forms[index].owner, forms[index].prizeAmount - spend);
        }
        competitionToken.transferFrom(address(this), burnNFT, id);
        _remove(id);
    }
}

