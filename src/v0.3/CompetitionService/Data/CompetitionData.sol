// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../interfaces/ICompetitionData.sol";
contract CompetitionData is ICompetitionData {
    
     function getSigner(bytes32 data_hash, bytes memory signature) public pure returns(address) {
        bytes32 ethSignedMessageHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", data_hash)
            );
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function nextState(bytes32 state, bytes memory data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(state, data));
    }

    function decode(bytes memory data) public pure returns (bytes32, uint8, uint64, address) {
        bytes32 r;
        bytes32 s; 
        uint8 v;
        bytes32 state;
        uint256 index;
        uint256 message;
        address signer;

        assembly {
            state := mload(add(data, 32))

            index := mload(add(data, 33))

            message := mload(add(data, 41))

            r := mload(add(data, 73))

            s := mload(add(data, 105))

            v := byte(0, mload(add(data, 137)))
        }

        bytes32 hash_data = keccak256(abi.encodePacked(state, uint8(index), uint64(message)));
        bytes32 ethSignedMessageHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash_data)
            );
        signer = ecrecover(ethSignedMessageHash, v, r, s);
        return (state, uint8(index), uint64(message), signer);
    }
    function getMessage(uint256 index, uint256 message) public pure returns (bytes memory) {
        return abi.encodePacked(uint8(index), uint64(message));
    }

    function getData(bytes32 state, uint256 index, uint256 message) public pure returns (bytes memory) {
        return abi.encodePacked(state, uint8(index), uint64(message));
    }

    function getTx(bytes32 state, uint256 index, uint256 message, bytes memory signature) public pure returns (bytes memory) {
        return abi.encodePacked(state, uint8(index), uint64(message), signature);
    }

    function getNextState(bytes32 state, uint256 index, uint256 message) public pure returns (bytes32) {
        return keccak256(getData(state, index, message));
    }

    function getState(bytes32 state, bytes[] memory messages) public pure returns (bytes32) {
        for (uint256 i = 0; i < messages.length; i++) {
            state = nextState(state, messages[i]);
        }
        return state;
    }
    
    function _splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {          
            r := mload(add(sig, 32))

            s := mload(add(sig, 64))

            v := byte(0, mload(add(sig, 96)))
        }
    }


}