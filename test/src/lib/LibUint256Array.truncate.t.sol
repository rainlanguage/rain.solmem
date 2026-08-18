// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";
import {LibUint256Array, Pointer} from "src/lib/LibUint256Array.sol";
import {LibPointer} from "src/lib/LibPointer.sol";
import {OutOfBoundsTruncate} from "src/error/ErrUint256Array.sol";
import {LibUint256ArraySlow} from "test/lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayTruncateTest is Test {
    function truncateExternal(uint256[] memory a, uint256 newLength) external pure returns (uint256[] memory) {
        LibUint256Array.truncate(a, newLength);
        return a;
    }

    function testTruncate(uint256[] memory a, uint256 newLength) public pure {
        vm.assume(newLength <= a.length);
        uint256[] memory b = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            b[i] = a[i];
        }
        assertEq(a, b);

        // truncate is documented to mutate in place with "no new allocation or
        // copying of data", so it must not move the free memory pointer. Read
        // the pointer immediately either side of the call under test, as
        // assertions themselves allocate.
        Pointer allocatedBefore = LibPointer.allocatedMemoryPointer();
        LibUint256Array.truncate(a, newLength);
        Pointer allocatedAfter = LibPointer.allocatedMemoryPointer();
        assertEq(Pointer.unwrap(allocatedBefore), Pointer.unwrap(allocatedAfter), "truncate allocated");

        b = LibUint256ArraySlow.truncateSlow(b, newLength);
        assertEq(a, b);
    }

    function testTruncateError(uint256[] memory a, uint256 newLength) public {
        vm.assume(newLength > a.length);
        vm.expectRevert(abi.encodeWithSelector(OutOfBoundsTruncate.selector, a.length, newLength));
        this.truncateExternal(a, newLength);
    }

    /// `array.length + 1` is the first REJECTED length, for every array length
    /// including zero. `testTruncateError` fuzzes `newLength` over the whole
    /// uint256 range under `newLength > a.length`, so it essentially never
    /// lands on the bound itself; this pins it exactly.
    function testTruncateOneTooLongReverts(uint256[] memory a) public {
        uint256 length = a.length;
        vm.expectRevert(abi.encodeWithSelector(OutOfBoundsTruncate.selector, length, length + 1));
        this.truncateExternal(a, length + 1);
    }

    /// The empty array cannot be truncated to one. The degenerate case of the
    /// bound, where `array.length + 1` is also the smallest nonzero length.
    function testTruncateEmptyToOneReverts() public {
        vm.expectRevert(abi.encodeWithSelector(OutOfBoundsTruncate.selector, 0, 1));
        this.truncateExternal(new uint256[](0), 1);
    }

    /// `array.length` is the largest ACCEPTED length — the other side of the
    /// bound — and truncating to it is a no-op that retains every item.
    function testTruncateToOwnLengthAccepted(uint256[] memory a) public pure {
        uint256 length = a.length;
        uint256[] memory b = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            b[i] = a[i];
        }

        LibUint256Array.truncate(a, length);

        assertEq(a.length, length, "length");
        assertEq(a, b);
    }

    /// `endPointer` is derived from the CURRENT length word, so it marks the end
    /// of the allocation only for an array that has not been shrunk. `truncate`
    /// leaks the tail, which leaves `endPointer` below the end of the memory
    /// still reserved for the array.
    function testEndPointerDivergesAfterTruncate() public pure {
        uint256[] memory a = new uint256[](10);
        // Read the free memory pointer before any assertion, as assertions
        // allocate. Nothing has been allocated since `a`, so this is the end of
        // its allocation.
        uint256 allocationEnd = uint256(Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        uint256 endBefore = uint256(Pointer.unwrap(LibUint256Array.endPointer(a)));

        LibUint256Array.truncate(a, 4);
        uint256 endAfter = uint256(Pointer.unwrap(LibUint256Array.endPointer(a)));

        assertEq(endBefore, allocationEnd, "untruncated: endPointer is the end of the allocation");
        assertEq(allocationEnd - endAfter, 6 * 0x20, "truncated: six words still allocated above endPointer");
    }

    function testTruncateGas0() public pure {
        LibUint256Array.truncate(LibUint256Array.arrayFrom(1, 2, 3), 1);
    }

    function testTruncateGas1() public pure {
        LibUint256Array.truncate(LibUint256Array.arrayFrom(1, 2, 3), 0);
    }
}
