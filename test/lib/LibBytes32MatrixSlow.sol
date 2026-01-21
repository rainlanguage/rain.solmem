// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

library LibBytes32MatrixSlow {
    function compareMatrices(bytes32[][] memory a, bytes32[][] memory b, uint256 expectedLength)
        internal
        pure
        returns (bool)
    {
        bool equal = true;
        equal = equal && (a.length == expectedLength);
        equal = equal && (a.length == b.length);
        for (uint256 i = 0; i < a.length; i++) {
            uint256 hashesEqual;
            bytes32[] memory ai = a[i];
            bytes32[] memory bi = b[i];
            assembly ("memory-safe") {
                hashesEqual := eq(
                    keccak256(ai, mul(0x20, add(mload(ai), 1))),
                    keccak256(bi, mul(0x20, add(mload(bi), 1)))
                )
            }
            equal = equal && (hashesEqual > 0);
            if (!equal) break;
        }
        return equal;
    }

    function matrixFromSlow(bytes32[] memory a) internal pure returns (bytes32[][] memory) {
        bytes32[][] memory matrix = new bytes32[][](1);
        matrix[0] = a;
        return matrix;
    }

    function matrixFromSlow(bytes32[] memory a, bytes32[] memory b) internal pure returns (bytes32[][] memory) {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = a;
        matrix[1] = b;
        return matrix;
    }

    function matrixFromSlow(bytes32[] memory a, bytes32[] memory b, bytes32[] memory c)
        internal
        pure
        returns (bytes32[][] memory)
    {
        bytes32[][] memory matrix = new bytes32[][](3);
        matrix[0] = a;
        matrix[1] = b;
        matrix[2] = c;
        return matrix;
    }

    function itemCountSlow(bytes32[][] memory matrix) internal pure returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < matrix.length; i++) {
            count += matrix[i].length;
        }
        return count;
    }

    function flattenSlow(bytes32[][] memory matrix) internal pure returns (bytes32[] memory) {
        uint256 length = 0;
        for (uint256 i = 0; i < matrix.length; i++) {
            length += matrix[i].length;
        }

        bytes32[] memory array = new bytes32[](length);
        uint256 k = 0;
        for (uint256 i = 0; i < matrix.length; i++) {
            for (uint256 j = 0; j < matrix[i].length; j++) {
                array[k] = matrix[i][j];
                k++;
            }
        }
        return array;
    }
}
