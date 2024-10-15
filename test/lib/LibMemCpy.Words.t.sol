// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import "forge-std/Test.sol";

import "src/lib/LibMemCpy.sol";
import "src/lib/LibUint256Array.sol";
import "src/lib/LibPointer.sol";

contract LibMemCpyWordsTest is Test {
    using LibPointer for Pointer;
    using LibUint256Array for uint256[];

    function testCopyFuzz(uint256[] memory source_, uint256 suffix_) public {
        uint256[] memory target_ = new uint256[](source_.length);
        uint256 end_;
        assembly {
            end_ := add(target_, add(0x20, mul(mload(target_), 0x20)))
            mstore(0x40, add(end_, 0x20))
            mstore(end_, suffix_)
        }
        LibMemCpy.unsafeCopyWordsTo(source_.dataPointer(), target_.dataPointer(), source_.length);
        assertEq(source_, target_);
        uint256 suffixAfter_;
        assembly {
            suffixAfter_ := mload(end_)
        }
        assertEq(suffix_, suffixAfter_);
    }

    function testCopyMultiWordFuzz(uint256[] memory source_, uint256 suffix_) public {
        vm.assume(source_.length > 0x20);
        testCopyFuzz(source_, suffix_);
    }

    function testCopyMaxSuffixFuzz(uint256[] memory source_) public {
        testCopyFuzz(source_, type(uint256).max);
    }

    function testCopyEmptyZero() public {
        testCopyFuzz(new uint256[](0), 0);
    }

    function testCopySimple() public {
        uint256[] memory source_ = new uint256[](3);
        source_[0] = 1;
        source_[1] = 2;
        source_[2] = 3;
        testCopyFuzz(source_, type(uint256).max);
    }

    // Uses somewhat circular logic to test that existing data in target cannot
    // corrupt copying from source somehow.
    function testCopyDirtyTargetFuzz(uint256[] memory source_, uint256[] memory target_) public {
        vm.assume(target_.length >= source_.length);
        uint256[] memory remainder_ = new uint256[](target_.length - source_.length);
        LibMemCpy.unsafeCopyWordsTo(
            target_.dataPointer().unsafeAddWords(source_.length), remainder_.dataPointer(), remainder_.length
        );
        uint256[] memory remainderCopy_ = new uint256[](remainder_.length);
        LibMemCpy.unsafeCopyWordsTo(remainder_.dataPointer(), remainderCopy_.dataPointer(), remainder_.length);

        LibMemCpy.unsafeCopyWordsTo(source_.dataPointer(), target_.dataPointer(), source_.length);
        target_.truncate(source_.length);
        assertEq(source_, target_);
        assertEq(remainder_, remainderCopy_);
    }
}
