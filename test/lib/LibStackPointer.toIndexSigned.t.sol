// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import "forge-std/Test.sol";

import "src/lib/LibPointer.sol";
import "src/lib/LibStackPointer.sol";

/// @title LibStackPointerToIndexSignedTest
/// Exercise the conversion of stack pointers to signed indexes.
contract LibStackPointerToIndexSignedTest is Test {
    using LibPointer for Pointer;
    using LibStackPointer for Pointer;

    /// Test that positive indexes are converted correctly.
    function testUnsafeToIndexPositive(Pointer lower, Pointer upper) public {
        lower = Pointer.wrap(bound(Pointer.unwrap(lower), 0, type(uint256).max));
        lower = Pointer.wrap(Pointer.unwrap(lower) - (Pointer.unwrap(lower) % 0x20));

        upper = Pointer.wrap(bound(Pointer.unwrap(upper), Pointer.unwrap(lower), type(uint256).max));
        upper = Pointer.wrap(Pointer.unwrap(upper) - (Pointer.unwrap(upper) % 0x20));

        assertTrue(lower.toIndexSigned(upper) >= 0, "index should be positive");
        uint256 lowerIndex = Pointer.unwrap(lower) / 0x20;
        uint256 upperIndex = Pointer.unwrap(upper) / 0x20;
        assertEq(lower.toIndexSigned(upper), int256(upperIndex - lowerIndex));
    }

    /// Test that negative indexes are converted correctly.
    function testUnsafeToIndexNegative(Pointer lower, Pointer upper) public {
        // Lower has to be at least 32 bytes above 0, otherwise upper can't be
        // below it to show a negative index.
        lower = Pointer.wrap(bound(Pointer.unwrap(lower), 0x20, type(uint256).max));
        lower = Pointer.wrap(Pointer.unwrap(lower) - (Pointer.unwrap(lower) % 0x20));

        upper = Pointer.wrap(bound(Pointer.unwrap(upper), 0, Pointer.unwrap(lower.unsafeSubWord())));
        upper = Pointer.wrap(Pointer.unwrap(upper) - (Pointer.unwrap(upper) % 0x20));

        assertTrue(lower.toIndexSigned(upper) < 0, "index should be negative");
        uint256 lowerIndex = Pointer.unwrap(lower) / 0x20;
        uint256 upperIndex = Pointer.unwrap(upper) / 0x20;
        assertEq(lower.toIndexSigned(upper), -int256(lowerIndex - upperIndex));
    }

    /// Test that unaligned lower pointers throw.
    function testUnsafeToIndexUnalignedLower(Pointer lower, Pointer upper) public {
        lower = Pointer.wrap(bound(Pointer.unwrap(lower), 0x10, type(uint256).max));
        vm.assume(Pointer.unwrap(lower) % 0x20 != 0);
        upper = Pointer.wrap(bound(Pointer.unwrap(upper), Pointer.unwrap(lower), type(uint256).max));
        vm.assume(Pointer.unwrap(upper) % 0x20 == 0);
        vm.expectRevert(abi.encodeWithSelector(UnalignedStackPointer.selector, lower));
        lower.toIndexSigned(upper);
    }

    /// Test that unaligned upper pointers throw.
    function testUnsafeToIndexUnalignedUpper(Pointer lower, Pointer upper) public {
        lower = Pointer.wrap(bound(Pointer.unwrap(lower), 0, type(uint256).max));
        vm.assume(Pointer.unwrap(lower) % 0x20 == 0);
        upper = Pointer.wrap(bound(Pointer.unwrap(upper), Pointer.unwrap(lower), type(uint256).max));
        vm.assume(Pointer.unwrap(upper) % 0x20 != 0);
        vm.expectRevert(abi.encodeWithSelector(UnalignedStackPointer.selector, upper));
        lower.toIndexSigned(upper);
    }
}
