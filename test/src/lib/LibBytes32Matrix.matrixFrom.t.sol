// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {LibBytes32Matrix, LibPointer, Pointer} from "src/lib/LibBytes32Matrix.sol";

import {LibBytes32MatrixSlow} from "test/lib/LibBytes32MatrixSlow.sol";

contract LibBytes32ArrayMatrixFromTest is Test {
    using LibBytes32Array for bytes32;
    using LibBytes32Matrix for bytes32[];
    using LibBytes32MatrixSlow for bytes32[];
    using LibBytes32Matrix for bytes32[][];

    /// forge-config: default.fuzz.runs = 100
    function testMatrixFromA(bytes32[] memory a) public pure {
        bytes32[][] memory matrix = a.matrixFrom();
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(matrix.endPointer()));
        assertEq(Pointer.unwrap(matrix.endPointer()) - Pointer.unwrap(matrix.dataPointer()), matrix.length * 0x20);
        bytes32[][] memory matrixSlow = a.matrixFromSlow();
        assertTrue(LibBytes32MatrixSlow.compareMatrices(matrix, matrixSlow, 1));
    }

    function testMatrixFromAGas0() public pure returns (bytes32[][] memory) {
        return bytes32(uint256(1)).arrayFrom().matrixFrom();
    }

    function testMatrixFromAGasSlow0() public pure returns (bytes32[][] memory) {
        return bytes32(uint256(1)).arrayFrom().matrixFromSlow();
    }

    /// forge-config: default.fuzz.runs = 100
    function testMatrixFromAB(bytes32[] memory a, bytes32[] memory b) public pure {
        bytes32[][] memory matrix = LibBytes32Matrix.matrixFrom(a, b);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(matrix.endPointer()));
        assertEq(Pointer.unwrap(matrix.endPointer()) - Pointer.unwrap(matrix.dataPointer()), matrix.length * 0x20);
        bytes32[][] memory matrixSlow = LibBytes32MatrixSlow.matrixFromSlow(a, b);
        assertTrue(LibBytes32MatrixSlow.compareMatrices(matrix, matrixSlow, 2));
    }

    function testMatrixFromABGas0() public pure returns (bytes32[][] memory) {
        return LibBytes32Matrix.matrixFrom(bytes32(uint256(1)).arrayFrom(), bytes32(uint256(2)).arrayFrom());
    }

    function testMatrixFromABGasSlow0() public pure returns (bytes32[][] memory) {
        return LibBytes32MatrixSlow.matrixFromSlow(bytes32(uint256(1)).arrayFrom(), bytes32(uint256(2)).arrayFrom());
    }

    /// forge-config: default.fuzz.runs = 100
    function testMatrixFromABC(bytes32[] memory a, bytes32[] memory b, bytes32[] memory c) public pure {
        bytes32[][] memory matrix = LibBytes32Matrix.matrixFrom(a, b, c);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(matrix.endPointer()));
        assertEq(Pointer.unwrap(matrix.endPointer()) - Pointer.unwrap(matrix.dataPointer()), matrix.length * 0x20);
        bytes32[][] memory matrixSlow = LibBytes32MatrixSlow.matrixFromSlow(a, b, c);
        assertTrue(LibBytes32MatrixSlow.compareMatrices(matrix, matrixSlow, 3));
    }

    function testMatrixFromABCGas0() public pure returns (bytes32[][] memory) {
        return LibBytes32Matrix.matrixFrom(
            bytes32(uint256(1)).arrayFrom(), bytes32(uint256(2)).arrayFrom(), bytes32(uint256(3)).arrayFrom()
        );
    }

    function testMatrixFromABCGasSlow0() public pure returns (bytes32[][] memory) {
        return LibBytes32MatrixSlow.matrixFromSlow(
            bytes32(uint256(1)).arrayFrom(), bytes32(uint256(2)).arrayFrom(), bytes32(uint256(3)).arrayFrom()
        );
    }
}
