// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibPointer.sol";

library LibUint256Matrix {
    /// Pointer to the start (length prefix) of a `uint256[][]`.
    /// @param matrix The matrix to get the start pointer of.
    /// @return pointer The pointer to the start of `matrix`.
    function startPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := matrix
        }
    }

    /// Pointer to the data of a `uint256[][]` NOT the length prefix.
    /// Note that the data of a `uint256[][]` is _references_ to the `uint256[]`
    /// start pointers and does NOT include the arrays themselves.
    /// @param matrix The matrix to get the data pointer of.
    /// @return pointer The pointer to the data of `matrix`.
    function dataPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(matrix, 0x20)
        }
    }

    /// Pointer to the end of the allocated memory of a matrix.
    /// Note that the data of a `uint256[][]` is _references_ to the `uint256[]`
    /// start pointers and does NOT include the arrays themselves.
    /// @param matrix The matrix to get the end pointer of.
    /// @return pointer The pointer to the end of `matrix`.
    function endPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(matrix, add(0x20, mul(0x20, mload(matrix))))
        }
    }

    /// Cast a `Pointer` to `uint256[][]` without modification or safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `uint256[][]`.
    /// @param pointer The pointer to cast to `uint256[][]`.
    /// @return matrix The cast `uint256[][]`.
    function unsafeAsUint256Matrix(Pointer pointer) internal pure returns (uint256[][] memory matrix) {
        assembly ("memory-safe") {
            matrix := pointer
        }
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes a 1-dimensional array and
    /// coerces it to a 2-dimensional matrix where the first and only item in the
    /// matrix is the 1-dimensional array.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a`.
    function matrixFrom(uint256[] memory a) internal pure returns (uint256[][] memory matrix) {
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
    function matrixFrom(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[][] memory matrix) {
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
    function matrixFrom(uint256[] memory a, uint256[] memory b, uint256[] memory c)
        internal
        pure
        returns (uint256[][] memory matrix)
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

    /// Allocates and builds a new `uint256[]` from a `uint256[][]`. This is
    /// potentially memory intensive and expensive, but there's no way around
    /// the allocation if a flat array is needed. This is because 2-dimensional
    /// arrays are stored as a length-prefixed array of pointers to 1-dimensional
    /// arrays, not as a contiguous block of memory.
    /// @param matrix The matrix to flatten.
    /// @return array The flattened array.
    function flatten(uint256[][] memory matrix) internal pure returns (uint256[] memory) {
        uint256[] memory array;
        assembly ("memory-safe") {
            let length := 0
            let cursor := add(matrix, 0x20)
            let end := add(cursor, mul(mload(matrix), 0x20))

            for {} lt(cursor, end) {} {
                length := add(length, mload(mload(cursor)))
                cursor := add(cursor, 0x20)
            }

            array := mload(0x40)
            mstore(0x40, add(array, add(0x20, mul(length, 0x20))))
            mstore(array, length)

            cursor := add(matrix, 0x20)
            let arrayCursor := add(array, 0x20)
            for {} lt(cursor, end) {} {
                let itemCursor := add(mload(cursor), 0x20)
                let itemEnd := add(itemCursor, mul(mload(mload(cursor)), 0x20))
                for {} lt(itemCursor, itemEnd) {} {
                    mstore(arrayCursor, mload(itemCursor))
                    arrayCursor := add(arrayCursor, 0x20)
                    itemCursor := add(itemCursor, 0x20)
                }
                cursor := add(cursor, 0x20)
            }
        }
        return array;
    }
}
