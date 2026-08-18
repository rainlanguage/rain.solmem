// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";
import {LibBytes32Matrix} from "src/lib/LibBytes32Matrix.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {LibPointer, Pointer} from "src/lib/LibPointer.sol";
import {LibBytes32MatrixSlow} from "test/lib/LibBytes32MatrixSlow.sol";

contract LibBytes32MatrixItemCountTest is Test {
    using LibBytes32Matrix for bytes32[][];
    using LibBytes32MatrixSlow for bytes32[][];

    /// forge-config: default.fuzz.runs = 100
    function testItemCountReference(bytes32[][] memory matrix) external pure {
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
        assertEq(LibBytes32Matrix.itemCount(new bytes32[][](0)), 0, "empty matrix");
    }

    /// Sub arrays that are all empty sum to zero, not to the outer length.
    function testItemCountAllInnerEmpty() external pure {
        bytes32[][] memory matrix = new bytes32[][](3);
        matrix[0] = new bytes32[](0);
        matrix[1] = new bytes32[](0);
        matrix[2] = new bytes32[](0);
        assertEq(matrix.itemCount(), 0, "all inner empty");
    }

    /// A lone sub array contributes its own length.
    function testItemCountSingleInner() external pure {
        assertEq(
            LibBytes32Matrix.matrixFrom(
                    LibBytes32Array.arrayFrom(bytes32(uint256(0x11)), bytes32(uint256(0x22)), bytes32(uint256(0x33)))
                ).itemCount(),
            3,
            "single inner"
        );
    }

    /// Empty sub arrays between non empty ones contribute nothing.
    function testItemCountEmptyInterleaved() external pure {
        bytes32[][] memory matrix = new bytes32[][](5);
        matrix[0] = new bytes32[](0);
        matrix[1] = LibBytes32Array.arrayFrom(bytes32(uint256(0x11)), bytes32(uint256(0x22)));
        matrix[2] = new bytes32[](0);
        matrix[3] = LibBytes32Array.arrayFrom(bytes32(uint256(0x33)));
        matrix[4] = new bytes32[](0);
        assertEq(matrix.itemCount(), 3, "empty interleaved");
    }

    /// The count is the SUM over sub arrays: not the outer length 3, not the
    /// first sub array length 1, not the longest sub array length 4.
    function testItemCountSumsAcrossInnerArrays() external pure {
        bytes32[][] memory matrix = new bytes32[][](3);
        matrix[0] = LibBytes32Array.arrayFrom(bytes32(uint256(0x11)));
        matrix[1] = LibBytes32Array.arrayFrom(
            bytes32(uint256(0x22)), bytes32(uint256(0x33)), bytes32(uint256(0x44)), bytes32(uint256(0x55))
        );
        matrix[2] = LibBytes32Array.arrayFrom(bytes32(uint256(0x66)), bytes32(uint256(0x77)));
        assertEq(matrix.itemCount(), 7, "sum across sub arrays");
    }

    /// `matrixFrom` stores the pointers it is handed, so one sub array can
    /// appear more than once and each appearance is counted. ABI decoding
    /// allocates a fresh sub array per element, so the fuzz above never builds
    /// this shape.
    function testItemCountAliasedInnerArrays() external pure {
        bytes32[] memory a = LibBytes32Array.arrayFrom(bytes32(uint256(0x11)), bytes32(uint256(0x22)));
        assertEq(LibBytes32Matrix.matrixFrom(a, a, a).itemCount(), 6, "aliased sub arrays");
    }
}
