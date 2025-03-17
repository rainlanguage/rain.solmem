// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibBytes32Matrix} from "src/lib/LibBytes32Matrix.sol";
import {LibBytes32MatrixSlow} from "test/lib/LibBytes32MatrixSlow.sol";

contract LibBytes32MatrixFlattenTest is Test {
    using LibBytes32Matrix for bytes32[][];
    using LibBytes32MatrixSlow for bytes32[][];

    function checkFlatten(bytes32[][] memory matrix, bytes32[] memory expected) internal pure {
        bytes32[] memory flattened = matrix.flatten();
        assertEq(flattened.length, expected.length, "length");
        for (uint256 i = 0; i < flattened.length; i++) {
            assertEq(flattened[i], expected[i]);
        }
    }

    /// Test an empty length 0 matrix.
    function testFlatten0() external pure {
        checkFlatten(new bytes32[][](0), new bytes32[](0));
    }

    /// Test an empty length 1 matrix.
    function testFlatten1() external pure {
        checkFlatten(new bytes32[][](1), new bytes32[](0));
    }

    /// Test an empty length 2 matrix.
    function testFlatten2() external pure {
        checkFlatten(new bytes32[][](2), new bytes32[](0));
    }

    /// Test a length 1 matrix with a length 0 array.
    function testFlatten10() external pure {
        bytes32[][] memory matrix = new bytes32[][](1);
        matrix[0] = new bytes32[](0);
        checkFlatten(matrix, new bytes32[](0));
    }

    /// Test a length 1 matrix with a length 1 array.
    function testFlatten11() external pure {
        bytes32[][] memory matrix = new bytes32[][](1);
        matrix[0] = new bytes32[](1);
        matrix[0][0] = bytes32(uint256(1));

        bytes32[] memory expected = new bytes32[](1);
        expected[0] = bytes32(uint256(1));
        checkFlatten(matrix, expected);
    }

    /// Test a length 1 matrix with a length 2 array.
    function testFlatten12() external pure {
        bytes32[][] memory matrix = new bytes32[][](1);
        matrix[0] = new bytes32[](2);
        matrix[0][0] = bytes32(uint256(1));
        matrix[0][1] = bytes32(uint256(2));

        bytes32[] memory expected = new bytes32[](2);
        expected[0] = bytes32(uint256(1));
        expected[1] = bytes32(uint256(2));
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 0 array.
    function testFlatten20() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = new bytes32[](0);
        matrix[1] = new bytes32[](0);
        checkFlatten(matrix, new bytes32[](0));
    }

    /// Test a length 2 matrix with a length 1 array.
    function testFlatten21() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = new bytes32[](1);
        matrix[0][0] = bytes32(uint256(1));
        matrix[1] = new bytes32[](0);

        bytes32[] memory expected = new bytes32[](1);
        expected[0] = bytes32(uint256(1));
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 2 array.
    function testFlatten22() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = new bytes32[](2);
        matrix[0][0] = bytes32(uint256(1));
        matrix[0][1] = bytes32(uint256(2));
        matrix[1] = new bytes32[](0);

        bytes32[] memory expected = new bytes32[](2);
        expected[0] = bytes32(uint256(1));
        expected[1] = bytes32(uint256(2));
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 3 array.
    function testFlatten23() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = new bytes32[](3);
        matrix[0][0] = bytes32(uint256(1));
        matrix[0][1] = bytes32(uint256(2));
        matrix[0][2] = bytes32(uint256(3));
        matrix[1] = new bytes32[](0);

        bytes32[] memory expected = new bytes32[](3);
        expected[0] = bytes32(uint256(1));
        expected[1] = bytes32(uint256(2));
        expected[2] = bytes32(uint256(3));
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 1 array and a length 2 array.
    function testFlatten121() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = new bytes32[](1);
        matrix[0][0] = bytes32(uint256(1));
        matrix[1] = new bytes32[](2);
        matrix[1][0] = bytes32(uint256(2));
        matrix[1][1] = bytes32(uint256(3));

        bytes32[] memory expected = new bytes32[](3);
        expected[0] = bytes32(uint256(1));
        expected[1] = bytes32(uint256(2));
        expected[2] = bytes32(uint256(3));
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 2 array and a length 1 array.
    function testFlatten211() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = new bytes32[](2);
        matrix[0][0] = bytes32(uint256(1));
        matrix[0][1] = bytes32(uint256(2));
        matrix[1] = new bytes32[](1);
        matrix[1][0] = bytes32(uint256(3));

        bytes32[] memory expected = new bytes32[](3);
        expected[0] = bytes32(uint256(1));
        expected[1] = bytes32(uint256(2));
        expected[2] = bytes32(uint256(3));
        checkFlatten(matrix, expected);
    }

    /// forge-config: default.fuzz.runs = 100
    function testFlattenReference(bytes32[][] memory matrix) external pure {
        checkFlatten(matrix, LibBytes32MatrixSlow.flattenSlow(matrix));
    }
}
