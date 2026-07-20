// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

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

    /// The copy MUST move words from source into target, and MUST NOT move
    /// words from target into source. Both arrays hold distinct non-zero values
    /// so that a reversed copy is observable in both directions.
    function testCopyWordsDirection() public pure {
        uint256[] memory source = new uint256[](3);
        source[0] = 7;
        source[1] = 8;
        source[2] = 9;

        uint256[] memory target = new uint256[](3);
        target[0] = 111;
        target[1] = 222;
        target[2] = 333;

        LibMemCpy.unsafeCopyWordsTo(source.dataPointer(), target.dataPointer(), 3);

        assertEq(target[0], 7);
        assertEq(target[1], 8);
        assertEq(target[2], 9);

        // Source is left completely untouched.
        assertEq(source[0], 7);
        assertEq(source[1], 8);
        assertEq(source[2], 9);
    }

    /// `mcopy` has memmove semantics, so a copy into an overlapping region at a
    /// HIGHER address MUST read the original source words, not words that the
    /// copy itself has already written.
    function testCopyWordsOverlapForward() public pure {
        uint256[] memory buffer = new uint256[](6);
        buffer[0] = 1;
        buffer[1] = 2;
        buffer[2] = 3;
        buffer[3] = 4;
        buffer[4] = 5;
        buffer[5] = 6;

        // Copy buffer[0:4] over buffer[2:6]. Source and target overlap by two
        // words with the target above the source.
        LibMemCpy.unsafeCopyWordsTo(buffer.dataPointer(), buffer.dataPointer().unsafeAddWords(2), 4);

        assertEq(buffer[0], 1);
        assertEq(buffer[1], 2);
        assertEq(buffer[2], 1);
        assertEq(buffer[3], 2);
        assertEq(buffer[4], 3);
        assertEq(buffer[5], 4);
    }

    /// Overlapping copy into a LOWER address must also preserve the original
    /// source words.
    function testCopyWordsOverlapBackward() public pure {
        uint256[] memory buffer = new uint256[](6);
        buffer[0] = 1;
        buffer[1] = 2;
        buffer[2] = 3;
        buffer[3] = 4;
        buffer[4] = 5;
        buffer[5] = 6;

        // Copy buffer[2:6] over buffer[0:4].
        LibMemCpy.unsafeCopyWordsTo(buffer.dataPointer().unsafeAddWords(2), buffer.dataPointer(), 4);

        assertEq(buffer[0], 3);
        assertEq(buffer[1], 4);
        assertEq(buffer[2], 5);
        assertEq(buffer[3], 6);
        assertEq(buffer[4], 5);
        assertEq(buffer[5], 6);
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
