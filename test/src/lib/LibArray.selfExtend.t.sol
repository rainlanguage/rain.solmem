// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";

/// Extending an array by itself. The inline path reads the extend length for
/// the copy size, and when extend aliases base that read has to happen before
/// base's length word is rewritten.
contract LibArraySelfExtendTest is Test {
    using LibUint256Array for uint256[];
    using LibBytes32Array for bytes32[];

    /// The assembly is annotated ("memory-safe"), which promises the compiler
    /// nothing is written at or above the free memory pointer the block leaves.
    /// Canaries planted above it must survive.
    function testSelfExtendUint256WritesNothingAboveFreeMemoryPointer() external pure {
        uint256[] memory a = new uint256[](3);
        a[0] = 0x11;
        a[1] = 0x22;
        a[2] = 0x33;

        uint256 fmpBefore;
        assembly ("memory-safe") {
            fmpBefore := mload(0x40)
        }
        assembly ("memory-safe") {
            mstore(add(fmpBefore, 0x60), 0xdead0001)
            mstore(add(fmpBefore, 0xa0), 0xdead0002)
        }

        a.unsafeExtend(a);

        uint256 canary1;
        uint256 canary2;
        assembly ("memory-safe") {
            canary1 := mload(add(fmpBefore, 0x60))
            canary2 := mload(add(fmpBefore, 0xa0))
        }
        assertEq(canary1, 0xdead0001, "wrote at or above the free memory pointer");
        assertEq(canary2, 0xdead0002, "wrote at or above the free memory pointer");
    }

    /// Self-extension copies the original elements once, so the result is the
    /// array doubled rather than a longer run of whatever the copy overran.
    function testSelfExtendUint256DoublesTheContents() external pure {
        uint256[] memory a = new uint256[](3);
        a[0] = 0x11;
        a[1] = 0x22;
        a[2] = 0x33;

        uint256[] memory extended = a.unsafeExtend(a);

        assertEq(extended.length, 6);
        assertEq(extended[0], 0x11);
        assertEq(extended[1], 0x22);
        assertEq(extended[2], 0x33);
        assertEq(extended[3], 0x11);
        assertEq(extended[4], 0x22);
        assertEq(extended[5], 0x33);
    }

    function testSelfExtendBytes32WritesNothingAboveFreeMemoryPointer() external pure {
        bytes32[] memory a = new bytes32[](3);
        a[0] = bytes32(uint256(0x11));
        a[1] = bytes32(uint256(0x22));
        a[2] = bytes32(uint256(0x33));

        uint256 fmpBefore;
        assembly ("memory-safe") {
            fmpBefore := mload(0x40)
        }
        assembly ("memory-safe") {
            mstore(add(fmpBefore, 0x60), 0xdead0001)
        }

        a.unsafeExtend(a);

        uint256 canary1;
        assembly ("memory-safe") {
            canary1 := mload(add(fmpBefore, 0x60))
        }
        assertEq(canary1, 0xdead0001, "wrote at or above the free memory pointer");
    }

    function testSelfExtendBytes32DoublesTheContents() external pure {
        bytes32[] memory a = new bytes32[](2);
        a[0] = bytes32(uint256(0xAA));
        a[1] = bytes32(uint256(0xBB));

        bytes32[] memory extended = a.unsafeExtend(a);

        assertEq(extended.length, 4);
        assertEq(extended[0], bytes32(uint256(0xAA)));
        assertEq(extended[1], bytes32(uint256(0xBB)));
        assertEq(extended[2], bytes32(uint256(0xAA)));
        assertEq(extended[3], bytes32(uint256(0xBB)));
    }
}
