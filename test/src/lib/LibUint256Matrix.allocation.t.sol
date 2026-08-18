// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibUint256Array} from "../../../src/lib/LibUint256Array.sol";
import {LibUint256Matrix, LibPointer, Pointer} from "../../../src/lib/LibUint256Matrix.sol";

/// The existing `flatten` tests assert the CONTENTS of the flattened array.
/// `flatten` also performs an allocation, and an over-allocating `flatten`
/// passes every content assertion while leaving the free memory pointer beyond
/// the end of the array it returned. `matrixFrom` and `arrayFrom` are already
/// pinned to `allocatedMemoryPointer()`; `flatten` was not.
contract LibUint256MatrixAllocationTest is Test {
    using LibUint256Array for uint256[];
    using LibUint256Matrix for uint256[][];

    /// forge-config: default.fuzz.runs = 100
    function testFlattenAllocatesExactly(uint256[][] memory matrix) external pure {
        uint256[] memory flattened = matrix.flatten();

        assertEq(
            Pointer.unwrap(LibPointer.allocatedMemoryPointer()),
            Pointer.unwrap(flattened.endPointer()),
            "fmp must sit exactly at the end of the flattened array"
        );
    }

    /// Concrete non-fuzzed case: a matrix of two non-empty arrays.
    function testFlattenAllocatesExactlyConcrete() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = LibUint256Array.arrayFrom(0x81, 0x82);
        matrix[1] = LibUint256Array.arrayFrom(0x83);

        uint256[] memory flattened = matrix.flatten();
        // Read the free memory pointer BEFORE any assertion, because assertions
        // allocate and would move it.
        uint256 fmpAfter = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256 endOfFlattened = uint256(Pointer.unwrap(flattened.endPointer()));

        assertEq(flattened.length, 3, "length");
        assertEq(flattened[0], 0x81);
        assertEq(flattened[1], 0x82);
        assertEq(flattened[2], 0x83);
        assertEq(fmpAfter, endOfFlattened, "fmp must sit exactly at the end of the flattened array");
    }

    /// An empty matrix must still allocate exactly the one length word.
    function testFlattenEmptyAllocatesLengthWordOnly() external pure {
        uint256[][] memory matrix = new uint256[][](0);

        uint256 fmpBefore = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256[] memory flattened = matrix.flatten();
        uint256 fmpAfter = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));

        assertEq(flattened.length, 0, "length");
        assertEq(fmpAfter - fmpBefore, 0x20, "exactly one length word allocated");
    }
}
