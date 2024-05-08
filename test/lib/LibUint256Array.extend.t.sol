// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import "forge-std/Test.sol";

import "src/lib/LibMemory.sol";
import "src/lib/LibUint256Array.sol";

import "test/lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayExtendTest is Test {
    // This code path hits the inline extension by ensuring that c_ is the most
    // recent thing allocated.
    function testExtendInline(uint256[] memory a_, uint256[] memory b_) public {
        uint256[] memory c_ = new uint256[](a_.length);
        for (uint256 i_ = 0; i_ < a_.length; i_++) {
            c_[i_] = a_[i_];
        }
        c_ = LibUint256Array.unsafeExtend(c_, b_);
        assertTrue(LibMemory.memoryIsAligned());

        assertEq(c_, LibUint256ArraySlow.extendSlow(a_, b_));
    }

    // This code path hits extension with allocation due to b_ sitting behind c_.
    function testExtendAllocate(uint256[] memory a_, uint256[] memory b_) public {
        uint256[] memory c_ = new uint256[](b_.length);
        for (uint256 i_ = 0; i_ < b_.length; i_++) {
            c_[i_] = b_[i_];
        }
        b_ = LibUint256Array.unsafeExtend(b_, a_);
        assertTrue(LibMemory.memoryIsAligned());

        assertEq(b_, LibUint256ArraySlow.extendSlow(c_, a_));
    }

    function testExtendAllocateDebug() public {
        uint256[] memory a_ = new uint256[](3);
        uint256[] memory b_ = new uint256[](4);
        a_[0] = 0x10;
        a_[1] = 0x20;
        a_[2] = 0x30;
        b_[0] = 0x40;
        b_[1] = 0x50;
        b_[2] = 0x60;
        b_[3] = 0x70;
        testExtendAllocate(a_, b_);
    }
}
