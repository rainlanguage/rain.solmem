// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

library LibUint256MatrixSlow {
    function compareMatrices(uint256[][] memory a, uint256[][] memory b, uint256 expectedLength)
        internal
        pure
        returns (bool)
    {
        bool equal = true;
        equal = equal && (a.length == expectedLength);
        equal = equal && (a.length == b.length);
        for (uint256 i = 0; i < a.length; i++) {
            uint256 hashesEqual;
            uint256[] memory ai = a[i];
            uint256[] memory bi = b[i];
            assembly ("memory-safe") {
                hashesEqual :=
                    eq(keccak256(ai, mul(0x20, add(mload(ai), 1))), keccak256(bi, mul(0x20, add(mload(bi), 1))))
            }
            equal = equal && (hashesEqual > 0);
            if (!equal) break;
        }
        return equal;
    }

    function matrixFromSlow(uint256[] memory a) internal pure returns (uint256[][] memory) {
        uint256[][] memory matrix = new uint256[][](1);
        matrix[0] = a;
        return matrix;
    }

    function matrixFromSlow(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[][] memory) {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = a;
        matrix[1] = b;
        return matrix;
    }

    function matrixFromSlow(uint256[] memory a, uint256[] memory b, uint256[] memory c)
        internal
        pure
        returns (uint256[][] memory)
    {
        uint256[][] memory matrix = new uint256[][](3);
        matrix[0] = a;
        matrix[1] = b;
        matrix[2] = c;
        return matrix;
    }

    function itemCountSlow(uint256[][] memory matrix) internal pure returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < matrix.length; i++) {
            count += matrix[i].length;
        }
        return count;
    }

    function flattenSlow(uint256[][] memory matrix) internal pure returns (uint256[] memory) {
        uint256 length = 0;
        for (uint256 i = 0; i < matrix.length; i++) {
            length += matrix[i].length;
        }

        uint256[] memory array = new uint256[](length);
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
