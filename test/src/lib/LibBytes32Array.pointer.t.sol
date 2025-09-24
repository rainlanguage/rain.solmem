// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibBytes32Array, Pointer} from "src/lib/LibBytes32Array.sol";

contract LibByes32ArrayPointerTest is Test {
    using LibBytes32Array for bytes32[];
    using LibBytes32Array for Pointer;

    function testUnsafeAsBytes32ArrayRoundBytes32Array(bytes32[] memory array) public pure {
        assertEq(array, array.startPointer().unsafeAsBytes32Array());
    }

    function testUnsafeAsBytes32ArrayRound(Pointer pointer) public pure {
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(pointer.unsafeAsBytes32Array().startPointer()));
    }

    function testBytes32ArrayDataPointer(bytes32[] memory array) public pure {
        assertEq(Pointer.unwrap(array.startPointer()) + 0x20, Pointer.unwrap(array.dataPointer()));
    }

    function testBytes32ArrayEndPointer(bytes32[] memory array) public pure {
        assertEq(Pointer.unwrap(array.dataPointer()) + (array.length * 0x20), Pointer.unwrap(array.endPointer()));
    }
}
