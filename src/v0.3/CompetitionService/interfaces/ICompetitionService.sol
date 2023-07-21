// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ICompetitionService {
    function register(address validator) external returns (uint256);
    function assignParticipants(uint256 id, address[] memory participants) external;
    function fill(uint256 id, bytes[] memory data) external;
    function getWinners(uint256 id) external returns (address[] memory winners);
}

