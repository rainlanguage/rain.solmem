// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibUint256Matrix} from "../../../src/lib/LibUint256Matrix.sol";
import {LibUint256Array} from "../../../src/lib/LibUint256Array.sol";
import {LibPointer, Pointer} from "../../../src/lib/LibPointer.sol";
import {LibUint256MatrixSlow} from "../../lib/LibUint256MatrixSlow.sol";

contract LibUint256MatrixItemCountTest is Test {
    using LibUint256Matrix for uint256[][];
    using LibUint256MatrixSlow for uint256[][];

    /// forge-config: default.fuzz.runs = 100
    function testItemCountReference(uint256[][] memory matrix) external pure {
        // itemCount only reads the matrix, so it must not move the free memory
        // pointer. Read the pointer immediately either side of the call under
        // test, as assertions themselves allocate.
        Pointer allocatedBefore = LibPointer.allocatedMemoryPointer();
        uint256 count = matrix.itemCount();
        Pointer allocatedAfter = LibPointer.allocatedMemoryPointer();
        assertEq(Pointer.unwrap(allocatedBefore), Pointer.unwrap(allocatedAfter), "itemCount allocated");

        assertEq(count, matrix.itemCountSlow());
    }

    /// An empty matrix has no sub arrays to sum, so the count is zero.
    function testItemCountEmptyMatrix() external pure {
        assertEq(LibUint256Matrix.itemCount(new uint256[][](0)), 0, "empty matrix");
    }

    /// Sub arrays that are all empty sum to zero, not to the outer length.
    function testItemCountAllInnerEmpty() external pure {
        uint256[][] memory matrix = new uint256[][](3);
        matrix[0] = new uint256[](0);
        matrix[1] = new uint256[](0);
        matrix[2] = new uint256[](0);
        assertEq(matrix.itemCount(), 0, "all inner empty");
    }

    /// A lone sub array contributes its own length.
    function testItemCountSingleInner() external pure {
        assertEq(
            LibUint256Matrix.matrixFrom(LibUint256Array.arrayFrom(0x11, 0x22, 0x33)).itemCount(), 3, "single inner"
        );
    }

    /// Empty sub arrays between non empty ones contribute nothing.
    function testItemCountEmptyInterleaved() external pure {
        uint256[][] memory matrix = new uint256[][](5);
        matrix[0] = new uint256[](0);
        matrix[1] = LibUint256Array.arrayFrom(0x11, 0x22);
        matrix[2] = new uint256[](0);
        matrix[3] = LibUint256Array.arrayFrom(0x33);
        matrix[4] = new uint256[](0);
        assertEq(matrix.itemCount(), 3, "empty interleaved");
    }

    /// The count is the SUM over sub arrays: not the outer length 3, not the
    /// first sub array length 1, not the longest sub array length 4.
    function testItemCountSumsAcrossInnerArrays() external pure {
        uint256[][] memory matrix = new uint256[][](3);
        matrix[0] = LibUint256Array.arrayFrom(0x11);
        matrix[1] = LibUint256Array.arrayFrom(0x22, 0x33, 0x44, 0x55);
        matrix[2] = LibUint256Array.arrayFrom(0x66, 0x77);
        assertEq(matrix.itemCount(), 7, "sum across sub arrays");
    }

    /// `matrixFrom` stores the pointers it is handed, so one sub array can
    /// appear more than once and each appearance is counted. ABI decoding
    /// allocates a fresh sub array per element, so the fuzz above never builds
    /// this shape.
    function testItemCountAliasedInnerArrays() external pure {
        uint256[] memory a = LibUint256Array.arrayFrom(0x11, 0x22);
        assertEq(LibUint256Matrix.matrixFrom(a, a, a).itemCount(), 6, "aliased sub arrays");
    }
}
