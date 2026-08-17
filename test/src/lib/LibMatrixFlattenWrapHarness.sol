// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibUint256Matrix} from "src/lib/LibUint256Matrix.sol";
import {LibBytes32Matrix} from "src/lib/LibBytes32Matrix.sol";
import {LibStackPointer} from "src/lib/LibStackPointer.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {Pointer} from "src/lib/LibPointer.sol";

/// Harness for `itemCount` and `flatten` on both matrix libraries.
///
/// Each probe builds its matrix and calls the library inside a single external
/// call, then reduces the result to plain words. The external boundary is what
/// lets the test observe a loud failure as an outcome rather than suffering it
/// as a test failure, and it means the test itself never touches the memory
/// these frames allocate.
contract LibMatrixFlattenWrapHarness {
    using LibUint256Matrix for uint256[][];
    using LibBytes32Matrix for bytes32[][];
    using LibBytes32Matrix for bytes32[];
    using LibStackPointer for Pointer;
    using LibBytes32Array for bytes32[];

    /// Planted in the allocation that lands immediately after `flatten`'s.
    uint256 public constant CANARY = 0xBEEF;

    /// Written through `flatten`'s result. Finding it in the canary means the
    /// write escaped the allocation `flatten` made.
    uint256 public constant SCRIBBLE = 0xC0FFEE;

    /// What a caller can observe about a `flatten` result without any assembly
    /// of its own.
    /// @param declaredLength The length word `flatten` stamped on its result.
    /// @param allocatedBytes How far `flatten` advanced the free memory
    /// pointer, i.e. the length word plus the data it actually reserved.
    struct Allocation {
        uint256 declaredLength;
        uint256 allocatedBytes;
    }

    /// Builds a two entry matrix whose inner arrays carry the given length
    /// words. Nothing is allocated behind those length words, which is exactly
    /// the situation the length words describe as impossible.
    /// @param length0 The length word of the first inner array.
    /// @param length1 The length word of the second inner array.
    /// @return matrix The forged matrix.
    function forgeUint256Matrix(uint256 length0, uint256 length1) internal pure returns (uint256[][] memory matrix) {
        assembly ("memory-safe") {
            let inner0 := mload(0x40)
            mstore(inner0, length0)
            let inner1 := add(inner0, 0x20)
            mstore(inner1, length1)
            matrix := add(inner1, 0x20)
            mstore(matrix, 2)
            mstore(add(matrix, 0x20), inner0)
            mstore(add(matrix, 0x40), inner1)
            mstore(0x40, add(matrix, 0x60))
        }
    }

    /// `forgeUint256Matrix` for the `bytes32` twin.
    /// @param length0 The length word of the first inner array.
    /// @param length1 The length word of the second inner array.
    /// @return matrix The forged matrix.
    function forgeBytes32Matrix(uint256 length0, uint256 length1) internal pure returns (bytes32[][] memory matrix) {
        assembly ("memory-safe") {
            let inner0 := mload(0x40)
            mstore(inner0, length0)
            let inner1 := add(inner0, 0x20)
            mstore(inner1, length1)
            matrix := add(inner1, 0x20)
            mstore(matrix, 2)
            mstore(add(matrix, 0x20), inner0)
            mstore(add(matrix, 0x40), inner1)
            mstore(0x40, add(matrix, 0x60))
        }
    }

    /// Reports `LibUint256Matrix.itemCount` over a forged two entry matrix.
    /// @param length0 The length word of the first inner array.
    /// @param length1 The length word of the second inner array.
    /// @return count The reported total.
    function uint256ItemCount(uint256 length0, uint256 length1) external pure returns (uint256 count) {
        return forgeUint256Matrix(length0, length1).itemCount();
    }

    /// `uint256ItemCount` for the `bytes32` twin.
    /// @param length0 The length word of the first inner array.
    /// @param length1 The length word of the second inner array.
    /// @return count The reported total.
    function bytes32ItemCount(uint256 length0, uint256 length1) external pure returns (uint256 count) {
        return forgeBytes32Matrix(length0, length1).itemCount();
    }

    /// Flattens a forged two entry matrix and reports the length word against
    /// the memory actually reserved for it.
    /// @param length0 The length word of the first inner array.
    /// @param length1 The length word of the second inner array.
    /// @return allocation See `Allocation`.
    function uint256Flatten(uint256 length0, uint256 length1) external pure returns (Allocation memory allocation) {
        uint256[][] memory matrix = forgeUint256Matrix(length0, length1);
        uint256 fmpBefore;
        assembly ("memory-safe") {
            fmpBefore := mload(0x40)
        }
        uint256[] memory flat = matrix.flatten();
        uint256 fmpAfter;
        assembly ("memory-safe") {
            fmpAfter := mload(0x40)
        }
        allocation.declaredLength = flat.length;
        allocation.allocatedBytes = fmpAfter - fmpBefore;
    }

    /// `uint256Flatten` for the `bytes32` twin.
    /// @param length0 The length word of the first inner array.
    /// @param length1 The length word of the second inner array.
    /// @return allocation See `Allocation`.
    function bytes32Flatten(uint256 length0, uint256 length1) external pure returns (Allocation memory allocation) {
        bytes32[][] memory matrix = forgeBytes32Matrix(length0, length1);
        uint256 fmpBefore;
        assembly ("memory-safe") {
            fmpBefore := mload(0x40)
        }
        bytes32[] memory flat = matrix.flatten();
        uint256 fmpAfter;
        assembly ("memory-safe") {
            fmpAfter := mload(0x40)
        }
        allocation.declaredLength = flat.length;
        allocation.allocatedBytes = fmpAfter - fmpBefore;
    }

    /// Flattens a forged matrix, allocates an ordinary array immediately after
    /// it, then writes `SCRIBBLE` through `flatten`'s result at whatever index
    /// aliases `canary[3]`.
    ///
    /// The write is ordinary bounds checked Solidity. Solidity consults the
    /// length word `flatten` stamped, so the library's own output is what
    /// licenses it. The index is derived from the live pointers rather than
    /// hardcoded, so the test does not depend on an exact memory layout.
    /// @param length0 The length word of the first inner array.
    /// @param length1 The length word of the second inner array.
    /// @return canaryValue `canary[3]` read back after the write.
    function uint256FlattenThenWriteThroughResult(uint256 length0, uint256 length1)
        external
        pure
        returns (uint256 canaryValue)
    {
        uint256[] memory flat = forgeUint256Matrix(length0, length1).flatten();

        uint256[] memory canary = new uint256[](8);
        canary[3] = CANARY;

        uint256 index;
        assembly ("memory-safe") {
            index := div(sub(add(canary, 0x80), add(flat, 0x20)), 0x20)
        }
        flat[index] = SCRIBBLE;

        canaryValue = canary[3];
    }

    /// `uint256FlattenThenWriteThroughResult` for the `bytes32` twin.
    /// @param length0 The length word of the first inner array.
    /// @param length1 The length word of the second inner array.
    /// @return canaryValue `canary[3]` read back after the write.
    function bytes32FlattenThenWriteThroughResult(uint256 length0, uint256 length1)
        external
        pure
        returns (uint256 canaryValue)
    {
        bytes32[] memory flat = forgeBytes32Matrix(length0, length1).flatten();

        bytes32[] memory canary = new bytes32[](8);
        canary[3] = bytes32(CANARY);

        uint256 index;
        assembly ("memory-safe") {
            index := div(sub(add(canary, 0x80), add(flat, 0x20)), 0x20)
        }
        flat[index] = bytes32(SCRIBBLE);

        canaryValue = uint256(canary[3]);
    }

    /// The same defect with no length word forged by this harness at all.
    ///
    /// `LibStackPointer.unsafeList` is the library's own minter of a forged
    /// length word (issue #54, second site). Its output goes through
    /// `matrixFrom` and `flatten`, neither of which is prefixed `unsafe` and
    /// neither of which documents any precondition on its input, and out comes
    /// an array declaring far more items than were reserved for it.
    /// @param forgedLength The length passed to `unsafeList`.
    /// @return mintedLength The length word `unsafeList` minted.
    /// @return allocation See `Allocation`, for the `flatten` that followed.
    function mintThenFlatten(uint256 forgedLength)
        external
        pure
        returns (uint256 mintedLength, Allocation memory allocation)
    {
        bytes32[] memory stack = new bytes32[](4);
        stack[0] = bytes32(uint256(0xA0));
        stack[1] = bytes32(uint256(0xA1));
        stack[2] = bytes32(uint256(0xA2));
        stack[3] = bytes32(uint256(0xA3));

        (, bytes32[] memory tail) = stack.endPointer().unsafeList(forgedLength);
        mintedLength = tail.length;

        bytes32[][] memory matrix = tail.matrixFrom();

        uint256 fmpBefore;
        assembly ("memory-safe") {
            fmpBefore := mload(0x40)
        }
        bytes32[] memory flat = matrix.flatten();
        uint256 fmpAfter;
        assembly ("memory-safe") {
            fmpAfter := mload(0x40)
        }
        allocation.declaredLength = flat.length;
        allocation.allocatedBytes = fmpAfter - fmpBefore;
    }
}
