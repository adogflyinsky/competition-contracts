// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library CustomMath {

    function log2(uint256 x) public pure returns (uint256) {
        require(x > 0, "Input must be greater than zero.");

        uint256 y = x;
        uint256 result = 0;

        while (y >= 2) {
            y /= 2;
            result++;
        }

        return result;
    }

    function toBinary(uint256 number) internal pure returns (string memory) {
        if (number == 0) {
            return "0";
        }
        
        uint256 tempNumber = number;
        uint256 binaryDigits = 0;

        while (tempNumber != 0) {
            binaryDigits++;
            tempNumber /= 2;
        }

        bytes memory binaryResult = new bytes(binaryDigits);

        for (uint256 i = 0; i < binaryDigits; i++) {
            if (number % 2 == 0) {
                binaryResult[binaryDigits - 1 - i] = "0";
            } else {
                binaryResult[binaryDigits - 1 - i] = "1";
            }

            number /= 2;
        }

        return string(binaryResult);
    }

    function toBinaryWithLength(uint256 length, uint256 index) internal pure returns (string memory) {
        require(index < length, "Index need to be smaller than length.");
        uint256 binLength = log2(length) + 1;
        bytes memory binaryResult = new bytes(binLength);

        for (uint256 i = 0; i < binLength; i++) {
            if (index % 2 == 0) {
                binaryResult[binLength - 1 - i] = "0";
            } else {
                binaryResult[binLength - 1 - i] = "1";
            }

            index /= 2;
        }
        return string(binaryResult);
        
    }

}