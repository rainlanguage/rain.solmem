// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {LibBytes32Matrix, LibPointer, Pointer} from "src/lib/LibBytes32Matrix.sol";

/// The existing `flatten` tests assert the CONTENTS of the flattened array.
/// `flatten` also performs an allocation, and an over-allocating `flatten`
/// passes every content assertion while leaving the free memory pointer beyond
/// the end of the array it returned. `matrixFrom` and `arrayFrom` are already
/// pinned to `allocatedMemoryPointer()`; `flatten` was not.
contract LibBytes32MatrixAllocationTest is Test {
    using LibBytes32Array for bytes32[];
    using LibBytes32Matrix for bytes32[][];

    /// forge-config: default.fuzz.runs = 100
    function testFlattenAllocatesExactly(bytes32[][] memory matrix) external pure {
        bytes32[] memory flattened = matrix.flatten();

        assertEq(
            Pointer.unwrap(LibPointer.allocatedMemoryPointer()),
            Pointer.unwrap(flattened.endPointer()),
            "fmp must sit exactly at the end of the flattened array"
        );
    }

    /// Concrete non-fuzzed case: a matrix of two non-empty arrays.
    function testFlattenAllocatesExactlyConcrete() external pure {
        bytes32[][] memory matrix = new bytes32[][](2);
        matrix[0] = LibBytes32Array.arrayFrom(bytes32(uint256(0x81)), bytes32(uint256(0x82)));
        matrix[1] = LibBytes32Array.arrayFrom(bytes32(uint256(0x83)));

        bytes32[] memory flattened = matrix.flatten();
        // Read the free memory pointer BEFORE any assertion, because assertions
        // allocate and would move it.
        uint256 fmpAfter = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256 endOfFlattened = uint256(Pointer.unwrap(flattened.endPointer()));

        assertEq(flattened.length, 3, "length");
        assertEq(flattened[0], bytes32(uint256(0x81)));
        assertEq(flattened[1], bytes32(uint256(0x82)));
        assertEq(flattened[2], bytes32(uint256(0x83)));
        assertEq(fmpAfter, endOfFlattened, "fmp must sit exactly at the end of the flattened array");
    }

    /// An empty matrix must still allocate exactly the one length word.
    function testFlattenEmptyAllocatesLengthWordOnly() external pure {
        bytes32[][] memory matrix = new bytes32[][](0);

        uint256 fmpBefore = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        bytes32[] memory flattened = matrix.flatten();
        uint256 fmpAfter = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));

        assertEq(flattened.length, 0, "length");
        assertEq(fmpAfter - fmpBefore, 0x20, "exactly one length word allocated");
    }
}
