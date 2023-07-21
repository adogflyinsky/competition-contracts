// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IProofSet.sol";
interface ICompetitionData {
    function getSigner(bytes32 data_hash, bytes memory signature) external pure returns(address);
    function decode(bytes memory data) external pure returns (bytes32, uint8, uint64, address);
    function getNextState(bytes32 state, uint256 index, uint256 message) external pure returns (bytes32);
    function getState(bytes32 state, bytes[] memory messages) external pure returns (bytes32);

}