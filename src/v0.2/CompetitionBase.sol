// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
abstract contract CompetitionBase {

    error IsNotParticipant();

    struct Competition {
        address owner;
        uint256 id;
        uint256 endTime;
        uint256[] prizeRatio; // sum of ratio is equal 100. 
        address[] participants;
        bytes[] encodedDataList; // including: address, index of participant, answer 
        string result;
        address[] winners;
    }

    Competition[] internal competitions;
    mapping(uint256 => uint256) internal trackingCompetition;

    function _create(uint256 id, uint256 endTime) internal virtual {
        require(!isInCompetition(id), "The id is existed in competition");
        Competition memory competition;
        competition.owner = msg.sender;
        competition.id = id;
        competition.endTime = endTime;
        competitions.push(competition);
        trackingCompetition[id] = competitions.length - 1;
    }  

    function _remove(uint256 id) internal virtual isValidCompetition(id) {
        uint256 index = trackingCompetition[id];
        require(competitions[index].endTime <= block.timestamp, "The competition is started");
        _naiveRemove(id);
    }
    
    function _start(uint256 id, uint256[] memory prizeRatio, address[] memory participants) internal virtual {
        uint256 totalRatio = 0;
        for (uint256 i = 0; i < prizeRatio.length; i ++) {
            totalRatio += prizeRatio[i];
        }
        require(totalRatio == 100, "Sum of prize ratio should be equal 100");
        uint256 index = trackingCompetition[id];
        competitions[index].participants = participants;
        competitions[index].prizeRatio = prizeRatio;
    }

    function _fillData(uint256 id, uint256 data) internal virtual isValidCompetition(id) {
        uint256 index = trackingCompetition[id];
        require(bytes(competitions[index].result).length == 0, "Result is filled");
        for (uint256 i = 0; i < competitions[index].participants.length ; i ++) {
            if (msg.sender == competitions[index].participants[i]) {
                // Remove address in participants by replacing it with address(0) 
                competitions[index].participants[i] = address(0);
                bytes memory encodeData = abi.encode(msg.sender, i, data);
                competitions[index].encodedDataList.push(encodeData);
                return;
            }
        }
        revert IsNotParticipant();
    } 

    // Add condition and specific address allowing to fill result
    function _fillResult(uint256 id, string memory result) internal virtual isValidCompetition(id) {
        uint256 index = trackingCompetition[id];
        require(bytes(competitions[index].result).length == 0, "Result is filled");
        competitions[index].result = result;
    }

    function _getWinners(uint256 id) internal virtual;

    function _finish(uint256 id) internal virtual isValidCompetition(id) {
        uint256 index = trackingCompetition[id];
        require(bytes(competitions[index].result).length != 0, "Result is not filled");
        _getWinners(id);
        _naiveRemove(id);
    }

    function _naiveRemove(uint256 id) private {
        uint256 index = trackingCompetition[id];
        Competition memory lastCompetition = competitions[competitions.length - 1];
        uint256 lastPuzzleId = lastCompetition.id;
        competitions[index] = lastCompetition;
        trackingCompetition[lastPuzzleId] = index;
        trackingCompetition[id] = 0;
        competitions.pop();
    }

    function isInCompetition(uint256 id) public view virtual returns(bool) {
        if (competitions.length == 0) {
            return false;
        }
        if (trackingCompetition[id] == 0 && competitions[0].id != id) {
            return false;
        }
        return true;
    }
   
    modifier isValidCompetition(uint256 id) virtual {
        require(isInCompetition(id), "This id is not in competition");
        _;
    }

    function getCompetition(uint256 id) public view isValidCompetition(id) returns (Competition memory) {
        uint256 index = trackingCompetition[id];
        return competitions[index];

    }

    function getParticipants(uint256 id) public view isValidCompetition(id) returns (address[] memory) {
        uint256 index = trackingCompetition[id];
        return competitions[index].participants;
    }

}   




