// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibBytes32Array, Pointer} from "src/lib/LibBytes32Array.sol";
import {LibPointer} from "src/lib/LibPointer.sol";
import {OutOfBoundsTruncate} from "src/error/ErrTruncate.sol";
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

        // truncate is documented to mutate in place with "no new allocation or
        // copying of data", so it must not move the free memory pointer. Read
        // the pointer immediately either side of the call under test, as
        // assertions themselves allocate.
        Pointer allocatedBefore = LibPointer.allocatedMemoryPointer();
        LibBytes32Array.truncate(a, newLength);
        Pointer allocatedAfter = LibPointer.allocatedMemoryPointer();
        assertEq(Pointer.unwrap(allocatedBefore), Pointer.unwrap(allocatedAfter), "truncate allocated");

        b = LibBytes32ArraySlow.truncateSlow(b, newLength);
        assertEq(a, b);
    }

    function testTruncateError(bytes32[] memory a, uint256 newLength) public {
        vm.assume(newLength > a.length);
        vm.expectRevert(abi.encodeWithSelector(OutOfBoundsTruncate.selector, a.length, newLength));
        this.truncateExternal(a, newLength);
    }

    /// `array.length + 1` is the first REJECTED length, for every array length
    /// including zero. `testTruncateError` fuzzes `newLength` over the whole
    /// uint256 range under `newLength > a.length`, so it essentially never
    /// lands on the bound itself; this pins it exactly.
    function testTruncateOneTooLongReverts(bytes32[] memory a) public {
        uint256 length = a.length;
        vm.expectRevert(abi.encodeWithSelector(OutOfBoundsTruncate.selector, length, length + 1));
        this.truncateExternal(a, length + 1);
    }

    /// The empty array cannot be truncated to one. The degenerate case of the
    /// bound, where `array.length + 1` is also the smallest nonzero length.
    function testTruncateEmptyToOneReverts() public {
        vm.expectRevert(abi.encodeWithSelector(OutOfBoundsTruncate.selector, 0, 1));
        this.truncateExternal(new bytes32[](0), 1);
    }

    /// `array.length` is the largest ACCEPTED length — the other side of the
    /// bound — and truncating to it is a no-op that neither allocates nor
    /// disturbs any item.
    function testTruncateToOwnLengthAccepted(bytes32[] memory a) public pure {
        uint256 length = a.length;
        bytes32[] memory b = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) {
            b[i] = a[i];
        }

        Pointer allocatedBefore = LibPointer.allocatedMemoryPointer();
        LibBytes32Array.truncate(a, length);
        Pointer allocatedAfter = LibPointer.allocatedMemoryPointer();
        assertEq(Pointer.unwrap(allocatedBefore), Pointer.unwrap(allocatedAfter), "truncate allocated");

        assertEq(a.length, length, "length");
        assertEq(a, b);
    }

    /// `endPointer` is derived from the CURRENT length word, so it marks the end
    /// of the allocation only for an array that has not been shrunk. `truncate`
    /// leaks the tail, which leaves `endPointer` below the end of the memory
    /// still reserved for the array.
    function testEndPointerDivergesAfterTruncate() public pure {
        bytes32[] memory a = new bytes32[](10);
        // Read the free memory pointer before any assertion, as assertions
        // allocate. Nothing has been allocated since `a`, so this is the end of
        // its allocation.
        uint256 allocationEnd = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256 endBefore = uint256(Pointer.unwrap(LibBytes32Array.endPointer(a)));

        LibBytes32Array.truncate(a, 4);
        uint256 endAfter = uint256(Pointer.unwrap(LibBytes32Array.endPointer(a)));

        assertEq(endBefore, allocationEnd, "untruncated: endPointer is the end of the allocation");
        assertEq(allocationEnd - endAfter, 6 * 0x20, "truncated: six words still allocated above endPointer");
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
