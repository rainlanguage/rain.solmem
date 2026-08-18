// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";
import {LibUint256Array, Pointer} from "../../../src/lib/LibUint256Array.sol";
import {LibPointer} from "../../../src/lib/LibPointer.sol";
import {LibUint256ArraySlow} from "../../lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayReverseTest is Test {
    /// Test that the reverse function works as expected according to the
    /// reference implementation.
    function testReverse(uint256[] memory a) public pure {
        uint256[] memory b = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            b[i] = a[i];
        }

        // reverse is documented to mutate in place, so it must not move the
        // free memory pointer at all. Read the pointer immediately either side
        // of the call under test, as assertions themselves allocate.
        Pointer allocatedBefore = LibPointer.allocatedMemoryPointer();
        LibUint256Array.reverse(a);
        Pointer allocatedAfter = LibPointer.allocatedMemoryPointer();
        assertEq(Pointer.unwrap(allocatedBefore), Pointer.unwrap(allocatedAfter), "reverse allocated");

        assertEq(a, LibUint256ArraySlow.reverseSlow(b));
    }

    /// Gas of reversing an empty array.
    function testReverseGas0() public pure {
        LibUint256Array.reverse(new uint256[](0));
    }

    /// Gas of reversing an array of length 1.
    function testReverseGas1() public pure {
        LibUint256Array.reverse(new uint256[](1));
    }

    /// Gas of reversing an array of length 2.
    function testReverseGas2() public pure {
        LibUint256Array.reverse(new uint256[](2));
    }

    /// Gas of reversing an array of length 3.
    function testReverseGas3() public pure {
        LibUint256Array.reverse(new uint256[](3));
    }
}
