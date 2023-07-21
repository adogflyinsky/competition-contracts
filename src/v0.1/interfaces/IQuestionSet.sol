// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IQuestionSet {

    function getProof(string memory data, uint256 numOfQuestions, uint256 index) external pure returns (uint256);

    function verify(uint256 proof, string memory data, uint256 numOfQuestions, uint256 index) external returns (bool);

}


