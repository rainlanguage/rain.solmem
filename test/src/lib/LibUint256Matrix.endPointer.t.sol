// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibUint256Array} from "src/lib/LibUint256Array.sol";
import {LibUint256Matrix, LibPointer, Pointer} from "src/lib/LibUint256Matrix.sol";

/// `endPointer` on a matrix is one word past the last REFERENCE, which is not
/// the end of any allocation. The NatSpec on `endPointer` states where the inner
/// arrays sit relative to that pointer and that writing there corrupts them.
/// These tests pin those claims against the real memory layout so the warning
/// cannot quietly become false.
contract LibUint256MatrixEndPointerTest is Test {
    using LibUint256Array for uint256[];
    using LibUint256Matrix for uint256[][];

    /// A matrix built with `new` allocates the pointer array first, so the inner
    /// arrays are ABOVE it and `endPointer` lands on the first of them rather
    /// than on free memory.
    function testEndPointerIsFirstInnerArrayForNewMatrix() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = new uint256[](2);
        matrix[1] = new uint256[](2);

        assertEq(
            uint256(Pointer.unwrap(matrix.endPointer())),
            uint256(Pointer.unwrap(matrix[0].startPointer())),
            "endPointer is the first inner array"
        );
    }

    /// The same layout stated as a bound rather than an exact address: the inner
    /// arrays of a `new` matrix are allocated above the pointer array, so
    /// `endPointer` is strictly below the free memory pointer by exactly the
    /// size of those arrays.
    function testEndPointerIsBelowFreeMemoryForNewMatrix() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = new uint256[](2);
        matrix[1] = new uint256[](3);
        // Read the free memory pointer before any assertion, as assertions
        // allocate.
        uint256 allocationEnd = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256 end = uint256(Pointer.unwrap(matrix.endPointer()));

        // Two inner arrays, one length word plus two items and one length word
        // plus three items.
        assertEq(allocationEnd - end, 0x20 * 7, "inner arrays live above endPointer");
    }

    /// The consequence the NatSpec warns about, performed. A single word written
    /// at `endPointer` of a `new` matrix overwrites the length word of the first
    /// inner array.
    function testWriteAtEndPointerCorruptsInnerArrayForNewMatrix() external pure {
        uint256[][] memory matrix = new uint256[][](2);
        matrix[0] = LibUint256Array.arrayFrom(0x11, 0x22);
        matrix[1] = LibUint256Array.arrayFrom(0x33, 0x44);

        assertEq(matrix[0].length, 2, "inner length before");

        Pointer end = matrix.endPointer();
        // Deliberately NOT annotated `memory-safe`. Writing here is precisely
        // the unsafe act the doc block warns about, and the annotation would be
        // a lie that lets the optimizer assume the write cannot be observed.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(end, 0xdead)
        }

        assertEq(matrix[0].length, 0xdead, "inner length corrupted");
    }

    /// A matrix built by `matrixFrom` wraps arrays that were already allocated,
    /// so its inner arrays are BELOW the pointer array. `endPointer` coincides
    /// with the free memory pointer here, which is exactly why the doc block
    /// cannot describe it as the end of the matrix's memory: the same pointer
    /// means different things for the two ways of building a matrix.
    function testInnerArraysAreBelowEndPointerForMatrixFrom() external pure {
        uint256[] memory a = LibUint256Array.arrayFrom(0x11, 0x22);
        uint256[] memory b = LibUint256Array.arrayFrom(0x33, 0x44);
        uint256[][] memory matrix = LibUint256Matrix.matrixFrom(a, b);

        uint256 allocationEnd = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256 start = uint256(Pointer.unwrap(matrix.startPointer()));
        uint256 end = uint256(Pointer.unwrap(matrix.endPointer()));

        assertLt(uint256(Pointer.unwrap(a.startPointer())), start, "a starts below the matrix");
        assertLt(uint256(Pointer.unwrap(b.startPointer())), start, "b starts below the matrix");
        assertLe(uint256(Pointer.unwrap(a.endPointer())), start, "a ends at or below the matrix");
        assertLe(uint256(Pointer.unwrap(b.endPointer())), start, "b ends at or below the matrix");
        assertEq(end, allocationEnd, "endPointer is the free memory pointer here");
    }
}
