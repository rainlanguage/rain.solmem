// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";
import {LibUint256Matrix} from "src/lib/LibUint256Matrix.sol";
import {LibPointer, Pointer} from "src/lib/LibPointer.sol";
import {LibUint256MatrixSlow} from "test/lib/LibUint256MatrixSlow.sol";

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
}
