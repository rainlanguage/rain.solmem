// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibUint256Array, Pointer} from "src/lib/LibUint256Array.sol";

import {LibUint256ArraySlow} from "test/lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayPointerTest is Test {
    using LibUint256Array for uint256[];
    using LibUint256Array for Pointer;

    function testUnsafeAsUint256ArrayRoundUint256Array(uint256[] memory array) public pure {
        assertEq(array, array.startPointer().unsafeAsUint256Array());
    }

    function testUnsafeAsUint256ArrayRound(Pointer pointer) public pure {
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(pointer.unsafeAsUint256Array().startPointer()));
    }

    function testUint256ArrayDataPointer(uint256[] memory array) public pure {
        assertEq(Pointer.unwrap(array.startPointer()) + 0x20, Pointer.unwrap(array.dataPointer()));
    }

    function testUint256ArrayEndPointer(uint256[] memory array) public pure {
        assertEq(Pointer.unwrap(array.dataPointer()) + (array.length * 0x20), Pointer.unwrap(array.endPointer()));
    }
}
