// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract VerifySignature {
    // refer to github: https://github.com/t4sk/hello-erc20-permit/blob/main/contracts/VerifySignature.sol
    function getSigner(bytes32 data_hash, bytes memory signature) public pure returns(address) {
        bytes32 ethSignedMessageHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", data_hash)
            );
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
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