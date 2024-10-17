// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";

import {LibMemory} from "src/lib/LibMemory.sol";
import {LibMemorySlow} from "test/lib/LibMemorySlow.sol";

contract LibMemoryTest is Test {
    function testMemoryIsAlignedReference(bytes memory) public pure {
        assertEq(LibMemory.memoryIsAligned(), LibMemorySlow.memoryIsAlignedSlow());
    }
}
