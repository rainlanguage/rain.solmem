// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Pointer} from "./LibPointer.sol";
import {LibBytes32Array} from "./LibBytes32Array.sol";
// `truncate` still reverts with `OutOfBoundsTruncate`, raised inside
// `LibBytes32Array`. The import is kept so that the symbol remains reachable
// from this file for downstream code that imports it from here, exactly as it
// was before this library was made a wrapper.
// forge-lint: disable-next-line(unused-import)
import {OutOfBoundsTruncate} from "../error/ErrTruncate.sol";

/// @title LibUint256Array
/// @notice The numeric view over `LibBytes32Array`.
///
/// `uint256[]` and `bytes32[]` are the same structure in memory: a length word
/// followed by full width, 32 byte aligned items. Neither type has a cleanup
/// obligation on its items, because neither has any bits in a word that are not
/// its own. Relabelling one as the other is therefore a no-op on memory, and
/// the two libraries can share a single implementation instead of being kept in
/// sync by hand.
///
/// `LibBytes32Array` holds that implementation and every function here
/// delegates to it, so the behavioural contract, the safety obligations on the
/// caller and the revert conditions are all defined there. This file adds
/// nothing but the relabel: read `LibBytes32Array` for what these functions
/// actually do.
///
/// All of it is `internal`, so there is no call boundary between the two
/// libraries and the optimiser inlines the whole chain into the caller.
library LibUint256Array {
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

    /// Pointer to the start (length prefix) of a `uint256[]`.
    /// See `LibBytes32Array.startPointer`.
    /// @param array The array to get the start pointer of.
    /// @return pointer The pointer to the start of `array`.
    function startPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        return LibBytes32Array.startPointer(asBytes32Array(array));
    }

    /// Pointer to the data of a `uint256[]` NOT the length prefix.
    /// See `LibBytes32Array.dataPointer`.
    /// @param array The array to get the data pointer of.
    /// @return pointer The pointer to the data of `array`.
    function dataPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        return LibBytes32Array.dataPointer(asBytes32Array(array));
    }

    /// Pointer to the end of the data of an array, i.e. one word past its last
    /// item. See `LibBytes32Array.endPointer` for what this does and does not
    /// bound after a `truncate`.
    /// @param array The array to get the end pointer of.
    /// @return pointer The pointer to the end of the data of `array`.
    function endPointer(uint256[] memory array) internal pure returns (Pointer pointer) {
        return LibBytes32Array.endPointer(asBytes32Array(array));
    }

    /// Cast a `Pointer` to `uint256[]` without modification or safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `uint256[]`. See `LibBytes32Array.unsafeAsBytes32Array`.
    /// @param pointer The pointer to cast to `uint256[]`.
    /// @return array The cast `uint256[]`.
    function unsafeAsUint256Array(Pointer pointer) internal pure returns (uint256[] memory array) {
        return asUint256Array(LibBytes32Array.unsafeAsBytes32Array(pointer));
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a A single integer to build an array around.
    /// @return array The newly allocated array including `a` as a single item.
    function arrayFrom(uint256 a) internal pure returns (uint256[] memory array) {
        return asUint256Array(LibBytes32Array.arrayFrom(bytes32(a)));
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @return array The newly allocated array including `a` and `b` as the only
    /// items.
    function arrayFrom(uint256 a, uint256 b) internal pure returns (uint256[] memory array) {
        return asUint256Array(LibBytes32Array.arrayFrom(bytes32(a), bytes32(b)));
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @return array The newly allocated array including `a`, `b` and `c` as the
    /// only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c) internal pure returns (uint256[] memory array) {
        return asUint256Array(LibBytes32Array.arrayFrom(bytes32(a), bytes32(b), bytes32(c)));
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c` and `d` as the
    /// only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256[] memory array) {
        return asUint256Array(LibBytes32Array.arrayFrom(bytes32(a), bytes32(b), bytes32(c), bytes32(d)));
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @param e The fifth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d` and
    /// `e` as the only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e)
        internal
        pure
        returns (uint256[] memory array)
    {
        return asUint256Array(LibBytes32Array.arrayFrom(bytes32(a), bytes32(b), bytes32(c), bytes32(d), bytes32(e)));
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @param e The fifth integer to build an array around.
    /// @param f The sixth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d`, `e`
    /// and `f` as the only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f)
        internal
        pure
        returns (uint256[] memory array)
    {
        return asUint256Array(
            LibBytes32Array.arrayFrom(bytes32(a), bytes32(b), bytes32(c), bytes32(d), bytes32(e), bytes32(f))
        );
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @param e The fifth integer to build an array around.
    /// @param f The sixth integer to build an array around.
    /// @param g The seventh integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d`, `e`,
    /// `f` and `g` as the only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f, uint256 g)
        internal
        pure
        returns (uint256[] memory array)
    {
        return asUint256Array(
            LibBytes32Array.arrayFrom(
                bytes32(a), bytes32(b), bytes32(c), bytes32(d), bytes32(e), bytes32(f), bytes32(g)
            )
        );
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first integer to build an array around.
    /// @param b The second integer to build an array around.
    /// @param c The third integer to build an array around.
    /// @param d The fourth integer to build an array around.
    /// @param e The fifth integer to build an array around.
    /// @param f The sixth integer to build an array around.
    /// @param g The seventh integer to build an array around.
    /// @param h The eighth integer to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d`, `e`,
    /// `f`, `g` and `h` as the only items.
    function arrayFrom(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f, uint256 g, uint256 h)
        internal
        pure
        returns (uint256[] memory array)
    {
        return asUint256Array(
            LibBytes32Array.arrayFrom(
                bytes32(a), bytes32(b), bytes32(c), bytes32(d), bytes32(e), bytes32(f), bytes32(g), bytes32(h)
            )
        );
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The head of the new array.
    /// @param tail The tail of the new array.
    /// @return array The new array.
    function arrayFrom(uint256 a, uint256[] memory tail) internal pure returns (uint256[] memory array) {
        return asUint256Array(LibBytes32Array.arrayFrom(bytes32(a), asBytes32Array(tail)));
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first item of the new array.
    /// @param b The second item of the new array.
    /// @param tail The tail of the new array.
    /// @return array The new array.
    function arrayFrom(uint256 a, uint256 b, uint256[] memory tail) internal pure returns (uint256[] memory array) {
        return asUint256Array(LibBytes32Array.arrayFrom(bytes32(a), bytes32(b), asBytes32Array(tail)));
    }

    /// Shrinks an array by mutating its length word directly. The truncated
    /// items are leaked, i.e. they become inaccessible regions of memory that
    /// are never deallocated.
    /// Reverts with `OutOfBoundsTruncate(array.length, newLength)` if
    /// `newLength` is greater than `array.length`. Truncation can only shrink.
    /// See `LibBytes32Array.truncate`.
    /// @param array The array to truncate. MUTATED in place, so there is no
    /// return value and no new allocation.
    /// @param newLength The new length of `array` after truncation. MUST NOT
    /// be greater than `array.length`.
    function truncate(uint256[] memory array, uint256 newLength) internal pure {
        LibBytes32Array.truncate(asBytes32Array(array), newLength);
    }

    /// Extends `baseArray` with `extendArray`, allocating only when it must.
    ///
    /// This function is UNSAFE because the base array IS MUTATED DIRECTLY by
    /// some code paths AND THE FINAL RETURN ARRAY MAY POINT TO THE SAME REGION
    /// OF MEMORY. THE CALLER MUST NOT USE THE BASE ARRAY AND MUST USE THE
    /// RETURNED ARRAY ONLY. See `LibBytes32Array.unsafeExtend` for the full
    /// contract, including which shapes always allocate and why.
    ///
    /// Both arrays MUST be valid solidity memory arrays, each owning the region
    /// its own length word describes.
    ///
    /// @param baseArray The base array that will be extended by `extendArray`.
    /// @param extendArray The extend array that extends `baseArray`.
    /// @return extended `baseArray` extended by `extendArray`.
    function unsafeExtend(uint256[] memory baseArray, uint256[] memory extendArray)
        internal
        pure
        returns (uint256[] memory extended)
    {
        return asUint256Array(LibBytes32Array.unsafeExtend(asBytes32Array(baseArray), asBytes32Array(extendArray)));
    }

    /// Reverse an array in place. This is a destructive operation that MUTATES
    /// the array in place. There is no return value.
    /// See `LibBytes32Array.reverse`.
    /// @param array The array to reverse.
    function reverse(uint256[] memory array) internal pure {
        LibBytes32Array.reverse(asBytes32Array(array));
    }
}
