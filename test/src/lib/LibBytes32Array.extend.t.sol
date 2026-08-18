// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibBytes32Array, Pointer} from "src/lib/LibBytes32Array.sol";
import {LibBytes32ArraySlow} from "test/lib/LibBytes32ArraySlow.sol";

contract LibBytes32ArrayExtendTest is Test {
    // This code path hits the inline extension by ensuring that c is the most
    // recent thing allocated. Both code paths produce identical contents, so
    // the returned pointer is the only thing that says which one ran: the
    // inline path extends the base in place and returns the pointer it was
    // given.
    /// forge-config: default.fuzz.runs = 100
    function testExtendInline(bytes32[] memory a, bytes32[] memory b) public pure {
        // Snapshot the extend array before the call so the expected value comes
        // from data `unsafeExtend` cannot reach. Allocated before c so that c
        // remains the most recent allocation.
        bytes32[] memory bBefore = LibBytes32ArraySlow.copySlow(b);
        bytes32[] memory c = new bytes32[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            c[i] = a[i];
        }
        uint256 cBefore = Pointer.unwrap(LibBytes32Array.startPointer(c));
        c = LibBytes32Array.unsafeExtend(c, b);
        assertEq(cBefore, Pointer.unwrap(LibBytes32Array.startPointer(c)), "inline path not taken");

        assertEq(b, bBefore, "extend mutated");
        assertEq(c, LibBytes32ArraySlow.extendSlow(a, bBefore));
    }

    // This code path hits extension with allocation due to b sitting behind c.
    // The allocating path copies the base to a fresh allocation, so it returns
    // a pointer that differs from the one it was given.
    /// forge-config: default.fuzz.runs = 100
    function testExtendAllocate(bytes32[] memory a, bytes32[] memory b) public pure {
        // Snapshot the extend array before the call so the expected value comes
        // from data `unsafeExtend` cannot reach.
        bytes32[] memory aBefore = LibBytes32ArraySlow.copySlow(a);
        bytes32[] memory c = new bytes32[](b.length);
        for (uint256 i = 0; i < b.length; i++) {
            c[i] = b[i];
        }
        uint256 bBefore = Pointer.unwrap(LibBytes32Array.startPointer(b));
        b = LibBytes32Array.unsafeExtend(b, a);
        assertNotEq(bBefore, Pointer.unwrap(LibBytes32Array.startPointer(b)), "allocate path not taken");

        assertEq(a, aBefore, "extend mutated");
        assertEq(b, LibBytes32ArraySlow.extendSlow(c, aBefore));
    }

    /// Extending by an EMPTY array copies nothing, so both code paths leave
    /// byte-identical contents behind and contents cannot say which one ran.
    /// The contents are asserted FIRST here precisely because they hold on
    /// either path: the returned pointer is the only discriminator, and the
    /// inline path returns the pointer it was given.
    function testExtendInlineEmptyExtendKeepsBasePointer() public pure {
        bytes32[] memory extend = new bytes32[](0);

        // Allocated last, so base is the most recent allocation.
        bytes32[] memory base = new bytes32[](2);
        base[0] = bytes32(uint256(0x11));
        base[1] = bytes32(uint256(0x22));

        uint256 baseBefore = Pointer.unwrap(LibBytes32Array.startPointer(base));
        bytes32[] memory extended = LibBytes32Array.unsafeExtend(base, extend);

        assertEq(extended.length, 2, "length");
        assertEq(extended[0], bytes32(uint256(0x11)), "0");
        assertEq(extended[1], bytes32(uint256(0x22)), "1");
        assertEq(baseBefore, Pointer.unwrap(LibBytes32Array.startPointer(extended)), "inline path not taken");
    }

    /// The allocating counterpart of the case above. Same contents, and the
    /// allocating path copies the base to a fresh allocation so it returns a
    /// pointer that differs from the one it was given.
    function testExtendAllocateEmptyExtendMovesBasePointer() public pure {
        bytes32[] memory base = new bytes32[](2);
        base[0] = bytes32(uint256(0x11));
        base[1] = bytes32(uint256(0x22));

        // Allocated after base, so base is no longer the most recent
        // allocation.
        bytes32[] memory extend = new bytes32[](0);

        uint256 baseBefore = Pointer.unwrap(LibBytes32Array.startPointer(base));
        bytes32[] memory extended = LibBytes32Array.unsafeExtend(base, extend);

        assertEq(extended.length, 2, "length");
        assertEq(extended[0], bytes32(uint256(0x11)), "0");
        assertEq(extended[1], bytes32(uint256(0x22)), "1");
        assertNotEq(baseBefore, Pointer.unwrap(LibBytes32Array.startPointer(extended)), "allocate path not taken");
    }

    function testExtendAllocateDebug() public pure {
        bytes32[] memory a = new bytes32[](3);
        bytes32[] memory b = new bytes32[](4);
        a[0] = bytes32(uint256(0x10));
        a[1] = bytes32(uint256(0x20));
        a[2] = bytes32(uint256(0x30));
        b[0] = bytes32(uint256(0x40));
        b[1] = bytes32(uint256(0x50));
        b[2] = bytes32(uint256(0x60));
        b[3] = bytes32(uint256(0x70));
        testExtendAllocate(a, b);
    }

    /// An uninitialised array points at the permanently zero slot at 0x60, and
    /// in a frame that has allocated nothing the free memory pointer sits
    /// exactly at the end of it. The in place path would rewrite the zero slot
    /// there, so an uninitialised base allocates instead: the slot stays zero
    /// and every later empty array in the frame still reads a zero length
    /// through it.
    function testExtendUninitialisedBaseNeverWritesTheZeroSlot() public pure {
        bytes32[] memory base;
        bytes32[] memory extend;

        // Deliberately NOT ("memory-safe"): extend is put in the scratch space
        // so that nothing is allocated and the free memory pointer stays at the
        // end of the zero slot base points at. The pointer is read here rather
        // than after the call because assertions allocate.
        uint256 fmpAtCall;
        assembly {
            mstore(0x00, 1)
            mstore(0x20, 0xDEADBEEF)
            extend := 0x00
            fmpAtCall := mload(0x40)
        }

        bytes32[] memory extended = LibBytes32Array.unsafeExtend(base, extend);

        bytes32[] memory later;
        uint256 zeroSlot;
        uint256 laterLength;
        uint256 extendedPointer;
        assembly {
            zeroSlot := mload(0x60)
            laterLength := mload(later)
            extendedPointer := extended
        }

        assertEq(fmpAtCall, 0x80, "base must be the last thing below the free memory pointer");
        assertEq(extendedPointer, 0x80, "the copy must land at the bottom of the heap");
        assertEq(zeroSlot, 0, "zero slot written");
        assertEq(laterLength, 0, "a later empty array must still read a zero length");
        assertEq(extended.length, 1, "length");
        assertEq(extended[0], bytes32(uint256(0xDEADBEEF)), "0");
    }
}
