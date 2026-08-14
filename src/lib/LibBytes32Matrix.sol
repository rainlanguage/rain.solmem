// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

// keeping this import here so downstream code can get LibPointer easily.
// forge-lint: disable-next-line(unused-import)
import {Pointer, LibPointer} from "./LibPointer.sol";

library LibBytes32Matrix {
    /// Pointer to the start (length prefix) of a `bytes32[][]`.
    /// @param matrix The matrix to get the start pointer of.
    /// @return pointer The pointer to the start of `matrix`.
    function startPointer(bytes32[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := matrix
        }
    }

    /// Pointer to the data of a `bytes32[][]` NOT the length prefix.
    /// Note that the data of a `bytes32[][]` is _references_ to the `bytes32[]`
    /// start pointers and does NOT include the arrays themselves.
    /// @param matrix The matrix to get the data pointer of.
    /// @return pointer The pointer to the data of `matrix`.
    function dataPointer(bytes32[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(matrix, 0x20)
        }
    }

    /// Pointer to the end of the allocated memory of a matrix.
    /// Note that the data of a `bytes32[][]` is _references_ to the `bytes32[]`
    /// start pointers and does NOT include the arrays themselves.
    /// @param matrix The matrix to get the end pointer of.
    /// @return pointer The pointer to the end of `matrix`.
    function endPointer(bytes32[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(matrix, add(0x20, mul(0x20, mload(matrix))))
        }
    }

    /// Cast a `Pointer` to `bytes32[][]` without modification or safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `bytes32[][]`.
    /// @param pointer The pointer to cast to `bytes32[][]`.
    /// @return matrix The cast `bytes32[][]`.
    function unsafeAsBytes32Matrix(Pointer pointer) internal pure returns (bytes32[][] memory matrix) {
        assembly ("memory-safe") {
            matrix := pointer
        }
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes a 1-dimensional array and
    /// coerces it to a 2-dimensional matrix where the first and only item in the
    /// matrix is the 1-dimensional array.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a`.
    function matrixFrom(bytes32[] memory a) internal pure returns (bytes32[][] memory matrix) {
        assembly ("memory-safe") {
            matrix := mload(0x40)
            mstore(matrix, 1)
            mstore(add(matrix, 0x20), a)
            mstore(0x40, add(matrix, 0x40))
        }
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes 1-dimensional arrays and
    /// coerces them to a 2-dimensional matrix where items in the matrix are the
    /// 1-dimensional arrays.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @param b Second 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a` and `b`.
    function matrixFrom(bytes32[] memory a, bytes32[] memory b) internal pure returns (bytes32[][] memory matrix) {
        assembly ("memory-safe") {
            matrix := mload(0x40)
            mstore(matrix, 2)
            mstore(add(matrix, 0x20), a)
            mstore(add(matrix, 0x40), b)
            mstore(0x40, add(matrix, 0x60))
        }
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes 1-dimensional arrays and
    /// coerces them to a 2-dimensional matrix where items in the matrix are the
    /// 1-dimensional arrays.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @param b Second 1-dimensional array to include in the matrix.
    /// @param c Third 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a`, `b` and `c`.
    function matrixFrom(bytes32[] memory a, bytes32[] memory b, bytes32[] memory c)
        internal
        pure
        returns (bytes32[][] memory matrix)
    {
        assembly ("memory-safe") {
            matrix := mload(0x40)
            mstore(matrix, 3)
            mstore(add(matrix, 0x20), a)
            mstore(add(matrix, 0x40), b)
            mstore(add(matrix, 0x60), c)
            mstore(0x40, add(matrix, 0x80))
        }
    }

    /// Counts the total number of items in the matrix across all internal
    /// arrays. Normally `matrix.length` only returns the number of internal
    /// arrays, not the total number of items in the matrix.
    ///
    /// The running total is guarded against overflow, so a matrix whose sub
    /// array length words sum to more than `type(uint256).max` reverts with an
    /// arithmetic panic instead of wrapping to a total that is smaller than one
    /// of the sub arrays it is totalling. That is only reachable for length
    /// words that do not describe real allocations, as every real item costs 32
    /// bytes of memory.
    /// @param matrix The matrix to count the items of.
    /// @return count The total number of items across every sub array.
    function itemCount(bytes32[][] memory matrix) internal pure returns (uint256 count) {
        assembly ("memory-safe") {
            let cursor := add(matrix, 0x20)
            let end := add(cursor, mul(mload(matrix), 0x20))

            for {} lt(cursor, end) {} {
                let subCount := mload(mload(cursor))
                count := add(count, subCount)
                // A total that is smaller than the part just added to it
                // wrapped. Revert with `Panic(uint256)` code 0x11, byte for
                // byte what checked Solidity arithmetic produces for an
                // overflow. Memory 0x00 to 0x40 is scratch space, so writing
                // the revert data there is memory safe.
                if lt(count, subCount) {
                    mstore(0x00, 0x4e487b71)
                    mstore(0x20, 0x11)
                    revert(0x1c, 0x24)
                }
                cursor := add(cursor, 0x20)
            }
        }
    }

    /// Allocates and builds a new `bytes32[]` from a `bytes32[][]`. This is
    /// potentially memory intensive and expensive, but there's no way around
    /// the allocation if a flat array is needed. This is because 2-dimensional
    /// arrays are stored as a length-prefixed array of pointers to 1-dimensional
    /// arrays, not as a contiguous block of memory.
    ///
    /// The item count is scaled to a size in bytes with checked arithmetic, so
    /// a matrix whose total item count cannot be scaled reverts with an
    /// arithmetic panic. A scaling that wrapped would size the allocation from
    /// one number while the length word stamped on the result is another,
    /// handing back an ordinary `bytes32[]` whose declared length far exceeds
    /// the memory reserved for it. Solidity's own bounds check trusts that
    /// length word, so such an array is a read and write primitive over the
    /// rest of memory.
    ///
    /// The per sub array scaling in the copy loop needs no guard of its own.
    /// The checked scaling above bounds the total at `type(uint256).max /
    /// 0x20`, and no sub array can declare more items than the total it was
    /// summed into, so scaling a sub array length cannot wrap either.
    /// @param matrix The matrix to flatten.
    /// @return array The flattened array.
    function flatten(bytes32[][] memory matrix) internal pure returns (bytes32[] memory) {
        uint256 length = itemCount(matrix);
        uint256 dataSize = length * 0x20;

        bytes32[] memory array;
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(0x40, add(array, add(0x20, dataSize)))
            mstore(array, length)

            let cursor := add(matrix, 0x20)
            let end := add(cursor, mul(mload(matrix), 0x20))

            let arrayCursor := add(array, 0x20)
            for {} lt(cursor, end) {} {
                let size := mul(mload(mload(cursor)), 0x20)
                mcopy(arrayCursor, add(mload(cursor), 0x20), size)
                arrayCursor := add(arrayCursor, size)
                cursor := add(cursor, 0x20)
            }
        }
        return array;
    }
}
