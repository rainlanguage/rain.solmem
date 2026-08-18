// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";

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
}
