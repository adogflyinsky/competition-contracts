// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./libraries/Counters.sol";
import "./interfaces/IProofSet.sol";
import "./interfaces/ICompetitionData.sol";
import "./CompetitionServiceForm.sol";
import "./interfaces/ICompetitionService.sol";

contract CompetitionService is 
    ICompetitionService,
    CompetitionServiceForm {
    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    ICompetitionData public competitionData;

    constructor(IProofSet _proofSet, ICompetitionData _competitionData) 
        CompetitionServiceForm(_proofSet) 
    {
        competitionData = _competitionData;
    }

    function register(address validator) public returns(uint256) {
        _idTracker.increment();
        uint256 id = _idTracker.current();
        _initialize(id, validator);
        return id;
    }  

    function setProofSet(uint256 id, IProofSet proofSet) public isInCompetition(id) {
        uint256 index = trackingCompetition[id];
        Competition memory c = competitions[index];
        require(c.organizer == msg.sender, "Only organizer can set.");
        require(c.participants.length == 0, "The competition was started.");
        competitions[index].proofSet = proofSet;
    }

    function assignParticipants(uint256 id, address[] memory participants) public isInCompetition(id) {
        uint256 index = trackingCompetition[id];
        Competition memory c = competitions[index];
        require(c.organizer == msg.sender, "Only organizer can start.");
        require(c.participants.length == 0, "The competition was started.");
        competitions[index].participants = participants;
    }

    function fill(uint256 id, bytes[] memory data) public {
        uint256 index = trackingCompetition[id];
        Competition memory c = competitions[index];
        bytes32 state = getCompetitionHash(id);

        bytes memory tx_final = data[data.length - 1];
        (bytes32 final_state, uint8 final_index, uint64 result, address final_signer) = competitionData.decode(tx_final);
        require(final_index == 0, "Final index should be equal to 0.");
        require(c.validator == final_signer, "Final signer must be organizer.");
        

        for (uint256 i = 0; i < data.length - 1; i++) {
            bytes memory tx_i = data[i];
            (bytes32 state_i, uint8 index_i, uint64 message_i, address signer_i) = competitionData.decode(tx_i); 
            require(state_i == state, "Wrong state");
            require(c.participants[index_i - 1] == signer_i, "Wrong signer");
            competitions[index].proofs.push(abi.encodePacked(index_i-1, message_i)); // uint8, uint64
            state = competitionData.getNextState(state, index_i, message_i);
        }
        require(state == final_state, "Final state is wrong.");
        competitions[index].result = result;
    }

    function report(uint256 id, bytes[] memory messages, bytes memory signature) public isInCompetition(id)  {
        Competition memory c = getCompetition(id);
        uint256 p_len = c.proofs.length;
        uint256 m_len = messages.length;
        if (p_len >= m_len) {
            require(keccak256(c.proofs[m_len - 1]) != keccak256(messages[m_len-1]), "C1");
        } else {
            require(keccak256(c.proofs[p_len - 1]) == keccak256(messages[p_len-1]), "C2");
        }
        // Cannot use state of organizer to report
        require(keccak256(abi.encode(uint8(0), uint64(c.result))) != keccak256(messages[m_len-1]), "C3");

        bytes32 state = getCompetitionHash(id);
        state = competitionData.getState(state, messages);
        if(competitionData.getSigner(state, signature) == c.validator) {
            // ...
            _remove(id);
        }
    }

   function getWinners(uint256 id) public isInCompetition(id) returns (address[] memory){
        Competition memory c = getCompetition(id);
        address[] memory check_winners = new address[](c.proofs.length);
        uint256 count = 0;
        for (uint256 i = 0; i < c.proofs.length; i++) {
            bytes memory data = c.proofs[i];
            uint256 index;
            uint256 proof;
            assembly {
                index := mload(add(data, 1))
                proof := mload(add(data, 9))
            }
            if(c.proofSet.get(c.result, c.participants.length, uint8(index)) == uint64(proof)) {
                check_winners[count] = c.participants[i];
                count++;
            }
        }
        address[] memory winners = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            winners[i] = check_winners[i];
        }
        _remove(id);
        return winners;
   }
}