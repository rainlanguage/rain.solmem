// SPDX-License-Identifier: CAL
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/LibMemory.sol";

contract LibMemoryTest is Test {
    // Just fuzz to get some things in memory.
    function testMemoryIsAlignedFalseFuzz(bytes memory, uint256 offset_) public {
        vm.assume(offset_ % 0x20 != 0);
        assertTrue(LibMemory.memoryIsAligned());
        assembly {
            mstore(0x40, add(mload(0x40), offset_))
        }
        assertTrue(!LibMemory.memoryIsAligned());
    }

    function testMemoryIsAlignedTrue(uint256 offset_) public {
        vm.assume(offset_ % 0x20 == 0);
        assertTrue(LibMemory.memoryIsAligned());
        assembly {
            mstore(0x40, add(mload(0x40), offset_))
        }
        assertTrue(LibMemory.memoryIsAligned());
    }
}
