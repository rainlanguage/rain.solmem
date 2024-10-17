// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";
import {LibUint256Matrix, LibPointer, Pointer} from "src/lib/LibUint256Matrix.sol";
import {LibMemory} from "src/lib/LibMemory.sol";

import {LibUint256MatrixSlow} from "test/lib/LibUint256MatrixSlow.sol";

contract LibUint256ArrayMatrixFromTest is Test {
    using LibUint256Array for uint256;
    using LibUint256Matrix for uint256[];
    using LibUint256MatrixSlow for uint256[];
    using LibUint256Matrix for uint256[][];

    /// forge-config: default.fuzz.runs = 100
    function testMatrixFromA(uint256[] memory a) public pure {
        uint256[][] memory matrix = a.matrixFrom();
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(matrix.endPointer()));
        assertEq(Pointer.unwrap(matrix.endPointer()) - Pointer.unwrap(matrix.dataPointer()), matrix.length * 0x20);
        assertTrue(LibMemory.memoryIsAligned());
        uint256[][] memory matrixSlow = a.matrixFromSlow();
        assertTrue(LibUint256MatrixSlow.compareMatrices(matrix, matrixSlow, 1));
    }

    function testMatrixFromAGas0() public pure returns (uint256[][] memory) {
        return uint256(1).arrayFrom().matrixFrom();
    }

    function testMatrixFromAGasSlow0() public pure returns (uint256[][] memory) {
        return uint256(1).arrayFrom().matrixFromSlow();
    }

    /// forge-config: default.fuzz.runs = 100
    function testMatrixFromAB(uint256[] memory a, uint256[] memory b) public pure {
        uint256[][] memory matrix = LibUint256Matrix.matrixFrom(a, b);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(matrix.endPointer()));
        assertEq(Pointer.unwrap(matrix.endPointer()) - Pointer.unwrap(matrix.dataPointer()), matrix.length * 0x20);
        assertTrue(LibMemory.memoryIsAligned());
        uint256[][] memory matrixSlow = LibUint256MatrixSlow.matrixFromSlow(a, b);
        assertTrue(LibUint256MatrixSlow.compareMatrices(matrix, matrixSlow, 2));
    }

    function testMatrixFromABGas0() public pure returns (uint256[][] memory) {
        return LibUint256Matrix.matrixFrom(uint256(1).arrayFrom(), uint256(2).arrayFrom());
    }

    function testMatrixFromABGasSlow0() public pure returns (uint256[][] memory) {
        return LibUint256MatrixSlow.matrixFromSlow(uint256(1).arrayFrom(), uint256(2).arrayFrom());
    }

    /// forge-config: default.fuzz.runs = 100
    function testMatrixFromABC(uint256[] memory a, uint256[] memory b, uint256[] memory c) public pure {
        uint256[][] memory matrix = LibUint256Matrix.matrixFrom(a, b, c);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(matrix.endPointer()));
        assertEq(Pointer.unwrap(matrix.endPointer()) - Pointer.unwrap(matrix.dataPointer()), matrix.length * 0x20);
        assertTrue(LibMemory.memoryIsAligned());
        uint256[][] memory matrixSlow = LibUint256MatrixSlow.matrixFromSlow(a, b, c);
        assertTrue(LibUint256MatrixSlow.compareMatrices(matrix, matrixSlow, 3));
    }

    function testMatrixFromABCGas0() public pure returns (uint256[][] memory) {
        return LibUint256Matrix.matrixFrom(uint256(1).arrayFrom(), uint256(2).arrayFrom(), uint256(3).arrayFrom());
    }

    function testMatrixFromABCGasSlow0() public pure returns (uint256[][] memory) {
        return
            LibUint256MatrixSlow.matrixFromSlow(uint256(1).arrayFrom(), uint256(2).arrayFrom(), uint256(3).arrayFrom());
    }
}
