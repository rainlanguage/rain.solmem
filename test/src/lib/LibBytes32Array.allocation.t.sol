// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibBytes32Array, Pointer} from "src/lib/LibBytes32Array.sol";
import {LibPointer} from "src/lib/LibPointer.sol";

/// The existing `unsafeExtend` tests assert the CONTENTS of the extended array
/// against a reference implementation. Contents alone cannot see the allocator
/// invariants the assembly is responsible for: extending is free to
/// over-allocate, or to write past the free memory pointer it just set, without
/// any content assertion noticing. These tests pin those invariants down.
///
/// Every one of these tests must read the free memory pointer IMMEDIATELY after
/// the call under test. Assertions allocate, so any assertion made first moves
/// the free memory pointer and destroys the measurement.
contract LibBytes32ArrayAllocationTest is Test {
    using LibBytes32Array for bytes32[];

    /// Number of words of free memory poisoned above the free memory pointer.
    uint256 internal constant POISON_WORDS = 8;

    /// Poison `POISON_WORDS` words of FREE memory starting at the free memory
    /// pointer with per-word recognisable sentinels. Returns the free memory
    /// pointer as it stood before the call under test.
    function _poisonFreeMemory() internal pure returns (uint256 fmpBefore) {
        assembly ("memory-safe") {
            fmpBefore := mload(0x40)
            for { let i := 0 } lt(i, 8) { i := add(i, 1) } {
                mstore(add(fmpBefore, mul(i, 0x20)), add(0xF00D0000, i))
            }
        }
    }

    /// Copy the poisoned region into `captured`, which the caller allocated
    /// BEFORE poisoning so that it sits below the poisoned region and is itself
    /// never disturbed. Copying must happen before any assertion runs.
    function _capture(bytes32[POISON_WORDS] memory captured, uint256 fmpBefore) internal pure {
        assembly ("memory-safe") {
            for { let i := 0 } lt(i, 8) { i := add(i, 1) } {
                mstore(add(captured, mul(i, 0x20)), mload(add(fmpBefore, mul(i, 0x20))))
            }
        }
    }

    /// Every poisoned word that lies at or above the FINAL free memory pointer
    /// is still free memory and must therefore be untouched.
    function _assertNothingWrittenPastFmp(bytes32[POISON_WORDS] memory captured, uint256 fmpBefore, uint256 fmpAfter)
        internal
        pure
    {
        for (uint256 i = 0; i < POISON_WORDS; i++) {
            if (fmpBefore + i * 0x20 < fmpAfter) {
                continue;
            }
            assertEq(captured[i], bytes32(uint256(0xF00D0000 + i)), "wrote past the free memory pointer");
        }
    }

    /// On the inline path the free memory pointer must end up EXACTLY at the
    /// end of the extended array. Over-allocating here is invisible to every
    /// content assertion but wastes memory and breaks the "base is the last
    /// allocation" precondition that the next inline extension relies on.
    function testExtendInlineAllocatesExactly() public pure {
        bytes32[] memory extend = new bytes32[](2);
        extend[0] = bytes32(uint256(0x44));
        extend[1] = bytes32(uint256(0x55));

        // Allocated last, so `base` is the most recent allocation and the
        // inline branch is taken.
        bytes32[] memory base = new bytes32[](3);
        base[0] = bytes32(uint256(0x11));
        base[1] = bytes32(uint256(0x22));
        base[2] = bytes32(uint256(0x33));

        bytes32[] memory extended = LibBytes32Array.unsafeExtend(base, extend);
        uint256 fmpAfter = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256 endOfExtended = uint256(Pointer.unwrap(extended.endPointer()));

        assertEq(extended.length, 5, "length");
        assertEq(extended[0], bytes32(uint256(0x11)));
        assertEq(extended[1], bytes32(uint256(0x22)));
        assertEq(extended[2], bytes32(uint256(0x33)));
        assertEq(extended[3], bytes32(uint256(0x44)));
        assertEq(extended[4], bytes32(uint256(0x55)));
        assertEq(fmpAfter, endOfExtended, "fmp must sit exactly at the end of the extended array");
    }

    /// Same invariant on the allocate-and-copy path, reached when the base
    /// array is not the most recent allocation.
    function testExtendAllocateAllocatesExactly() public pure {
        bytes32[] memory base = new bytes32[](3);
        base[0] = bytes32(uint256(0x11));
        base[1] = bytes32(uint256(0x22));
        base[2] = bytes32(uint256(0x33));

        // Allocated after `base`, so `base` is no longer the last allocation.
        bytes32[] memory extend = new bytes32[](2);
        extend[0] = bytes32(uint256(0x44));
        extend[1] = bytes32(uint256(0x55));

        bytes32[] memory extended = LibBytes32Array.unsafeExtend(base, extend);
        uint256 fmpAfter = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256 endOfExtended = uint256(Pointer.unwrap(extended.endPointer()));

        assertEq(extended.length, 5, "length");
        assertEq(extended[0], bytes32(uint256(0x11)));
        assertEq(extended[4], bytes32(uint256(0x55)));
        assertEq(fmpAfter, endOfExtended, "fmp must sit exactly at the end of the extended array");
    }

    /// The inline path must not write above the free memory pointer it sets.
    /// A copy that runs one word long lands on memory the allocator still
    /// considers free, which the next allocation then hands out to someone else.
    function testExtendInlineDoesNotWritePastFreeMemoryPointer() public pure {
        bytes32[POISON_WORDS] memory captured;

        bytes32[] memory extend = new bytes32[](1);
        extend[0] = bytes32(uint256(0x44));

        bytes32[] memory base = new bytes32[](2);
        base[0] = bytes32(uint256(0x11));
        base[1] = bytes32(uint256(0x22));

        uint256 fmpBefore = _poisonFreeMemory();
        bytes32[] memory extended = LibBytes32Array.unsafeExtend(base, extend);
        uint256 fmpAfter;
        assembly ("memory-safe") {
            fmpAfter := mload(0x40)
        }
        _capture(captured, fmpBefore);

        assertEq(extended.length, 3, "length");
        assertEq(extended[2], bytes32(uint256(0x44)));
        _assertNothingWrittenPastFmp(captured, fmpBefore, fmpAfter);
    }

    /// Same invariant on the allocate-and-copy path. An empty extend array is
    /// used so that the extension copy cannot mask an over-long base copy.
    function testExtendAllocateDoesNotWritePastFreeMemoryPointer() public pure {
        bytes32[POISON_WORDS] memory captured;

        bytes32[] memory base = new bytes32[](2);
        base[0] = bytes32(uint256(0x11));
        base[1] = bytes32(uint256(0x22));

        // Allocated after `base`, forcing the allocate-and-copy branch.
        bytes32[] memory extend = new bytes32[](0);

        uint256 fmpBefore = _poisonFreeMemory();
        bytes32[] memory extended = LibBytes32Array.unsafeExtend(base, extend);
        uint256 fmpAfter;
        assembly ("memory-safe") {
            fmpAfter := mload(0x40)
        }
        _capture(captured, fmpBefore);

        assertEq(extended.length, 2, "length");
        assertEq(extended[0], bytes32(uint256(0x11)));
        assertEq(extended[1], bytes32(uint256(0x22)));
        _assertNothingWrittenPastFmp(captured, fmpBefore, fmpAfter);
    }
}
