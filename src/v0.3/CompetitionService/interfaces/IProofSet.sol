// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IProofSet {
    function get(uint256 data, uint256 quantity, uint256 index) external pure returns (uint256);
}


