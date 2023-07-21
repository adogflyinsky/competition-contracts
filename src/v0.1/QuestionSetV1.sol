// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IQuestionSet.sol";
import "./libraries/CustomMath.sol";

contract QuestionSetV1 is IQuestionSet {
    using CustomMath for uint256;
    
    function getProof(string memory data, uint256 numOfQuestions, uint256 index) public pure returns (uint256) {
        require(index < numOfQuestions, "Index need to be smaller than length.");
        uint256 binLength = numOfQuestions.log2() + 1;
        bytes32 hash = keccak256(bytes(data));
        for (uint256 i = 0; i < binLength; i++) {
            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash));
            } else {
                hash = sha256(abi.encodePacked(hash));
            }
            index /= 2;
        }
        return uint256(hash) % 20;
    }

    function verify(uint256 proof, string memory data, uint256 numOfQuestions, uint256 index) external pure returns (bool) {
        return getProof(data, numOfQuestions, index) == proof;
    }
    
}