// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibUint256Matrix} from "src/lib/LibUint256Matrix.sol";
import {LibUint256MatrixSlow} from "test/lib/LibUint256MatrixSlow.sol";

contract LibUint256MatrixFlattenTest is Test {
    using LibUint256Matrix for uint256[][];
    using LibUint256MatrixSlow for uint256[][];

    function checkFlatten(uint256[][] memory matrix, uint256[] memory expected) internal pure {
        uint256[] memory flattened = matrix.flatten();
        assertEq(flattened.length, expected.length, "length");
        for (uint256 i = 0; i < flattened.length; i++) {
            assertEq(flattened[i], expected[i]);
        }
    }

    /// Test an empty length 0 matrix.
    function testFlatten0() external pure {
        checkFlatten(new uint256[][](0), new uint256[](0));
    }

    /// Test an empty length 1 matrix.
    function testFlatten1() external pure {
        checkFlatten(new uint256[][](1), new uint256[](0));
    }

    /// Test an empty length 2 matrix.
    function testFlatten2() external pure {
        checkFlatten(new uint256[][](2), new uint256[](0));
    }

    /// Test a length 1 matrix with a length 0 array.
    function testFlatten10() external pure {
        uint256[][] memory matrix = new uint256[][](1);
        matrix[0] = new uint256[](0);
        checkFlatten(matrix, new uint256[](0));
    }

    /// Test a length 1 matrix with a length 1 array.
    function testFlatten11() external pure {
        uint256[][] memory matrix = new uint256[][](1);
        matrix[0] = new uint256[](1);
        matrix[0][0] = 1;

        uint256[] memory expected = new uint256[](1);
        expected[0] = 1;
        checkFlatten(matrix, expected);
    }

    /// Test a length 1 matrix with a length 2 array.
    function testFlatten12() external pure {
        uint256[][] memory matrix = new uint256[][](1);
        matrix[0] = new uint256[](2);
        matrix[0][0] = 1;
        matrix[0][1] = 2;

        uint256[] memory expected = new uint256[](2);
        expected[0] = 1;
        expected[1] = 2;
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 0 array.
    function testFlatten20() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = new uint256[](0);
        matrix[1] = new uint256[](0);
        checkFlatten(matrix, new uint256[](0));
    }

    /// Test a length 2 matrix with a length 1 array.
    function testFlatten21() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = new uint256[](1);
        matrix[0][0] = 1;
        matrix[1] = new uint256[](0);

        uint256[] memory expected = new uint256[](1);
        expected[0] = 1;
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 2 array.
    function testFlatten22() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = new uint256[](2);
        matrix[0][0] = 1;
        matrix[0][1] = 2;
        matrix[1] = new uint256[](0);

        uint256[] memory expected = new uint256[](2);
        expected[0] = 1;
        expected[1] = 2;
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 3 array.
    function testFlatten23() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = new uint256[](3);
        matrix[0][0] = 1;
        matrix[0][1] = 2;
        matrix[0][2] = 3;
        matrix[1] = new uint256[](0);

        uint256[] memory expected = new uint256[](3);
        expected[0] = 1;
        expected[1] = 2;
        expected[2] = 3;
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 1 array and a length 2 array.
    function testFlatten121() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = new uint256[](1);
        matrix[0][0] = 1;
        matrix[1] = new uint256[](2);
        matrix[1][0] = 2;
        matrix[1][1] = 3;

        uint256[] memory expected = new uint256[](3);
        expected[0] = 1;
        expected[1] = 2;
        expected[2] = 3;
        checkFlatten(matrix, expected);
    }

    /// Test a length 2 matrix with a length 2 array and a length 1 array.
    function testFlatten211() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = new uint256[](2);
        matrix[0][0] = 1;
        matrix[0][1] = 2;
        matrix[1] = new uint256[](1);
        matrix[1][0] = 3;

        uint256[] memory expected = new uint256[](3);
        expected[0] = 1;
        expected[1] = 2;
        expected[2] = 3;
        checkFlatten(matrix, expected);
    }

    /// forge-config: default.fuzz.runs = 100
    function testFlattenReference(uint256[][] memory matrix) external pure {
        checkFlatten(matrix, LibUint256MatrixSlow.flattenSlow(matrix));
    }
}
