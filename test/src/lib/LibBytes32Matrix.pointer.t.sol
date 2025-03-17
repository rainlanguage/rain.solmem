// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibBytes32Matrix, Pointer} from "src/lib/LibBytes32Matrix.sol";

import {LibBytes32MatrixSlow} from "test/lib/LibBytes32MatrixSlow.sol";

contract LibBytes32MatrixPointerTest is Test {
    using LibBytes32Matrix for bytes32[][];
    using LibBytes32Matrix for Pointer;

    /// forge-config: default.fuzz.runs = 100
    function testUnsafeAsBytes32MatrixRoundUint256Array(bytes32[][] memory matrix) public pure {
        assertTrue(
            LibBytes32MatrixSlow.compareMatrices(matrix, matrix.startPointer().unsafeAsBytes32Matrix(), matrix.length)
        );
    }

    function testUnsafeAsBytes32MatrixRound(Pointer pointer) public pure {
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(pointer.unsafeAsBytes32Matrix().startPointer()));
    }

    /// forge-config: default.fuzz.runs = 100
    function testBytes32MatrixDataPointer(bytes32[][] memory matrix) public pure {
        assertEq(Pointer.unwrap(matrix.startPointer()) + 0x20, Pointer.unwrap(matrix.dataPointer()));
    }

    /// forge-config: default.fuzz.runs = 100
    function testBytes32MatrixEndPointer(bytes32[][] memory matrix) public pure {
        assertEq(Pointer.unwrap(matrix.dataPointer()) + (matrix.length * 0x20), Pointer.unwrap(matrix.endPointer()));
    }
}
