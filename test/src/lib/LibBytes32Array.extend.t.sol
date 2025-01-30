// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {LibBytes32ArraySlow} from "test/lib/LibBytes32ArraySlow.sol";

contract LibBytes32ArrayExtendTest is Test {
    // This code path hits the inline extension by ensuring that c is the most
    // recent thing allocated.
    /// forge-config: default.fuzz.runs = 100
    function testExtendInline(bytes32[] memory a, bytes32[] memory b) public pure {
        bytes32[] memory c = new bytes32[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            c[i] = a[i];
        }
        c = LibBytes32Array.unsafeExtend(c, b);

        assertEq(c, LibBytes32ArraySlow.extendSlow(a, b));
    }

    // This code path hits extension with allocation due to b sitting behind c.
    /// forge-config: default.fuzz.runs = 100
    function testExtendAllocate(bytes32[] memory a, bytes32[] memory b) public pure {
        bytes32[] memory c = new bytes32[](b.length);
        for (uint256 i = 0; i < b.length; i++) {
            c[i] = b[i];
        }
        b = LibBytes32Array.unsafeExtend(b, a);

        assertEq(b, LibBytes32ArraySlow.extendSlow(c, a));
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
