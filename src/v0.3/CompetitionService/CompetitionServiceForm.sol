// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IProofSet.sol";
abstract contract CompetitionServiceForm {
    error IsNotParticipant();

    struct Competition {
       uint256 id;
        address organizer;
        address validator;
        address[] participants;
        IProofSet proofSet;
        bytes[] proofs;
        uint256 result;
    }

    IProofSet public defaultProofSet;
    
    constructor(IProofSet _defaultProofSet) {
        defaultProofSet = _defaultProofSet;
    }

    Competition[] internal competitions;
    mapping(uint256 => uint256) internal trackingCompetition;

    function _initialize(uint256 id, address validator) internal {
        require(!inCompetition(id), "The id is existed in Competition");
        Competition memory competition;
        competition.id = id;
        competition.organizer = msg.sender;
        competition.validator = validator;
        competition.proofSet = defaultProofSet;
        competitions.push(competition);
        trackingCompetition[id] = competitions.length - 1;
    }  

    function _remove(uint256 id) internal isInCompetition(id) {
        uint256 index = trackingCompetition[id];
        Competition memory lastCompetition = competitions[competitions.length - 1];

        competitions[index] = lastCompetition;
        trackingCompetition[lastCompetition.id] = index;
        
        trackingCompetition[id] = 0;
        competitions.pop();
    }
    
    function inCompetition(uint256 id) public view virtual returns(bool) {
        if (competitions.length == 0) {
            return false;
        }
        if (trackingCompetition[id] == 0 && competitions[0].id != id) {
            return false;
        }
        return true;
    }
    function getCompetition(uint256 id) internal view isInCompetition(id) returns (Competition memory) {
        uint256 index = trackingCompetition[id];
        return competitions[index];
    }
     function getCompetitionHash(uint256 id) public view returns (bytes32) {
        Competition memory competition = getCompetition(id);
        return keccak256(abi.encodePacked(competition.id, competition.proofSet, competition.organizer, competition.participants));
    }

    function getIndexAndProof(uint256 id, uint256 data) public view returns (uint256, uint256) {
        Competition memory competition = getCompetition(id);
        for (uint256 i=0; i < competition.participants.length; i++) {
            if (msg.sender == competition.participants[i]) {
                return (i+1 ,competition.proofSet.get(data, competition.participants.length , i));
            }
        }
        revert IsNotParticipant();
    }

      modifier isInCompetition(uint256 id) virtual {
        require(inCompetition(id), "This id is not in Competition");
        _;
    }
}




