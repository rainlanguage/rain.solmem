// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";
import {LibMemory} from "src/lib/LibMemory.sol";
import {OutOfBoundsTruncate} from "src/error/ErrUint256Array.sol";
import {LibUint256ArraySlow} from "test/lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayTruncateTest is Test {
    function testTruncate(uint256[] memory a, uint256 newLength) public {
        vm.assume(newLength <= a.length);
        uint256[] memory b = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            b[i] = a[i];
        }
        assertEq(a, b);

        LibUint256Array.truncate(a, newLength);
        assertTrue(LibMemory.memoryIsAligned());

        b = LibUint256ArraySlow.truncateSlow(b, newLength);
        assertEq(a, b);
    }

    function testTruncateError(uint256[] memory a, uint256 newLength) public {
        vm.assume(newLength > a.length);
        vm.expectRevert(abi.encodeWithSelector(OutOfBoundsTruncate.selector, a.length, newLength));
        LibUint256Array.truncate(a, newLength);
    }

    function testTruncateGas0() public pure {
        LibUint256Array.truncate(LibUint256Array.arrayFrom(1, 2, 3), 1);
    }

    function testTruncateGas1() public pure {
        LibUint256Array.truncate(LibUint256Array.arrayFrom(1, 2, 3), 0);
    }
}
