// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";

/// The tail taking `arrayFrom` overloads allocate their output at the free
/// memory pointer and read the tail's length word to size the copy. A tail that
/// sits at the free memory pointer, which is what `unsafeAsUint256Array` and
/// `unsafeAsBytes32Array` over hand managed memory produce, shares that word
/// with the output's length prefix, so the read has to happen before the output
/// length is written.
///
/// The assembly is annotated `("memory-safe")`, which promises the compiler
/// nothing is written at or above the free memory pointer the block leaves.
/// Canaries planted above the reserved region must survive.
contract LibArrayAliasedTailTest is Test {
    /// `arrayFrom(a, tail)` reserves a length word plus four items for a three
    /// item tail, so the output ends `0xA0` above the free memory pointer and
    /// the canary is the first word past it.
    function testArrayFromATailUint256WritesNothingAboveFreeMemoryPointer() external pure {
        uint256[] memory tail;
        uint256 canaryPointer;
        // Deliberately NOT ("memory-safe"): this builds the tail at the free
        // memory pointer without moving it, and plants a canary above the
        // region the call reserves. Claiming memory-safe here would let the
        // optimizer assume those words are untouched and fold the read below
        // into a constant, so the test could pass even after a regression.
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, 3)
            mstore(add(fmp, 0x20), 0x11)
            mstore(add(fmp, 0x40), 0x22)
            mstore(add(fmp, 0x60), 0x33)
            tail := fmp
            canaryPointer := add(fmp, 0xA0)
            mstore(canaryPointer, 0xdead0001)
        }

        uint256[] memory array = LibUint256Array.arrayFrom(0xFF, tail);

        // Read the canary before anything else, as the free memory pointer now
        // points at it and any allocation would overwrite it legitimately.
        uint256 canary;
        assembly {
            canary := mload(canaryPointer)
        }
        assertEq(canary, 0xdead0001, "wrote at or above the free memory pointer");
        assertEq(array.length, 4, "length is the tail length plus the head");
    }

    /// `arrayFrom(a, b, tail)` reserves a length word plus five items for a
    /// three item tail, so the output ends `0xC0` above the free memory pointer
    /// and the double read overruns it by two words.
    function testArrayFromABTailUint256WritesNothingAboveFreeMemoryPointer() external pure {
        uint256[] memory tail;
        uint256 canaryPointer;
        // Deliberately NOT ("memory-safe") -- see above.
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, 3)
            mstore(add(fmp, 0x20), 0x11)
            mstore(add(fmp, 0x40), 0x22)
            mstore(add(fmp, 0x60), 0x33)
            tail := fmp
            canaryPointer := add(fmp, 0xC0)
            mstore(canaryPointer, 0xdead0001)
            mstore(add(canaryPointer, 0x20), 0xdead0002)
        }

        uint256[] memory array = LibUint256Array.arrayFrom(0xFF, 0xEE, tail);

        uint256 canary1;
        uint256 canary2;
        assembly {
            canary1 := mload(canaryPointer)
            canary2 := mload(add(canaryPointer, 0x20))
        }
        assertEq(canary1, 0xdead0001, "wrote at or above the free memory pointer");
        assertEq(canary2, 0xdead0002, "wrote at or above the free memory pointer");
        assertEq(array.length, 5, "length is the tail length plus the two heads");
    }

    function testArrayFromATailBytes32WritesNothingAboveFreeMemoryPointer() external pure {
        bytes32[] memory tail;
        uint256 canaryPointer;
        // Deliberately NOT ("memory-safe") -- see above.
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, 3)
            mstore(add(fmp, 0x20), 0x11)
            mstore(add(fmp, 0x40), 0x22)
            mstore(add(fmp, 0x60), 0x33)
            tail := fmp
            canaryPointer := add(fmp, 0xA0)
            mstore(canaryPointer, 0xdead0001)
        }

        bytes32[] memory array = LibBytes32Array.arrayFrom(bytes32(uint256(0xFF)), tail);

        uint256 canary;
        assembly {
            canary := mload(canaryPointer)
        }
        assertEq(canary, 0xdead0001, "wrote at or above the free memory pointer");
        assertEq(array.length, 4, "length is the tail length plus the head");
    }

    function testArrayFromABTailBytes32WritesNothingAboveFreeMemoryPointer() external pure {
        bytes32[] memory tail;
        uint256 canaryPointer;
        // Deliberately NOT ("memory-safe") -- see above.
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, 3)
            mstore(add(fmp, 0x20), 0x11)
            mstore(add(fmp, 0x40), 0x22)
            mstore(add(fmp, 0x60), 0x33)
            tail := fmp
            canaryPointer := add(fmp, 0xC0)
            mstore(canaryPointer, 0xdead0001)
            mstore(add(canaryPointer, 0x20), 0xdead0002)
        }

        bytes32[] memory array = LibBytes32Array.arrayFrom(bytes32(uint256(0xFF)), bytes32(uint256(0xEE)), tail);

        uint256 canary1;
        uint256 canary2;
        assembly {
            canary1 := mload(canaryPointer)
            canary2 := mload(add(canaryPointer, 0x20))
        }
        assertEq(canary1, 0xdead0001, "wrote at or above the free memory pointer");
        assertEq(canary2, 0xdead0002, "wrote at or above the free memory pointer");
        assertEq(array.length, 5, "length is the tail length plus the two heads");
    }
}
