// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibMemCpy} from "src/lib/LibMemCpy.sol";
import {LibUint256Array, Pointer} from "src/lib/LibUint256Array.sol";
import {LibPointer} from "src/lib/LibPointer.sol";

contract LibMemCpyWordsTest is Test {
    using LibPointer for Pointer;
    using LibUint256Array for uint256[];

    function testCopyFuzz(uint256[] memory source, uint256 suffix) public pure {
        uint256[] memory target = new uint256[](source.length);
        uint256 end;
        assembly {
            end := add(target, add(0x20, mul(mload(target), 0x20)))
            mstore(0x40, add(end, 0x20))
            mstore(end, suffix)
        }
        LibMemCpy.unsafeCopyWordsTo(source.dataPointer(), target.dataPointer(), source.length);
        assertEq(source, target);
        uint256 suffixAfter;
        assembly {
            suffixAfter := mload(end)
        }
        assertEq(suffix, suffixAfter);
    }

    function testCopyMultiWordFuzz(uint256[] memory source, uint256 suffix) public pure {
        vm.assume(source.length > 0x20);
        testCopyFuzz(source, suffix);
    }

    function testCopyMaxSuffixFuzz(uint256[] memory source) public pure {
        testCopyFuzz(source, type(uint256).max);
    }

    function testCopyEmptyZero() public pure {
        testCopyFuzz(new uint256[](0), 0);
    }

    function testCopySimple() public pure {
        uint256[] memory source = new uint256[](3);
        source[0] = 1;
        source[1] = 2;
        source[2] = 3;
        testCopyFuzz(source, type(uint256).max);
    }

    // Uses somewhat circular logic to test that existing data in target cannot
    // corrupt copying from source somehow.
    function testCopyDirtyTargetFuzz(uint256[] memory source, uint256[] memory target) public pure {
        vm.assume(target.length >= source.length);
        uint256[] memory remainder = new uint256[](target.length - source.length);
        LibMemCpy.unsafeCopyWordsTo(
            target.dataPointer().unsafeAddWords(source.length), remainder.dataPointer(), remainder.length
        );
        uint256[] memory remainderCopy = new uint256[](remainder.length);
        LibMemCpy.unsafeCopyWordsTo(remainder.dataPointer(), remainderCopy.dataPointer(), remainder.length);

        LibMemCpy.unsafeCopyWordsTo(source.dataPointer(), target.dataPointer(), source.length);
        target.truncate(source.length);
        assertEq(source, target);
        assertEq(remainder, remainderCopy);
    }
}
