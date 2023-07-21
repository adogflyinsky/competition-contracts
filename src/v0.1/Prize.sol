// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./VToken.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPrize.sol";

contract Prize is IPrize, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    IERC20 private _token;
    constructor(IERC20 token) ERC721("Prize", "Prize") {
        _token = token;
    }
    struct PrizeInfo {
        address sender;
        uint256 taskId;
        
        uint256 amount;
        uint256[] ratio; // Purpose is for spending all.

        bool isActive; 
    }

    mapping(uint256 => PrizeInfo) private prizes;

    function getPrizeInfoById(uint256 id) public view returns (PrizeInfo memory) {
        return prizes[id];
    }
    
    function mintTo(address to, uint256 taskId, uint256 amount, uint256[] memory ratio) external returns (uint256) {
        require(_token.balanceOf(msg.sender) >= amount, "You don't have enough token.");
        SafeERC20.safeTransferFrom(_token, msg.sender, address(this), amount);
        uint256 sum = 0;
        for (uint256 i = 0; i < ratio.length;  i++) {
            sum += ratio[i];
        }
        require(sum == 100, "sum of ratio should be equal 100");
        _tokenIdTracker.increment();    
        uint256 token_id = _tokenIdTracker.current();
        prizes[token_id] = PrizeInfo(msg.sender, taskId, amount, ratio, false);
        _mint(to, token_id);
        return token_id;
    }

    function listPrizeIds(address owner)external view returns (uint256[] memory tokenIds){
        uint balance = balanceOf(owner);
        uint256[] memory ids = new uint256[](balance);
       
        for( uint i = 0;i < balance; i++)
        {
            ids[i]=tokenOfOwnerByIndex(owner,i);
        }
        return (ids);
    }

    function fund(uint256 id, uint256 amount) external {
        require(!checkIsActive(id) , "This prize is actived");
        require(_token.balanceOf(msg.sender) >= amount, "You don't have enough token");
        SafeERC20.safeTransferFrom(_token, msg.sender, address(this), amount);
        prizes[id].amount += amount;
    }

    function active(uint256 id, uint256 taskId, address[] memory receivers) external {
        require(ownerOf(id) == msg.sender, "Need to be owner to active");
        require(!checkIsActive(id) , "This prize is actived");
        require(prizes[id].taskId == taskId, "Don't match task id");
        require(receivers.length <= prizes[id].ratio.length, "Number of receivers exceed");
        uint256 spend = 0;
        for (uint256 i=0; i < receivers.length; i++) {
            uint256 amount = prizes[id].amount * prizes[id].ratio[i] / 100;
            _token.transfer(receivers[i], amount);
            spend += amount;
        }
        _token.transfer(prizes[id].sender, prizes[id].amount - spend);
        prizes[id].isActive = true;
    }

    function checkIsActive(uint256 id) public view returns (bool) {
        require(_tokenIdTracker.current() >= id, "Token is not minted.");
        return prizes[id].isActive;
    }

    function taskIdOf(uint256 id) public view returns (uint256) { 
        require(_tokenIdTracker.current() >= id, "Token is not minted.");
        return prizes[id].taskId;
    }
}
