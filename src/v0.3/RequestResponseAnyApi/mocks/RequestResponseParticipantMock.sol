// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../RequestResponseParticipant.sol";

contract RequestResponseParticipantMock is RequestResponseParticipant {

    address[] public participants;

    constructor(address _oracleAddress) RequestResponseParticipant(_oracleAddress) {}

     function responseParticpants(bytes32 _requestId, uint256 _id, address[] memory _participants) public override ICNResponseFulfilled(_requestId) {
        participants = _participants;
    }
}