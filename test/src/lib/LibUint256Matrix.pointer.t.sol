// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibUint256Matrix, Pointer} from "src/lib/LibUint256Matrix.sol";

import {LibUint256MatrixSlow} from "test/lib/LibUint256MatrixSlow.sol";

contract LibUint256MatrixPointerTest is Test {
    using LibUint256Matrix for uint256[][];
    using LibUint256Matrix for Pointer;

    /// forge-config: default.fuzz.runs = 100
    function testUnsafeAsUint256MatrixRoundUint256Array(uint256[][] memory matrix) public pure {
        assertTrue(
            LibUint256MatrixSlow.compareMatrices(matrix, matrix.startPointer().unsafeAsUint256Matrix(), matrix.length)
        );
    }

    function testUnsafeAsUint256MatrixRound(Pointer pointer) public pure {
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(pointer.unsafeAsUint256Matrix().startPointer()));
    }

    /// forge-config: default.fuzz.runs = 100
    function testUint256MatrixDataPointer(uint256[][] memory matrix) public pure {
        assertEq(Pointer.unwrap(matrix.startPointer()) + 0x20, Pointer.unwrap(matrix.dataPointer()));
    }

    /// forge-config: default.fuzz.runs = 100
    function testUint256MatrixEndPointer(uint256[][] memory matrix) public pure {
        assertEq(Pointer.unwrap(matrix.dataPointer()) + (matrix.length * 0x20), Pointer.unwrap(matrix.endPointer()));
    }
}
