// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import "src/lib/LibBytes.sol";
import "src/lib/LibMemCpy.sol";

contract LibBytesTest is Test {
    using LibBytes for bytes;
    using LibPointer for Pointer;

    function testTruncateFuzz(bytes memory data, uint256 length) public {
        vm.assume(data.length >= length);
        data.truncate(length);
        assertEq(data.length, length);
    }

    function testTruncateError(bytes memory data, uint256 length) public {
        vm.assume(data.length < length);
        vm.expectRevert(abi.encodeWithSelector(TruncateError.selector, data.length, length));
        data.truncate(length);
    }

    function testDataPointerFuzz(bytes memory data) public {
        assertEq(Pointer.unwrap(data.dataPointer()), Pointer.unwrap(data.startPointer().unsafeAddWord()));
    }

    function testRoundBytesPointer(bytes memory data) public {
        assertEq(data, data.startPointer().unsafeAsBytes());
    }

    function testDataRound(bytes memory data) public {
        bytes memory copy = new bytes(data.length);

        LibMemCpy.unsafeCopyBytesTo(data.dataPointer(), copy.dataPointer(), data.length);

        assertEq(data, copy);
    }

    function testEndPointers(uint8 length) public {
        bytes memory data = new bytes(length);
        assertEq(Pointer.unwrap(data.endAllocatedPointer()), Pointer.unwrap(LibPointer.allocatedMemoryPointer()));
        assertEq(
            Pointer.unwrap(data.endAllocatedPointer()) - Pointer.unwrap(data.endDataPointer()),
            (0x20 - (length % 32)) % 0x20
        );
        assertEq(Pointer.unwrap(data.endDataPointer()) - Pointer.unwrap(data.dataPointer()), length);
    }
}
