// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibUint256Array, Pointer} from "src/lib/LibUint256Array.sol";
import {LibUint256ArraySlow} from "test/lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayExtendTest is Test {
    // This code path hits the inline extension by ensuring that c is the most
    // recent thing allocated. Both code paths produce identical contents, so
    // the returned pointer is the only thing that says which one ran: the
    // inline path extends the base in place and returns the pointer it was
    // given.
    /// forge-config: default.fuzz.runs = 100
    function testExtendInline(uint256[] memory a, uint256[] memory b) public pure {
        // Snapshot the extend array before the call so the expected value comes
        // from data `unsafeExtend` cannot reach. Allocated before c so that c
        // remains the most recent allocation.
        uint256[] memory bBefore = LibUint256ArraySlow.copySlow(b);
        uint256[] memory c = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            c[i] = a[i];
        }
        uint256 cBefore = Pointer.unwrap(LibUint256Array.startPointer(c));
        c = LibUint256Array.unsafeExtend(c, b);
        assertEq(cBefore, Pointer.unwrap(LibUint256Array.startPointer(c)), "inline path not taken");

        assertEq(b, bBefore, "extend mutated");
        assertEq(c, LibUint256ArraySlow.extendSlow(a, bBefore));
    }

    // This code path hits extension with allocation due to b sitting behind c.
    // The allocating path copies the base to a fresh allocation, so it returns
    // a pointer that differs from the one it was given.
    /// forge-config: default.fuzz.runs = 100
    function testExtendAllocate(uint256[] memory a, uint256[] memory b) public pure {
        // Snapshot the extend array before the call so the expected value comes
        // from data `unsafeExtend` cannot reach.
        uint256[] memory aBefore = LibUint256ArraySlow.copySlow(a);
        uint256[] memory c = new uint256[](b.length);
        for (uint256 i = 0; i < b.length; i++) {
            c[i] = b[i];
        }
        uint256 bBefore = Pointer.unwrap(LibUint256Array.startPointer(b));
        b = LibUint256Array.unsafeExtend(b, a);
        assertNotEq(bBefore, Pointer.unwrap(LibUint256Array.startPointer(b)), "allocate path not taken");

        assertEq(a, aBefore, "extend mutated");
        assertEq(b, LibUint256ArraySlow.extendSlow(c, aBefore));
    }

    /// Extending by an EMPTY array copies nothing, so both code paths leave
    /// byte-identical contents behind and contents cannot say which one ran.
    /// The contents are asserted FIRST here precisely because they hold on
    /// either path: the returned pointer is the only discriminator, and the
    /// inline path returns the pointer it was given.
    function testExtendInlineEmptyExtendKeepsBasePointer() public pure {
        uint256[] memory extend = new uint256[](0);

        // Allocated last, so base is the most recent allocation.
        uint256[] memory base = new uint256[](2);
        base[0] = 0x11;
        base[1] = 0x22;

        uint256 baseBefore = Pointer.unwrap(LibUint256Array.startPointer(base));
        uint256[] memory extended = LibUint256Array.unsafeExtend(base, extend);

        assertEq(extended.length, 2, "length");
        assertEq(extended[0], 0x11, "0");
        assertEq(extended[1], 0x22, "1");
        assertEq(baseBefore, Pointer.unwrap(LibUint256Array.startPointer(extended)), "inline path not taken");
    }

    /// The allocating counterpart of the case above. Same contents, and the
    /// allocating path copies the base to a fresh allocation so it returns a
    /// pointer that differs from the one it was given.
    function testExtendAllocateEmptyExtendMovesBasePointer() public pure {
        uint256[] memory base = new uint256[](2);
        base[0] = 0x11;
        base[1] = 0x22;

        // Allocated after base, so base is no longer the most recent
        // allocation.
        uint256[] memory extend = new uint256[](0);

        uint256 baseBefore = Pointer.unwrap(LibUint256Array.startPointer(base));
        uint256[] memory extended = LibUint256Array.unsafeExtend(base, extend);

        assertEq(extended.length, 2, "length");
        assertEq(extended[0], 0x11, "0");
        assertEq(extended[1], 0x22, "1");
        assertNotEq(baseBefore, Pointer.unwrap(LibUint256Array.startPointer(extended)), "allocate path not taken");
    }

    function testExtendAllocateDebug() public pure {
        uint256[] memory a = new uint256[](3);
        uint256[] memory b = new uint256[](4);
        a[0] = 0x10;
        a[1] = 0x20;
        a[2] = 0x30;
        b[0] = 0x40;
        b[1] = 0x50;
        b[2] = 0x60;
        b[3] = 0x70;
        testExtendAllocate(a, b);
    }

    /// An uninitialised array points at the permanently zero slot at 0x60, and
    /// in a frame that has allocated nothing the free memory pointer sits
    /// exactly at the end of it. The in place path would rewrite the zero slot
    /// there, so an uninitialised base allocates instead: the slot stays zero
    /// and every later empty array in the frame still reads a zero length
    /// through it.
    function testExtendUninitialisedBaseNeverWritesTheZeroSlot() public pure {
        uint256[] memory base;
        uint256[] memory extend;

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

        uint256[] memory extended = LibUint256Array.unsafeExtend(base, extend);

        uint256[] memory later;
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
        assertEq(extended[0], 0xDEADBEEF, "0");
    }
}
