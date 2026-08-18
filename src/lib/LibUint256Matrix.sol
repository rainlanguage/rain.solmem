// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

// keeping this import here so downstream code can get LibPointer easily.
// forge-lint: disable-next-line(unused-import)
import {Pointer, LibPointer} from "./LibPointer.sol";
import {LibBytes32Matrix} from "./LibBytes32Matrix.sol";

/// @title LibUint256Matrix
/// @notice The numeric view over `LibBytes32Matrix`.
///
/// `uint256[][]` and `bytes32[][]` are the same structure in memory: a length
/// word followed by full width pointers to the sub arrays, which are themselves
/// the same structure for both element types. Relabelling one as the other is
/// therefore a no-op on memory, and the two libraries can share a single
/// implementation instead of being kept in sync by hand.
///
/// `LibBytes32Matrix` holds that implementation and every function here
/// delegates to it, so the behavioural contract, the safety obligations on the
/// caller and the revert conditions are all defined there. This file adds
/// nothing but the relabel: read `LibBytes32Matrix` for what these functions
/// actually do.
///
/// All of it is `internal`, so there is no call boundary between the two
/// libraries and the optimiser inlines the whole chain into the caller.
library LibUint256Matrix {
    /// Relabel a `uint256[]` as a `bytes32[]`. Same bits, same layout, no work.
    /// @param array The array to relabel.
    /// @return relabelled The same memory, typed as `bytes32[]`.
    function asBytes32Array(uint256[] memory array) private pure returns (bytes32[] memory relabelled) {
        assembly ("memory-safe") {
            relabelled := array
        }
    }

    /// Relabel a `bytes32[]` as a `uint256[]`. Same bits, same layout, no work.
    /// @param array The array to relabel.
    /// @return relabelled The same memory, typed as `uint256[]`.
    function asUint256Array(bytes32[] memory array) private pure returns (uint256[] memory relabelled) {
        assembly ("memory-safe") {
            relabelled := array
        }
    }

    /// Relabel a `uint256[][]` as a `bytes32[][]`. Same bits, same layout, no
    /// work.
    /// @param matrix The matrix to relabel.
    /// @return relabelled The same memory, typed as `bytes32[][]`.
    function asBytes32Matrix(uint256[][] memory matrix) private pure returns (bytes32[][] memory relabelled) {
        assembly ("memory-safe") {
            relabelled := matrix
        }
    }

    /// Relabel a `bytes32[][]` as a `uint256[][]`. Same bits, same layout, no
    /// work.
    /// @param matrix The matrix to relabel.
    /// @return relabelled The same memory, typed as `uint256[][]`.
    function asUint256Matrix(bytes32[][] memory matrix) private pure returns (uint256[][] memory relabelled) {
        assembly ("memory-safe") {
            relabelled := matrix
        }
    }

    /// Pointer to the start (length prefix) of a `uint256[][]`.
    /// See `LibBytes32Matrix.startPointer`.
    /// @param matrix The matrix to get the start pointer of.
    /// @return pointer The pointer to the start of `matrix`.
    function startPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        return LibBytes32Matrix.startPointer(asBytes32Matrix(matrix));
    }

    /// Pointer to the data of a `uint256[][]` NOT the length prefix.
    /// Note that the data of a `uint256[][]` is _references_ to the `uint256[]`
    /// start pointers and does NOT include the arrays themselves.
    /// See `LibBytes32Matrix.dataPointer`.
    /// @param matrix The matrix to get the data pointer of.
    /// @return pointer The pointer to the data of `matrix`.
    function dataPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        return LibBytes32Matrix.dataPointer(asBytes32Matrix(matrix));
    }

    /// Pointer to one word past the last `uint256[]` REFERENCE in a matrix,
    /// i.e. the end of the matrix's pointer array.
    ///
    /// This is NOT the end of the memory allocated for the matrix, and writing
    /// at it can corrupt the matrix. See `LibBytes32Matrix.endPointer` for why.
    /// @param matrix The matrix to get the end pointer of.
    /// @return pointer The pointer one word past the last reference in `matrix`.
    function endPointer(uint256[][] memory matrix) internal pure returns (Pointer pointer) {
        return LibBytes32Matrix.endPointer(asBytes32Matrix(matrix));
    }

    /// Cast a `Pointer` to `uint256[][]` without modification or safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `uint256[][]`. See `LibBytes32Matrix.unsafeAsBytes32Matrix`.
    /// @param pointer The pointer to cast to `uint256[][]`.
    /// @return matrix The cast `uint256[][]`.
    function unsafeAsUint256Matrix(Pointer pointer) internal pure returns (uint256[][] memory matrix) {
        return asUint256Matrix(LibBytes32Matrix.unsafeAsBytes32Matrix(pointer));
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes a 1-dimensional array and
    /// coerces it to a 2-dimensional matrix where the first and only item in the
    /// matrix is the 1-dimensional array.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a`.
    function matrixFrom(uint256[] memory a) internal pure returns (uint256[][] memory matrix) {
        return asUint256Matrix(LibBytes32Matrix.matrixFrom(asBytes32Array(a)));
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes 1-dimensional arrays and
    /// coerces them to a 2-dimensional matrix where items in the matrix are the
    /// 1-dimensional arrays.
    /// @param a The 1-dimensional array to include in the matrix.
    /// @param b Second 1-dimensional array to include in the matrix.
    /// @return matrix The 2-dimensional matrix containing `a` and `b`.
    function matrixFrom(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[][] memory matrix) {
        return asUint256Matrix(LibBytes32Matrix.matrixFrom(asBytes32Array(a), asBytes32Array(b)));
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
        return asUint256Matrix(LibBytes32Matrix.matrixFrom(asBytes32Array(a), asBytes32Array(b), asBytes32Array(c)));
    }

    /// Counts the total number of items in the matrix across all internal
    /// arrays. Normally `matrix.length` only returns the number of internal
    /// arrays, not the total number of items in the matrix.
    ///
    /// Reverts with an arithmetic panic on overflow of the running total.
    /// See `LibBytes32Matrix.itemCount`.
    /// @param matrix The matrix to count the items of.
    /// @return count The total number of items across every sub array.
    function itemCount(uint256[][] memory matrix) internal pure returns (uint256 count) {
        return LibBytes32Matrix.itemCount(asBytes32Matrix(matrix));
    }

    /// Allocates and builds a new `uint256[]` from a `uint256[][]`. This is
    /// potentially memory intensive and expensive, but there's no way around
    /// the allocation if a flat array is needed.
    ///
    /// Reverts with an arithmetic panic if the total item count cannot be
    /// scaled to a size in bytes. See `LibBytes32Matrix.flatten`.
    /// @param matrix The matrix to flatten.
    /// @return The flattened array.
    function flatten(uint256[][] memory matrix) internal pure returns (uint256[] memory) {
        return asUint256Array(LibBytes32Matrix.flatten(asBytes32Matrix(matrix)));
    }
}
