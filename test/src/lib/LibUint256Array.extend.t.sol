// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";

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
}
