// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";

import {LibPointer, Pointer} from "../../../src/lib/LibPointer.sol";
import {LibBytes} from "../../../src/lib/LibBytes.sol";

contract LibPointerTest is Test {
    using LibPointer for Pointer;
    using LibBytes for bytes;

    /// `unsafeWriteWord` writes the 32 bytes at the pointer and nothing else.
    /// Claims three words, fills them with the complement of `word` so a stray
    /// write can never be mistaken for the fill, then writes the middle word.
    function checkWriteWordExtent(bytes32 word) internal pure {
        uint256 low = Pointer.unwrap(LibPointer.allocatedMemoryPointer());
        uint256 mid = low + 0x20;
        uint256 high = low + 0x40;
        bytes32 fill = ~word;
        bytes32 lowAfter;
        bytes32 midAfter;
        bytes32 highAfter;
        assembly ("memory-safe") {
            mstore(0x40, add(low, 0x60))
            mstore(low, fill)
            mstore(mid, fill)
            mstore(high, fill)
        }
        Pointer.wrap(mid).unsafeWriteWord(word);
        assembly ("memory-safe") {
            lowAfter := mload(low)
            midAfter := mload(mid)
            highAfter := mload(high)
        }
        assertEq(midAfter, word, "write missed the pointer");
        assertEq(lowAfter, fill, "write touched the word below");
        assertEq(highAfter, fill, "write touched the word above");
    }

    function testUnsafeAsBytesRoundBytes(bytes memory data) public pure {
        assertEq(data, data.startPointer().unsafeAsBytes());
    }

    function testUnsafeAsBytesRound(Pointer pointer) public pure {
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(pointer.unsafeAsBytes().startPointer()));
    }

    function testUnsafeAddBytes(uint256 pointer, uint256 n) public pure {
        unchecked {
            assertEq(pointer + n, Pointer.unwrap(Pointer.wrap(pointer).unsafeAddBytes(n)));
        }
    }

    /// The pointer wraps mod 2**256 and the whole offset counts.
    function testUnsafeAddBytesWrap() public pure {
        assertEq(0, Pointer.unwrap(Pointer.wrap(type(uint256).max).unsafeAddBytes(1)));
        assertEq(0, Pointer.unwrap(Pointer.wrap(1).unsafeAddBytes(type(uint256).max)));
        assertEq(
            type(uint256).max - 1, Pointer.unwrap(Pointer.wrap(type(uint256).max).unsafeAddBytes(type(uint256).max))
        );
    }

    function testUnsafeAddWord(uint256 pointer) public pure {
        unchecked {
            assertEq(pointer + 0x20, Pointer.unwrap(Pointer.wrap(pointer).unsafeAddWord()));
        }
    }

    function testUnsafeAddWordWrap() public pure {
        assertEq(0, Pointer.unwrap(Pointer.wrap(type(uint256).max - 0x1f).unsafeAddWord()));
        assertEq(0x1f, Pointer.unwrap(Pointer.wrap(type(uint256).max).unsafeAddWord()));
    }

    function testUnsafeAddWords(uint256 pointer, uint32 n) public pure {
        unchecked {
            assertEq(pointer + uint256(n) * 0x20, Pointer.unwrap(Pointer.wrap(pointer).unsafeAddWords(n)));
        }
    }

    /// The word count keeps its full width, and the product of a real count
    /// with `0x20` is what moves the pointer, wrapping mod 2**256.
    function testUnsafeAddWordsWrap() public pure {
        assertEq(0x1f, Pointer.unwrap(Pointer.wrap(type(uint256).max).unsafeAddWords(1)));
        assertEq(0, Pointer.unwrap(Pointer.wrap(type(uint256).max - 0x3f).unsafeAddWords(2)));
        assertEq(0x20 * (2 ** 32 + 1), Pointer.unwrap(Pointer.wrap(0).unsafeAddWords(2 ** 32 + 1)));
    }

    function testUnsafeSubWord(uint256 pointer) public pure {
        unchecked {
            assertEq(pointer - 0x20, Pointer.unwrap(Pointer.wrap(pointer).unsafeSubWord()));
        }
    }

    function testUnsafeSubWordWrap() public pure {
        assertEq(0, Pointer.unwrap(Pointer.wrap(0x20).unsafeSubWord()));
        assertEq(type(uint256).max, Pointer.unwrap(Pointer.wrap(0x1f).unsafeSubWord()));
        assertEq(type(uint256).max - 0x1f, Pointer.unwrap(Pointer.wrap(0).unsafeSubWord()));
    }

    function testUnsafeSubWords(uint256 pointer, uint32 n) public pure {
        unchecked {
            assertEq(pointer - uint256(n) * 0x20, Pointer.unwrap(Pointer.wrap(pointer).unsafeSubWords(n)));
        }
    }

    /// The word count keeps its full width, and the product of a real count
    /// with `0x20` is what moves the pointer, wrapping below zero.
    function testUnsafeSubWordsWrap() public pure {
        unchecked {
            assertEq(0, Pointer.unwrap(Pointer.wrap(0x40).unsafeSubWords(2)));
            assertEq(type(uint256).max - 0x1f, Pointer.unwrap(Pointer.wrap(0).unsafeSubWords(1)));
            assertEq(type(uint256).max - 0x20, Pointer.unwrap(Pointer.wrap(0x1f).unsafeSubWords(2)));
            assertEq(uint256(0) - 0x20 * (2 ** 32 + 1), Pointer.unwrap(Pointer.wrap(0).unsafeSubWords(2 ** 32 + 1)));
        }
    }

    function testReadWriteRound(bytes32 a, bytes32 b) public pure {
        Pointer pointer = LibPointer.allocatedMemoryPointer();
        pointer.unsafeWriteWord(a);
        assertEq(a, pointer.unsafeReadWord());
        pointer.unsafeWriteWord(b);
        assertEq(b, pointer.unsafeReadWord());
    }

    function testUnsafeWriteWordExtent(bytes32 word) public pure {
        checkWriteWordExtent(word);
    }

    function testUnsafeWriteWordExtentZero() public pure {
        checkWriteWordExtent(bytes32(0));
    }

    function testAllocatedMemoryPointer(uint8 length_) public pure {
        vm.assume(length_ > 0);
        Pointer a_ = LibPointer.allocatedMemoryPointer();
        new uint256[](length_);
        Pointer b_ = LibPointer.allocatedMemoryPointer();
        assertEq(uint256(length_) * 0x20 + 0x20, Pointer.unwrap(b_) - Pointer.unwrap(a_));
    }
}
