// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import "src/lib/LibMemory.sol";
import "src/lib/LibUint256Array.sol";

import "test/lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayPointerTest is Test {
    using LibUint256Array for uint256[];
    using LibUint256Array for Pointer;

    function testUnsafeAsUint256ArrayRoundUint256Array(uint256[] memory array) public {
        assertEq(array, array.startPointer().unsafeAsUint256Array());
    }

    function testUnsafeAsUint256ArrayRound(Pointer pointer) public {
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(pointer.unsafeAsUint256Array().startPointer()));
    }

    function testUint256ArrayDataPointer(uint256[] memory array) public {
        assertEq(Pointer.unwrap(array.startPointer()) + 0x20, Pointer.unwrap(array.dataPointer()));
    }

    function testUint256ArrayEndPointer(uint256[] memory array) public {
        assertEq(Pointer.unwrap(array.dataPointer()) + (array.length * 0x20), Pointer.unwrap(array.endPointer()));
    }
}
