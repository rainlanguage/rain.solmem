// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {LibBytes32ArraySlow} from "test/lib/LibBytes32ArraySlow.sol";

contract LibBytes32ArrayReverseTest is Test {
    /// Test that the reverse function works as expected according to the
    /// reference implementation.
    function testReverse(bytes32[] memory a) public pure {
        bytes32[] memory b = new bytes32[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            b[i] = a[i];
        }
        LibBytes32Array.reverse(a);

        assertEq(a, LibBytes32ArraySlow.reverseSlow(b));
    }

    /// Gas of reversing an empty array.
    function testReverseGas0() public pure {
        LibBytes32Array.reverse(new bytes32[](0));
    }

    /// Gas of reversing an array of length 1.
    function testReverseGas1() public pure {
        LibBytes32Array.reverse(new bytes32[](1));
    }

    /// Gas of reversing an array of length 2.
    function testReverseGas2() public pure {
        LibBytes32Array.reverse(new bytes32[](2));
    }

    /// Gas of reversing an array of length 3.
    function testReverseGas3() public pure {
        LibBytes32Array.reverse(new bytes32[](3));
    }
}
