// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import "src/lib/LibMemory.sol";
import "src/lib/LibUint256Matrix.sol";

import "test/lib/LibUint256MatrixSlow.sol";

contract LibUint256MatrixPointerTest is Test {
    using LibUint256Matrix for uint256[][];
    using LibUint256Matrix for Pointer;

    function testUnsafeAsUint256MatrixRoundUint256Array(uint256[][] memory matrix) public {
        assertTrue(
            LibUint256MatrixSlow.compareMatrices(matrix, matrix.startPointer().unsafeAsUint256Matrix(), matrix.length)
        );
    }

    function testUnsafeAsUint256MatrixRound(Pointer pointer) public {
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(pointer.unsafeAsUint256Matrix().startPointer()));
    }

    function testUint256MatrixDataPointer(uint256[][] memory matrix) public {
        assertEq(Pointer.unwrap(matrix.startPointer()) + 0x20, Pointer.unwrap(matrix.dataPointer()));
    }

    function testUint256MatrixEndPointer(uint256[][] memory matrix) public {
        assertEq(Pointer.unwrap(matrix.dataPointer()) + (matrix.length * 0x20), Pointer.unwrap(matrix.endPointer()));
    }
}
