// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
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

    /// An empty inner array contributes nothing, so it must not advance the
    /// write cursor. That is only observable when a NON-EMPTY inner array
    /// follows the empty one. Every concrete case above either makes every
    /// inner array empty or puts the empty one LAST, so this is the first case
    /// where a spurious cursor advance on an empty inner array displaces data.
    function testFlattenEmptyFirstThenNonEmpty() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = new bytes32[](0);
        matrix[1] = new bytes32[](2);
        matrix[1][0] = bytes32(uint256(0x11));
        matrix[1][1] = bytes32(uint256(0x22));

        bytes32[] memory expected = new bytes32[](2);
        expected[0] = bytes32(uint256(0x11));
        expected[1] = bytes32(uint256(0x22));
        checkFlatten(matrix, expected);
    }

    /// A leading inner array that was never assigned is also empty, but it is
    /// the zero slot rather than a freshly allocated length word. It must
    /// behave the same as an explicitly allocated empty array.
    function testFlattenUninitialisedFirstThenNonEmpty() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[1] = new bytes32[](2);
        matrix[1][0] = bytes32(uint256(0x11));
        matrix[1][1] = bytes32(uint256(0x22));

        bytes32[] memory expected = new bytes32[](2);
        expected[0] = bytes32(uint256(0x11));
        expected[1] = bytes32(uint256(0x22));
        checkFlatten(matrix, expected);
    }

    /// An empty inner array in an INTERIOR position must not displace the
    /// elements that follow it.
    function testFlattenEmptyInteriorBetweenNonEmpty() external pure {
        bytes32[][] memory matrix = new bytes32[][](3);
        matrix[0] = new bytes32[](1);
        matrix[0][0] = bytes32(uint256(0x11));
        matrix[1] = new bytes32[](0);
        matrix[2] = new bytes32[](2);
        matrix[2][0] = bytes32(uint256(0x22));
        matrix[2][1] = bytes32(uint256(0x33));

        bytes32[] memory expected = new bytes32[](3);
        expected[0] = bytes32(uint256(0x11));
        expected[1] = bytes32(uint256(0x22));
        expected[2] = bytes32(uint256(0x33));
        checkFlatten(matrix, expected);
    }

    /// A RUN of empty inner arrays between two non-empty ones. Each empty array
    /// is handled by its own iteration of the copy loop, so a per-iteration
    /// displacement accumulates across the run.
    function testFlattenConsecutiveEmptyInterior() external pure {
        bytes32[][] memory matrix = new bytes32[][](4);
        matrix[0] = new bytes32[](1);
        matrix[0][0] = bytes32(uint256(0x11));
        matrix[1] = new bytes32[](0);
        matrix[2] = new bytes32[](0);
        matrix[3] = new bytes32[](1);
        matrix[3][0] = bytes32(uint256(0x22));

        bytes32[] memory expected = new bytes32[](2);
        expected[0] = bytes32(uint256(0x11));
        expected[1] = bytes32(uint256(0x22));
        checkFlatten(matrix, expected);
    }

    /// A run of empty inner arrays in the LEADING position, before any data has
    /// been written at all.
    function testFlattenMultipleEmptyLeading() external pure {
        bytes32[][] memory matrix = new bytes32[][](3);
        matrix[0] = new bytes32[](0);
        matrix[1] = new bytes32[](0);
        matrix[2] = new bytes32[](2);
        matrix[2][0] = bytes32(uint256(0x11));
        matrix[2][1] = bytes32(uint256(0x22));

        bytes32[] memory expected = new bytes32[](2);
        expected[0] = bytes32(uint256(0x11));
        expected[1] = bytes32(uint256(0x22));
        checkFlatten(matrix, expected);
    }

    /// Empty inner arrays occupying the first, an interior and the last
    /// position of the same matrix.
    function testFlattenEmptyFirstInteriorAndLast() external pure {
        bytes32[][] memory matrix = new bytes32[][](5);
        matrix[0] = new bytes32[](0);
        matrix[1] = new bytes32[](1);
        matrix[1][0] = bytes32(uint256(0x11));
        matrix[2] = new bytes32[](0);
        matrix[3] = new bytes32[](1);
        matrix[3][0] = bytes32(uint256(0x22));
        matrix[4] = new bytes32[](0);

        bytes32[] memory expected = new bytes32[](2);
        expected[0] = bytes32(uint256(0x11));
        expected[1] = bytes32(uint256(0x22));
        checkFlatten(matrix, expected);
    }

    /// Sweep the POSITION of a single empty inner array across every index of
    /// every outer length up to 6, deterministically. No position of an empty
    /// inner array is left to a fuzzer to stumble upon.
    function testFlattenSingleEmptyAtEveryPosition() external pure {
        for (uint256 outerLength = 1; outerLength <= 6; outerLength++) {
            for (uint256 emptyAt = 0; emptyAt < outerLength; emptyAt++) {
                bytes32[][] memory matrix = new bytes32[][](outerLength);
                bytes32[] memory expected = new bytes32[]((outerLength - 1) * 2);
                uint256 k = 0;
                for (uint256 i = 0; i < outerLength; i++) {
                    if (i == emptyAt) {
                        matrix[i] = new bytes32[](0);
                        continue;
                    }
                    matrix[i] = new bytes32[](2);
                    matrix[i][0] = bytes32((i * 2) + 1);
                    matrix[i][1] = bytes32((i * 2) + 2);
                    expected[k] = bytes32((i * 2) + 1);
                    expected[k + 1] = bytes32((i * 2) + 2);
                    k += 2;
                }
                checkFlatten(matrix, expected);
            }
        }
    }

    /// forge-config: default.fuzz.runs = 100
    function testFlattenReference(bytes32[][] memory matrix) external pure {
        checkFlatten(matrix, LibBytes32MatrixSlow.flattenSlow(matrix));
    }
}
