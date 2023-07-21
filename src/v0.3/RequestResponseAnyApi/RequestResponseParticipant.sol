// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./RequestResponseConsumerBase.sol";

abstract contract RequestResponseParticipant is RequestResponseConsumerBase {
    using ICN for ICN.Request;

    bytes32 private s_jobId;
    string internal url;
    constructor(address _oracleAddress) {
        setOracle(_oracleAddress);
        s_jobId = keccak256(abi.encodePacked("any-api"));
        url = "";
    }

    function requestParticipants(uint256 id) public returns (bytes32 requestId) {
        ICN.Request memory req = buildRequest(s_jobId, address(this), this.responseParticpants.selector);
        req.add("url", url);
        req.addUInt("id", id);
        return sendRequest(req);
    }

    function responseParticpants(bytes32 _requestId, uint256 _id, address[] memory _respone) public virtual;

    function cancelRequest(bytes32 _requestId) public {
        cancelRequest(_requestId, this.responseParticpants.selector);
    }

}
