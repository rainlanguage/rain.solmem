// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibMemory} from "src/lib/LibMemory.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";

import {LibUint256ArraySlow} from "test/lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayExtendTest is Test {
    // This code path hits the inline extension by ensuring that c is the most
    // recent thing allocated.
    /// forge-config: default.fuzz.runs = 100
    function testExtendInline(uint256[] memory a, uint256[] memory b) public pure {
        uint256[] memory c = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            c[i] = a[i];
        }
        c = LibUint256Array.unsafeExtend(c, b);
        assertTrue(LibMemory.memoryIsAligned());

        assertEq(c, LibUint256ArraySlow.extendSlow(a, b));
    }

    // This code path hits extension with allocation due to b sitting behind c.
    /// forge-config: default.fuzz.runs = 100
    function testExtendAllocate(uint256[] memory a, uint256[] memory b) public pure {
        uint256[] memory c = new uint256[](b.length);
        for (uint256 i = 0; i < b.length; i++) {
            c[i] = b[i];
        }
        b = LibUint256Array.unsafeExtend(b, a);
        assertTrue(LibMemory.memoryIsAligned());

        assertEq(b, LibUint256ArraySlow.extendSlow(c, a));
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
