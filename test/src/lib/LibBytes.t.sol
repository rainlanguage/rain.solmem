// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibBytes, TruncateError} from "src/lib/LibBytes.sol";
import {LibPointer, Pointer, LibMemCpy} from "src/lib/LibMemCpy.sol";

contract LibBytesTest is Test {
    using LibBytes for bytes;
    using LibPointer for Pointer;

    function truncateExternal(bytes memory data, uint256 length) external pure returns (bytes memory) {
        data.truncate(length);
        return data;
    }

    function testTruncateFuzz(bytes memory data, uint256 length) public pure {
        vm.assume(data.length >= length);
        data.truncate(length);
        assertEq(data.length, length);
    }

    function testTruncateError(bytes memory data, uint256 length) public {
        vm.assume(data.length < length);
        vm.expectRevert(abi.encodeWithSelector(TruncateError.selector, data.length, length));
        this.truncateExternal(data, length);
    }

    function testDataPointerFuzz(bytes memory data) public pure {
        assertEq(Pointer.unwrap(data.dataPointer()), Pointer.unwrap(data.startPointer().unsafeAddWord()));
    }

    function testRoundBytesPointer(bytes memory data) public pure {
        assertEq(data, data.startPointer().unsafeAsBytes());
    }

    function testDataRound(bytes memory data) public pure {
        bytes memory copy = new bytes(data.length);

        LibMemCpy.unsafeCopyBytesTo(data.dataPointer(), copy.dataPointer(), data.length);

        assertEq(data, copy);
    }

    /// Assert every pointer of `data` against values derived from the layout of
    /// a `bytes` in memory rather than from the implementation: a 32 byte length
    /// prefix, then `length` bytes of data, then padding out to a whole number
    /// of 32 byte words.
    function checkPointers(bytes memory data, uint256 length) internal pure {
        uint256 start = Pointer.unwrap(data.startPointer());

        assertEq(data.length, length, "length");
        assertEq(Pointer.unwrap(data.dataPointer()), start + 32, "dataPointer");
        assertEq(Pointer.unwrap(data.endDataPointer()), start + 32 + length, "endDataPointer");

        // Whole words needed to hold `length` bytes, rounded up.
        uint256 words = length / 32;
        if (length % 32 != 0) {
            ++words;
        }
        assertEq(Pointer.unwrap(data.endAllocatedPointer()), start + 32 + (words * 32), "endAllocatedPointer");
    }

    /// The length domain here is deliberately wider than a single byte so that
    /// pointer arithmetic that is only wrong past 0xff is caught.
    function testEndPointers(uint16 length) public pure {
        bytes memory data = new bytes(length);
        assertEq(Pointer.unwrap(data.endAllocatedPointer()), Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        checkPointers(data, length);
    }

    /// Deterministic coverage of the word alignment boundaries and of lengths
    /// that a `uint8` bounded fuzz can never reach.
    function testEndPointersExactLengths() public pure {
        uint256[12] memory lengths = [uint256(0), 1, 31, 32, 33, 63, 64, 255, 256, 257, 1000, 1024];
        for (uint256 i = 0; i < lengths.length; ++i) {
            bytes memory data = new bytes(lengths[i]);
            checkPointers(data, lengths[i]);
        }
    }

    /// Truncation must set the length EXACTLY, including for lengths that do
    /// not fit in a single byte, and must not disturb the retained data.
    function testTruncateLargeExact() public pure {
        bytes memory data = new bytes(1000);
        for (uint256 i = 0; i < 1000; ++i) {
            data[i] = bytes1(uint8((i % 251) + 1));
        }

        data.truncate(300);

        assertEq(data.length, 300);
        for (uint256 i = 0; i < 300; ++i) {
            assertEq(uint8(data[i]), uint8((i % 251) + 1));
        }
        checkPointers(data, 300);
    }

    /// Truncating to exactly the current length is a no-op, NOT a revert.
    function testTruncateToOwnLengthExact() public pure {
        bytes memory data = hex"0102030405";
        data.truncate(5);
        assertEq(data, hex"0102030405");
    }

    /// Truncating to one byte longer than the current length reverts.
    function testTruncateOneTooLongExact() public {
        bytes memory data = hex"0102030405";
        vm.expectRevert(abi.encodeWithSelector(TruncateError.selector, 5, 6));
        this.truncateExternal(data, 6);
    }
}
