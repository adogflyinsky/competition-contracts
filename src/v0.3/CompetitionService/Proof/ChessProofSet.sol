// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "../interfaces/IProofSet.sol";

contract ChessProofSet is IProofSet {
    uint256 immutable private allowed = 16;
    
    function get(uint256 answer, uint256 numOfParticipants, uint256 index) public pure returns (uint256) {
        require(numOfParticipants <= allowed && index < numOfParticipants);
        
        uint256 numOfProofs = allowed / numOfParticipants;
        answer = answer >> (index * numOfProofs);
        uint256 proof = 0;
        for (uint256 i = 0; i < numOfProofs; i++) {
            if(answer % 2 != 0) {
                proof += 2 ** i;
            }
            answer = answer >> 1;
        }
        return proof;
    }

}
