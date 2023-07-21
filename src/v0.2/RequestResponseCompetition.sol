// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./RequestResponseConsumerBase.sol";

abstract contract RequestResponseCompetition is RequestResponseConsumerBase {
    using ICN for ICN.Request;
    bytes32 private s_jobId;

    constructor(address _oracleAddress) {
        setOracle(_oracleAddress);
        s_jobId = keccak256(abi.encodePacked("any-api"));
    }

    function requestResult(uint256 id) public returns (bytes32 requestId) {
        ICN.Request memory req = buildRequest(s_jobId, address(this), this.fillResult.selector);
        req.add("baseURI", "http://127.0.0.1:8000/api/riddles/");
        req.addUInt("id", id);
        req.add("path", "answer");
        return sendRequest(req);
    }

    function cancelRequest(bytes32 _requestId) public {
        cancelRequest(_requestId, this.fillResult.selector);
    }

    function fillResult(bytes32 _requestId, uint256 _id, string memory _respone) public virtual;
}
