// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibPointer, Pointer} from "src/lib/LibPointer.sol";
import {LibBytes} from "src/lib/LibBytes.sol";

contract LibPointerTest is Test {
    using LibPointer for Pointer;
    using LibBytes for bytes;

    function testUnsafeAsBytesRoundBytes(bytes memory data) public pure {
        assertEq(data, data.startPointer().unsafeAsBytes());
    }

    function testUnsafeAsBytesRound(Pointer pointer) public pure {
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(pointer.unsafeAsBytes().startPointer()));
    }

    function testUnsafeAddBytes(uint32 pointer, uint32 n) public pure {
        assertEq(uint256(pointer) + uint256(n), Pointer.unwrap(Pointer.wrap(pointer).unsafeAddBytes(n)));
    }

    function testUnsafeAddWord(uint32 pointer) public pure {
        assertEq(uint256(pointer) + 0x20, Pointer.unwrap(Pointer.wrap(pointer).unsafeAddWord()));
    }

    function testUnsafeAddWords(uint32 pointer, uint32 n) public pure {
        assertEq(uint256(pointer) + uint256(n) * 0x20, Pointer.unwrap(Pointer.wrap(pointer).unsafeAddWords(n)));
    }

    function testUnsafeSubWord(uint32 pointer) public pure {
        // The caller MUST ensure the pointer will not underflow on sub.
        vm.assume(pointer >= 0x20);
        assertEq(uint256(pointer) - 0x20, Pointer.unwrap(Pointer.wrap(pointer).unsafeSubWord()));
    }

    function testUnsafeSubWords(uint32 pointer, uint32 n) public pure {
        // The caller MUST ensure the pointer will not underflow on sub.
        vm.assume(uint256(pointer) >= uint256(n) * 0x20);
        assertEq(uint256(pointer) - uint256(n) * 0x20, Pointer.unwrap(Pointer.wrap(pointer).unsafeSubWords(n)));
    }

    function testReadWriteRound(bytes32 a, bytes32 b) public pure {
        Pointer pointer = LibPointer.allocatedMemoryPointer();
        pointer.unsafeWriteWord(a);
        assertEq(a, pointer.unsafeReadWord());
        pointer.unsafeWriteWord(b);
        assertEq(b, pointer.unsafeReadWord());
    }

    function testAllocatedMemoryPointer(uint8 length_) public pure {
        vm.assume(length_ > 0);
        Pointer a_ = LibPointer.allocatedMemoryPointer();
        new uint256[](length_);
        Pointer b_ = LibPointer.allocatedMemoryPointer();
        assertEq(uint256(length_) * 0x20 + 0x20, Pointer.unwrap(b_) - Pointer.unwrap(a_));
    }
}
