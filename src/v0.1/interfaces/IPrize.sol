// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPrize {
    function mintTo(address to, uint256 taskId, uint256 amount, uint256[] memory ratio) external returns (uint256);
    function checkIsActive(uint256 id) external returns (bool);
    function fund(uint256 id, uint256 amount) external;
    function active(uint256 id, uint256 taskId, address[] memory receivers) external;
    function taskIdOf(uint256 id) external view returns (uint256);
}