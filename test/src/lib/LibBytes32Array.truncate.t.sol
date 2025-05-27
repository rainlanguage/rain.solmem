// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {OutOfBoundsTruncate} from "src/error/ErrUint256Array.sol";
import {LibBytes32ArraySlow} from "test/lib/LibBytes32ArraySlow.sol";

contract LibBytes32ArrayTruncateTest is Test {
    function truncateExternal(bytes32[] memory a, uint256 newLength) external pure returns (bytes32[] memory) {
        LibBytes32Array.truncate(a, newLength);
        return a;
    }

    function testTruncate(bytes32[] memory a, uint256 newLength) public pure {
        vm.assume(newLength <= a.length);
        bytes32[] memory b = new bytes32[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            b[i] = a[i];
        }
        assertEq(a, b);

        LibBytes32Array.truncate(a, newLength);

        b = LibBytes32ArraySlow.truncateSlow(b, newLength);
        assertEq(a, b);
    }

    function testTruncateError(bytes32[] memory a, uint256 newLength) public {
        vm.assume(newLength > a.length);
        vm.expectRevert(abi.encodeWithSelector(OutOfBoundsTruncate.selector, a.length, newLength));
        this.truncateExternal(a, newLength);
    }

    function testTruncateGas0() public pure {
        LibBytes32Array.truncate(
            LibBytes32Array.arrayFrom(bytes32(uint256(1)), bytes32(uint256(2)), bytes32(uint256(3))), 1
        );
    }

    function testTruncateGas1() public pure {
        LibBytes32Array.truncate(
            LibBytes32Array.arrayFrom(bytes32(uint256(1)), bytes32(uint256(2)), bytes32(uint256(3))), 0
        );
    }
}
