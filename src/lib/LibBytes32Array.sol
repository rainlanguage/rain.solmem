// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Pointer} from "./LibPointer.sol";
import {OutOfBoundsTruncate} from "../error/ErrTruncate.sol";

/// @title Bytes32Array
/// @notice Things we want to do carefully and efficiently with bytes32 arrays
/// that Solidity doesn't give us native tools for.
library LibBytes32Array {
    /// Pointer to the start (length prefix) of a `bytes32[]`.
    /// @param array The array to get the start pointer of.
    /// @return pointer The pointer to the start of `array`.
    function startPointer(bytes32[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := array
        }
    }

    /// Pointer to the data of a `bytes32[]` NOT the length prefix.
    /// @param array The array to get the data pointer of.
    /// @return pointer The pointer to the data of `array`.
    function dataPointer(bytes32[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(array, 0x20)
        }
    }

    /// Pointer to the end of the data of an array, i.e. one word past its last
    /// item.
    ///
    /// This is derived from the CURRENT length word, so it is the end of the
    /// allocated region only for an array that has not been shrunk. `truncate`
    /// mutates the length word and leaks the tail, so after a truncation the
    /// allocation extends beyond this pointer.
    /// @param array The array to get the end pointer of.
    /// @return pointer The pointer to the end of the data of `array`.
    function endPointer(bytes32[] memory array) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(array, add(0x20, mul(0x20, mload(array))))
        }
    }

    /// Cast a `Pointer` to `bytes32[]` without modification or safety checks.
    /// The caller MUST ensure the pointer is to a valid region of memory for
    /// some `bytes32[]`.
    /// @param pointer The pointer to cast to `bytes32[]`.
    /// @return array The cast `bytes32[]`.
    function unsafeAsBytes32Array(Pointer pointer) internal pure returns (bytes32[] memory array) {
        assembly ("memory-safe") {
            array := pointer
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a A single value to build an array around.
    /// @return array The newly allocated array including `a` as a single item.
    function arrayFrom(bytes32 a) internal pure returns (bytes32[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 1)
            mstore(add(array, 0x20), a)
            mstore(0x40, add(array, 0x40))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first value to build an array around.
    /// @param b The second value to build an array around.
    /// @return array The newly allocated array including `a` and `b` as the only
    /// items.
    function arrayFrom(bytes32 a, bytes32 b) internal pure returns (bytes32[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 2)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(0x40, add(array, 0x60))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first value to build an array around.
    /// @param b The second value to build an array around.
    /// @param c The third value to build an array around.
    /// @return array The newly allocated array including `a`, `b` and `c` as the
    /// only items.
    function arrayFrom(bytes32 a, bytes32 b, bytes32 c) internal pure returns (bytes32[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 3)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(0x40, add(array, 0x80))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first value to build an array around.
    /// @param b The second value to build an array around.
    /// @param c The third value to build an array around.
    /// @param d The fourth value to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c` and `d` as the
    /// only items.
    function arrayFrom(bytes32 a, bytes32 b, bytes32 c, bytes32 d) internal pure returns (bytes32[] memory array) {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 4)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(0x40, add(array, 0xA0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first value to build an array around.
    /// @param b The second value to build an array around.
    /// @param c The third value to build an array around.
    /// @param d The fourth value to build an array around.
    /// @param e The fifth value to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d` and
    /// `e` as the only items.
    function arrayFrom(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e)
        internal
        pure
        returns (bytes32[] memory array)
    {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 5)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(add(array, 0xA0), e)
            mstore(0x40, add(array, 0xC0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first value to build an array around.
    /// @param b The second value to build an array around.
    /// @param c The third value to build an array around.
    /// @param d The fourth value to build an array around.
    /// @param e The fifth value to build an array around.
    /// @param f The sixth value to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d`, `e`
    /// and `f` as the only items.
    function arrayFrom(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e, bytes32 f)
        internal
        pure
        returns (bytes32[] memory array)
    {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 6)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(add(array, 0xA0), e)
            mstore(add(array, 0xC0), f)
            mstore(0x40, add(array, 0xE0))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first value to build an array around.
    /// @param b The second value to build an array around.
    /// @param c The third value to build an array around.
    /// @param d The fourth value to build an array around.
    /// @param e The fifth value to build an array around.
    /// @param f The sixth value to build an array around.
    /// @param g The seventh value to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d`, `e`,
    /// `f` and `g` as the only items.
    function arrayFrom(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e, bytes32 f, bytes32 g)
        internal
        pure
        returns (bytes32[] memory array)
    {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 7)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(add(array, 0xA0), e)
            mstore(add(array, 0xC0), f)
            mstore(add(array, 0xE0), g)
            mstore(0x40, add(array, 0x100))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first value to build an array around.
    /// @param b The second value to build an array around.
    /// @param c The third value to build an array around.
    /// @param d The fourth value to build an array around.
    /// @param e The fifth value to build an array around.
    /// @param f The sixth value to build an array around.
    /// @param g The seventh value to build an array around.
    /// @param h The eighth value to build an array around.
    /// @return array The newly allocated array including `a`, `b`, `c`, `d`, `e`,
    /// `f`, `g` and `h` as the only items.
    function arrayFrom(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e, bytes32 f, bytes32 g, bytes32 h)
        internal
        pure
        returns (bytes32[] memory array)
    {
        assembly ("memory-safe") {
            array := mload(0x40)
            mstore(array, 8)
            mstore(add(array, 0x20), a)
            mstore(add(array, 0x40), b)
            mstore(add(array, 0x60), c)
            mstore(add(array, 0x80), d)
            mstore(add(array, 0xA0), e)
            mstore(add(array, 0xC0), f)
            mstore(add(array, 0xE0), g)
            mstore(add(array, 0x100), h)
            mstore(0x40, add(array, 0x120))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The head of the new array.
    /// @param tail The tail of the new array.
    /// @return array The new array.
    function arrayFrom(bytes32 a, bytes32[] memory tail) internal pure returns (bytes32[] memory array) {
        assembly ("memory-safe") {
            // Read the tail length ONCE, before anything is written into the
            // output region. The output is allocated at the free memory
            // pointer, so a tail at or above it overlaps the output and the
            // writes below can land on the tail's own length word. Reading the
            // length again after that would size the copy from a word the
            // function itself just wrote, running it past the free memory
            // pointer.
            let tailLength := mload(tail)
            let length := add(tailLength, 1)
            let outputCursor := mload(0x40)
            array := outputCursor
            let outputEnd := add(outputCursor, add(0x20, mul(length, 0x20)))
            mstore(0x40, outputEnd)

            mstore(outputCursor, length)
            mstore(add(outputCursor, 0x20), a)

            mcopy(add(outputCursor, 0x40), add(tail, 0x20), mul(tailLength, 0x20))
        }
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a The first item of the new array.
    /// @param b The second item of the new array.
    /// @param tail The tail of the new array.
    /// @return array The new array.
    function arrayFrom(bytes32 a, bytes32 b, bytes32[] memory tail) internal pure returns (bytes32[] memory array) {
        assembly ("memory-safe") {
            // Read the tail length ONCE, before anything is written into the
            // output region. The output is allocated at the free memory
            // pointer, so a tail at or above it overlaps the output and the
            // writes below can land on the tail's own length word. Reading the
            // length again after that would size the copy from a word the
            // function itself just wrote, running it past the free memory
            // pointer.
            let tailLength := mload(tail)
            let length := add(tailLength, 2)
            let outputCursor := mload(0x40)
            array := outputCursor
            let outputEnd := add(outputCursor, add(0x20, mul(length, 0x20)))
            mstore(0x40, outputEnd)

            mstore(outputCursor, length)
            mstore(add(outputCursor, 0x20), a)
            mstore(add(outputCursor, 0x40), b)

            mcopy(add(outputCursor, 0x60), add(tail, 0x20), mul(tailLength, 0x20))
        }
    }

    /// Solidity provides no way to change the length of in-memory arrays but
    /// it also does not deallocate memory ever. It is always safe to shrink an
    /// array that has already been allocated, with the caveat that the
    /// truncated items will effectively become inaccessible regions of memory.
    /// That is to say, we deliberately "leak" the truncated items, but that is
    /// no worse than Solidity's native behaviour of leaking everything always.
    /// The array is MUTATED in place so there is no return value and there is
    /// no new allocation or copying of data either.
    /// @param array The array to truncate.
    /// @param newLength The new length of the array after truncation.
    function truncate(bytes32[] memory array, uint256 newLength) internal pure {
        if (newLength > array.length) {
            revert OutOfBoundsTruncate(array.length, newLength);
        }
        assembly ("memory-safe") {
            mstore(array, newLength)
        }
    }

    /// Extends `baseArray` with `extendArray` by allocating only an additional
    /// `extendArray.length` words onto `baseArray` and copying only
    /// `extendArray` if possible. If `baseArray` is large this MAY be
    /// significantly more efficient than allocating
    /// `baseArray.length + extendArray.length` for an entirely new array and
    /// copying both `baseArray` and `extendArray` into the new array one item
    /// at a time in Solidity.
    ///
    /// The efficient version of extension is only possible if the free memory
    /// pointer sits at the end of the base array at the moment of extension. If
    /// there is allocated memory after the end of base then extension will
    /// require copying both the base and extend arrays to a new region of memory.
    /// The caller is responsible for optimising code paths to avoid additional
    /// allocations.
    ///
    /// This function is UNSAFE because the base array IS MUTATED DIRECTLY by
    /// some code paths AND THE FINAL RETURN ARRAY MAY POINT TO THE SAME REGION
    /// OF MEMORY. It is NOT POSSIBLE to reliably see this behaviour from the
    /// caller in all cases as the Solidity compiler optimisations may switch the
    /// caller between the allocating and non-allocating logic due to subtle
    /// optimisation reasons. To use this function safely THE CALLER MUST NOT USE
    /// THE BASE ARRAY AND MUST USE THE RETURNED ARRAY ONLY. It is safe to use
    /// the extend array after calling this function as it is never mutated, it
    /// is only copied from. Extending an array by itself therefore always
    /// allocates, as the in place path would rewrite the length word that base
    /// and extend share.
    ///
    /// Both arrays MUST be valid solidity memory arrays, each owning the region
    /// its own length word describes.
    ///
    /// @param baseArray The base array that will be extended by `extendArray`.
    /// @param extendArray The extend array that extends `baseArray`.
    /// @return extended `baseArray` extended by `extendArray`.
    function unsafeExtend(bytes32[] memory baseArray, bytes32[] memory extendArray)
        internal
        pure
        returns (bytes32[] memory extended)
    {
        assembly ("memory-safe") {
            // Slither doesn't recognise assembly function names as mixed case
            // even if they are.
            // https://github.com/crytic/slither/issues/1815
            //slither-disable-next-line naming-convention
            function extendInline(base, extend) -> baseAfter {
                let outputCursor := mload(0x40)
                let baseLength := mload(base)
                let baseEnd := add(base, add(0x20, mul(baseLength, 0x20)))

                // The in place path rewrites base's length word where it sits,
                // and when extend IS base that word is also extend's length
                // word, so the write would mutate extend. The in place path is
                // therefore only taken when base is the last thing in allocated
                // memory AND extend is a different array. Otherwise allocate,
                // copy and recurse. The copy puts base above every existing
                // allocation, where it is both the last allocation and distinct
                // from extend, so the recursion is one deep and lands on the in
                // place path.
                switch and(eq(outputCursor, baseEnd), iszero(eq(base, extend)))
                case 0 {
                    let newBase := outputCursor
                    // Base size includes the length word and is in bytes.
                    let newBaseSize := sub(baseEnd, base)
                    let newBaseEnd := add(newBase, newBaseSize)
                    mstore(0x40, newBaseEnd)
                    mcopy(newBase, base, newBaseSize)

                    baseAfter := extendInline(newBase, extend)
                }
                case 1 {
                    // The extend length is read ONCE, before base's length word
                    // is overwritten, so the copy size never depends on the
                    // order of the read and the write.
                    let extendLength := mload(extend)
                    let totalLength := add(baseLength, extendLength)
                    let outputEnd := add(base, add(0x20, mul(totalLength, 0x20)))
                    mstore(base, totalLength)
                    mstore(0x40, outputEnd)
                    mcopy(baseEnd, add(extend, 0x20), mul(extendLength, 0x20))

                    baseAfter := base
                }
            }

            extended := extendInline(baseArray, extendArray)
        }
    }

    /// Reverse an array in place. This is a destructive operation that MUTATES
    /// the array in place. There is no return value.
    /// @param array The array to reverse.
    function reverse(bytes32[] memory array) internal pure {
        assembly ("memory-safe") {
            for {
                let left := add(array, 0x20)
                // Right points at the last item in the array. Which is the
                // length number of items from the length.
                let right := add(array, mul(mload(array), 0x20))
            } lt(left, right) {
                left := add(left, 0x20)
                right := sub(right, 0x20)
            } {
                let leftValue := mload(left)
                mstore(left, mload(right))
                mstore(right, leftValue)
            }
        }
    }
}
