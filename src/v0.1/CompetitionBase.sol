// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
abstract contract CompetitionBase {

    error IsNotParticipant();

    struct Competition {
        address owner;
        uint256 id;
        uint256 startTime;
        address[] participants;
        bytes[] encodedDataList; 
        string result;
        address[] winners;
    }

    Competition[] internal competitions;
    mapping(uint256 => uint256) internal trackingCompetition;

    function _create(uint256 id) internal virtual {
        require(!isInCompetition(id), "The id is existed in competition");
        Competition memory competition;
        competition.owner = msg.sender;
        competition.id = id;
        competitions.push(competition);
        trackingCompetition[id] = competitions.length - 1;
    }  

    function _remove(uint256 id) internal virtual isValidCompetition(id) {
        uint256 index = trackingCompetition[id];
        require(competitions[index].startTime == 0, "The competition is started");
        _naiveRemove(id);
    }
    
    function _start(uint256 id, address[] memory participants, uint256 time) internal virtual {
        uint256 index = trackingCompetition[id];
        competitions[index].participants = participants;
        competitions[index].startTime= block.timestamp + time;
    }

    function _fillData(uint256 id, uint256 data) internal virtual isValidCompetition(id) 
    {
        uint256 index = trackingCompetition[id];
        require(competitions[index].startTime <= block.timestamp, "Can not fill data yet");
        require(bytes(competitions[index].result).length == 0, "Result is filled");
        for (uint256 i = 0; i < competitions[index].participants.length ; i ++) {
            if (msg.sender == competitions[index].participants[i]) {
                competitions[index].participants[i] = address(0);
                bytes memory encodeData = abi.encode(msg.sender, i, data);
                competitions[index].encodedDataList.push(encodeData);
                return;
            }
        }
        revert IsNotParticipant();
    } 

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




