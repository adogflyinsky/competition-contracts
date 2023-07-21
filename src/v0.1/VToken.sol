// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract VToken is
    ERC20("VToken", "VT"),
    ERC20Burnable,
    Ownable
{
    event Minted(address to,uint256 amount);
    uint256 private cap = 1000_000_000_000 * 10**uint256(18);
    constructor() {
        _mint(msg.sender, cap);
        transferOwnership(msg.sender);
    }
    function mint(address to, uint256 amount) public onlyOwner {
        require(
            ERC20.totalSupply() + amount <= cap,
            "Token: exceed capacity"
        );
        _mint(to, amount);
        emit Minted(to, amount);
    }
}
