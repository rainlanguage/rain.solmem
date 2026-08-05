// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibPointer, Pointer} from "src/lib/LibPointer.sol";
import {LibUint256Array} from "src/lib/LibStackPointer.sol";
import {UnalignedStackPointer} from "src/error/ErrStackPointer.sol";
import {
    LibStackSentinel,
    Sentinel,
    MissingSentinel,
    ZeroSentinelTupleSize,
    InvalidStackBounds,
    UnallocatedStack
} from "src/lib/LibStackSentinel.sol";

contract LibStackSentinelTest is Test {
    using LibUint256Array for uint256[];
    using LibPointer for Pointer;
    using LibStackSentinel for Pointer;

    function externalConsumeSentinelTuplesStack(uint256[] memory stack, Sentinel sentinel, uint256 n)
        external
        pure
        returns (Pointer, Pointer)
    {
        Pointer stackBottom = stack.dataPointer();
        Pointer stackTop = stack.endPointer();
        return stackBottom.consumeSentinelTuples(stackTop, sentinel, n);
    }

    function testConsumeSentinelTuplesNZeroError(uint256[] memory stack, Sentinel sentinel) external {
        vm.expectRevert(abi.encodeWithSelector(ZeroSentinelTupleSize.selector));
        this.externalConsumeSentinelTuplesStack(stack, sentinel, 0);
    }

    /// A zero tuple size is reported ahead of anything that is wrong with the
    /// bounds.
    function testConsumeSentinelTuplesNZeroErrorPrecedence(
        Pointer upper,
        uint8 words,
        uint8 offsetSeed,
        Sentinel sentinel
    ) external {
        // `lower` is above `upper` AND not a whole number of words from it, so
        // both of the pointer guards would fire too.
        uint256 distance = (uint256(words) * 0x20) + ((uint256(offsetSeed) % 0x1f) + 1);
        vm.assume(Pointer.unwrap(upper) <= type(uint256).max - distance);
        Pointer lower = Pointer.wrap(Pointer.unwrap(upper) + distance);

        vm.expectRevert(abi.encodeWithSelector(ZeroSentinelTupleSize.selector));
        this.consumeSentinelTuplesExternal(lower, upper, sentinel, 0);
    }

    function testConsumeSentinelTuplesMultiSize(
        uint256[] memory stack,
        Sentinel sentinel,
        uint8 lengthAlpha,
        uint8 lengthBravo
    ) public pure {
        for (uint256 i = 0; i < stack.length; i++) {
            //slither-disable-next-line calls-loop
            vm.assume(stack[i] != Sentinel.unwrap(sentinel));
        }
        vm.assume(lengthAlpha > 1);
        vm.assume(lengthBravo > 1);
        vm.assume(stack.length >= uint256(lengthAlpha) + uint256(lengthBravo));

        stack[stack.length - lengthAlpha] = Sentinel.unwrap(sentinel);
        stack[stack.length - (lengthAlpha + lengthBravo)] = Sentinel.unwrap(sentinel);

        Pointer stackBottom = stack.dataPointer();
        (Pointer stackTopAlpha, Pointer tuplesPointerAlpha) =
            stackBottom.consumeSentinelTuples(stack.endPointer(), sentinel, lengthAlpha - 1);
        (Pointer stackTopBravo, Pointer tuplesPointerBravo) =
            stackBottom.consumeSentinelTuples(stackTopAlpha, sentinel, lengthBravo - 1);

        assertEq(Pointer.unwrap(stack.endPointer().unsafeSubWords(lengthAlpha)), Pointer.unwrap(stackTopAlpha));
        assertEq(
            Pointer.unwrap(stack.endPointer().unsafeSubWords(lengthAlpha + lengthBravo)), Pointer.unwrap(stackTopBravo)
        );

        assertEq(tuplesPointerAlpha.unsafeReadWord(), bytes32(uint256(1)));
        assertEq(tuplesPointerBravo.unsafeReadWord(), bytes32(uint256(1)));

        assertEq(
            Pointer.unwrap(stackTopAlpha.unsafeAddWord()), uint256(tuplesPointerAlpha.unsafeAddWord().unsafeReadWord())
        );
        assertEq(
            Pointer.unwrap(stackTopBravo.unsafeAddWord()), uint256(tuplesPointerBravo.unsafeAddWord().unsafeReadWord())
        );
    }

    /// We can read multiple sentinels from the stack, and each time we consume
    /// we stop at the first discovered sentinel.
    function testConsumeSentinelTuplesMultiple(uint256[] memory stack, Sentinel sentinel, uint8 length) public pure {
        for (uint256 i = 0; i < stack.length; i++) {
            //slither-disable-next-line calls-loop
            vm.assume(stack[i] != Sentinel.unwrap(sentinel));
        }
        vm.assume(length > 1);
        vm.assume(stack.length % length == 0);
        for (uint256 i = 0; i < stack.length; i += length) {
            stack[i] = Sentinel.unwrap(sentinel);
        }

        Pointer stackBottom = stack.dataPointer();
        Pointer stackTop = stack.endPointer();
        Pointer tuplesPointer;

        uint256 count = 0;
        while (Pointer.unwrap(stackTop) > Pointer.unwrap(stackBottom)) {
            Pointer stackTopBefore = stackTop;
            (stackTop, tuplesPointer) = stackBottom.consumeSentinelTuples(stackTop, sentinel, length - 1);
            assertEq(Pointer.unwrap(stackTopBefore) - Pointer.unwrap(stackTop), uint256(length) * 0x20);
            // Length of tuples should be 1 because length - 1 is the _size_ of
            // each tuple item.
            assertEq(tuplesPointer.unsafeReadWord(), bytes32(uint256(1)));
            count++;
        }
        assertEq(count * length, stack.length);
    }

    function testConsumeSentinelTuples(uint256[] memory stack, Sentinel sentinel, uint8 sentinelIndex) public pure {
        for (uint256 i = 0; i < stack.length; i++) {
            //slither-disable-next-line calls-loop
            vm.assume(stack[i] != Sentinel.unwrap(sentinel));
        }
        vm.assume(sentinelIndex < stack.length);
        // Align the sentinels with clean tuples.
        vm.assume((stack.length - (sentinelIndex + 1)) % 2 == 0);
        stack[sentinelIndex] = Sentinel.unwrap(sentinel);

        // The tuples array MUST be allocated exactly at the free memory
        // pointer, i.e. with no gap between the prior allocation and the
        // length slot of the tuples array.
        Pointer expectedTuplesPointer = LibPointer.allocatedMemoryPointer();

        (Pointer sentinelPointer, Pointer tuplesPointer) =
            stack.dataPointer().consumeSentinelTuples(stack.endPointer(), sentinel, 2);
        assertEq(Pointer.unwrap(tuplesPointer), Pointer.unwrap(expectedTuplesPointer));
        uint256[2][] memory tuples;
        assembly ("memory-safe") {
            tuples := tuplesPointer
        }

        Pointer expectedSentinelPointer;
        assembly ("memory-safe") {
            expectedSentinelPointer := add(stack, add(0x20, mul(0x20, sentinelIndex)))
        }
        assertEq(Pointer.unwrap(sentinelPointer), Pointer.unwrap(expectedSentinelPointer));
        assertTrue(((Pointer.unwrap(stack.endPointer()) - (Pointer.unwrap(sentinelPointer) + 0x20)) / 0x20) % 2 == 0);
        uint256 j = 0;
        for (uint256 i = sentinelIndex + 1; i < stack.length; i += 2) {
            assertEq(stack[i], tuples[j][0]);
            assertEq(stack[i + 1], tuples[j][1]);
            j++;
        }
        assertEq(tuples.length * 2, stack.length - (sentinelIndex + 1));

        assertEq(
            Pointer.unwrap(tuplesPointer.unsafeAddWords(tuples.length + 1)),
            Pointer.unwrap(LibPointer.allocatedMemoryPointer())
        );
    }

    function testConsumeSentinelTuples3(uint256[] memory stack, Sentinel sentinel, uint8 sentinelIndex) public pure {
        for (uint256 i = 0; i < stack.length; i++) {
            //slither-disable-next-line calls-loop
            vm.assume(stack[i] != Sentinel.unwrap(sentinel));
        }
        vm.assume(sentinelIndex < stack.length);
        // Align the sentinels with clean tuples.
        vm.assume((stack.length - (sentinelIndex + 1)) % 3 == 0);
        stack[sentinelIndex] = Sentinel.unwrap(sentinel);

        // The tuples array MUST be allocated exactly at the free memory
        // pointer, i.e. with no gap between the prior allocation and the
        // length slot of the tuples array.
        Pointer expectedTuplesPointer = LibPointer.allocatedMemoryPointer();

        (Pointer sentinelPointer, Pointer tuplesPointer) =
            stack.dataPointer().consumeSentinelTuples(stack.endPointer(), sentinel, 3);
        assertEq(Pointer.unwrap(tuplesPointer), Pointer.unwrap(expectedTuplesPointer));
        uint256[3][] memory tuples;
        assembly ("memory-safe") {
            tuples := tuplesPointer
        }

        Pointer expectedSentinelPointer;
        assembly ("memory-safe") {
            expectedSentinelPointer := add(stack, add(0x20, mul(0x20, sentinelIndex)))
        }
        assertEq(Pointer.unwrap(sentinelPointer), Pointer.unwrap(expectedSentinelPointer));
        assertEq(((Pointer.unwrap(stack.endPointer()) - (Pointer.unwrap(sentinelPointer) + 0x20)) / 0x20) % 3, 0);
        uint256 j = 0;
        for (uint256 i = sentinelIndex + 1; i < stack.length; i += 3) {
            assertEq(stack[i], tuples[j][0]);
            assertEq(stack[i + 1], tuples[j][1]);
            assertEq(stack[i + 2], tuples[j][2]);
            j++;
        }
        assertEq(tuples.length * 3, stack.length - (sentinelIndex + 1));

        assertEq(
            Pointer.unwrap(tuplesPointer.unsafeAddWords(tuples.length + 1)),
            Pointer.unwrap(LibPointer.allocatedMemoryPointer())
        );
    }

    function consumeSentinelTuplesExternal(uint256[] memory stack, Sentinel sentinel)
        external
        pure
        returns (Pointer, Pointer)
    {
        return stack.dataPointer().consumeSentinelTuples(stack.endPointer(), sentinel, 2);
    }

    function testConsumeSentinelTuplesMissingSentinel(uint256[] memory stack, Sentinel sentinel) public {
        for (uint256 i = 0; i < stack.length; i++) {
            //slither-disable-next-line calls-loop
            vm.assume(stack[i] != Sentinel.unwrap(sentinel));
        }

        vm.expectRevert(abi.encodeWithSelector(MissingSentinel.selector, sentinel));
        (Pointer sentinelPointer, Pointer tuplesPointer) = this.consumeSentinelTuplesExternal(stack, sentinel);
        (sentinelPointer);
        (tuplesPointer);
    }

    function testConsumeSentinelTuplesOddSentinel(uint256[] memory stack, Sentinel sentinel, uint8 sentinelIndex)
        public
    {
        for (uint256 i = 0; i < stack.length; i++) {
            //slither-disable-next-line calls-loop
            vm.assume(stack[i] != Sentinel.unwrap(sentinel));
        }
        vm.assume(sentinelIndex < stack.length);
        // UNalign the sentinel with clean tuples.
        vm.assume((stack.length - (sentinelIndex + 1)) % 2 == 1);

        stack[sentinelIndex] = Sentinel.unwrap(sentinel);

        vm.expectRevert(abi.encodeWithSelector(MissingSentinel.selector, sentinel));
        (Pointer sentinelPointer, Pointer tuplesPointer) = this.consumeSentinelTuplesExternal(stack, sentinel);
        (sentinelPointer);
        (tuplesPointer);
    }

    function consumeSentinelTuplesExternal(Pointer lower, Pointer upper, Sentinel sentinel, uint256 n) external pure {
        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, n);
        (sentinelPointer);
        (tuplesPointer);
    }

    function testConsumeSentinelTuplesUnderflowError(Pointer lower, uint8 words, Sentinel sentinel, uint256 n) public {
        // If the sentinel is easy to collide with then it might just match and
        // not underflow, which defeats the purpose of the test.
        vm.assume(Sentinel.unwrap(sentinel) > type(uint128).max);
        vm.assume(Pointer.unwrap(lower) < n);
        vm.assume(words > 0);
        // `upper` is a whole number of words above `lower` so the scan runs
        // rather than being refused as unaligned.
        uint256 distance = uint256(words) * 0x20;
        vm.assume(Pointer.unwrap(lower) <= type(uint256).max - distance);
        Pointer upper = Pointer.wrap(Pointer.unwrap(lower) + distance);

        // Underflow will revert because it will run out of gas attempting to
        // loop over infinity.
        vm.expectRevert();
        this.consumeSentinelTuplesExternal(lower, upper, sentinel, n);
    }

    /// Two pointers that are not a whole number of words apart cannot describe
    /// a stack of words, so the scan is refused.
    function testConsumeSentinelTuplesUnalignedError(
        Pointer lower,
        uint8 words,
        uint8 offsetSeed,
        Sentinel sentinel,
        uint256 n
    ) public {
        vm.assume(n > 0);
        // Any sub word distance between the two pointers.
        uint256 distance = (uint256(words) * 0x20) + ((uint256(offsetSeed) % 0x1f) + 1);
        vm.assume(Pointer.unwrap(lower) <= type(uint256).max - distance);
        Pointer upper = Pointer.wrap(Pointer.unwrap(lower) + distance);

        vm.expectRevert(abi.encodeWithSelector(UnalignedStackPointer.selector, lower, upper));
        this.consumeSentinelTuplesExternal(lower, upper, sentinel, n);
    }

    /// Lays out real memory such that the word stepped scan down from an
    /// unaligned `upper` steps over the whole stack and lands on a sentinel
    /// sitting below `lower`.
    function consumeSentinelTuplesBelowLowerExternal(Sentinel sentinel) external pure returns (Pointer, Pointer) {
        Pointer lower;
        Pointer upper;
        assembly ("memory-safe") {
            let base := mload(0x40)
            mstore(0x40, add(base, 0x100))
            lower := add(base, 0x20)
            // 0x30 is not a whole number of words.
            upper := add(lower, 0x30)
            // Zero the two words that are actually in the stack so nothing in
            // range and nothing straddling them can match the sentinel.
            mstore(lower, 0)
            mstore(add(lower, 0x20), 0)
            // The sentinel sits half a word below the bottom of the stack,
            // exactly where the second probe of the scan reads.
            mstore(sub(lower, 0x10), sentinel)
        }
        return lower.consumeSentinelTuples(upper, sentinel, 1);
    }

    function testConsumeSentinelTuplesBelowLower(Sentinel sentinel) external view {
        vm.assume(Sentinel.unwrap(sentinel) != 0);

        (bool success, bytes memory data) =
            address(this).staticcall(abi.encodeCall(this.consumeSentinelTuplesBelowLowerExternal, (sentinel)));

        assertFalse(success);
        assertEq(data.length, 4 + 0x40);
        bytes4 selector;
        uint256 lower;
        uint256 upper;
        assembly ("memory-safe") {
            selector := mload(add(data, 0x20))
            lower := mload(add(data, 0x24))
            upper := mload(add(data, 0x44))
        }
        assertEq(selector, UnalignedStackPointer.selector);
        assertEq(upper - lower, 0x30);
    }

    /// Neither pointer needs to be aligned in absolute terms, only with each
    /// other, so a sub word offset shared by both pointers builds tuples as
    /// normal.
    function testConsumeSentinelTuplesSharedSubWordOffset(
        Sentinel sentinel,
        uint8 offsetSeed,
        uint256 item0,
        uint256 item1
    ) external pure {
        vm.assume(Sentinel.unwrap(sentinel) != item0);
        vm.assume(Sentinel.unwrap(sentinel) != item1);
        uint256 offset = (uint256(offsetSeed) % 0x1f) + 1;

        Pointer lower;
        assembly ("memory-safe") {
            let base := mload(0x40)
            mstore(0x40, add(base, 0x100))
            lower := add(base, offset)
            mstore(lower, sentinel)
            mstore(add(lower, 0x20), item0)
            mstore(add(lower, 0x40), item1)
        }

        (Pointer sentinelPointer, Pointer tuplesPointer) =
            lower.consumeSentinelTuples(lower.unsafeAddWords(3), sentinel, 1);

        assertEq(Pointer.unwrap(sentinelPointer), Pointer.unwrap(lower));
        assertEq(tuplesPointer.unsafeReadWord(), bytes32(uint256(2)));

        uint256[1][] memory tuples;
        assembly ("memory-safe") {
            tuples := tuplesPointer
        }
        assertEq(tuples[0][0], item0);
        assertEq(tuples[1][0], item1);
    }

    function testConsumeSentinelTuplesInitialStateUnderflowError(Pointer lower, Pointer upper, Sentinel sentinel)
        public
    {
        vm.assume(Pointer.unwrap(upper) < Pointer.unwrap(lower));

        vm.expectRevert(abi.encodeWithSelector(InvalidStackBounds.selector, lower, upper));
        this.consumeSentinelTuplesExternal(lower, upper, sentinel, 2);
    }

    function consumeSentinelTuplesEmptyErrorExternal(Sentinel sentinel) external pure {
        Pointer lower;
        assembly ("memory-safe") {
            lower := mload(0x40)
            mstore(lower, sentinel)
        }

        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(lower, sentinel, 2);
        (sentinelPointer);
        (tuplesPointer);
    }

    function testConsumeSentinelTuplesEmptyError(Sentinel sentinel) external {
        vm.expectRevert(abi.encodeWithSelector(MissingSentinel.selector, sentinel));
        this.consumeSentinelTuplesEmptyErrorExternal(sentinel);
    }

    function testConsumeSentinelTuplesEmpty(Sentinel sentinel) external pure {
        Pointer lower;
        assembly ("memory-safe") {
            lower := mload(0x40)
            // Allocate the one word stack so that it sits at or below the
            // allocated memory pointer.
            mstore(0x40, add(lower, 0x20))
            mstore(lower, sentinel)
        }

        // The tuples array MUST be allocated exactly at the free memory
        // pointer, i.e. with no gap between the prior allocation and the
        // length slot of the tuples array.
        Pointer expectedTuplesPointer = LibPointer.allocatedMemoryPointer();

        (Pointer sentinelPointer, Pointer tuplesPointer) =
            lower.consumeSentinelTuples(lower.unsafeAddWord(), sentinel, 2);
        assertEq(Pointer.unwrap(sentinelPointer), Pointer.unwrap(lower));
        assertEq(tuplesPointer.unsafeReadWord(), 0);
        // A zero length tuples array is still allocated exactly at the free
        // memory pointer, and consumes exactly one word for its length.
        assertEq(Pointer.unwrap(tuplesPointer), Pointer.unwrap(expectedTuplesPointer));
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(tuplesPointer.unsafeAddWord()));
        // The stack is left intact because the tuples array is built above it.
        assertEq(lower.unsafeReadWord(), bytes32(Sentinel.unwrap(sentinel)));
    }

    /// Stages a stack at the allocated memory pointer WITHOUT allocating it,
    /// exactly as a caller building a temporary structure above the free memory
    /// pointer would. `consume` false reports the pointers that were staged
    /// without consuming them. Both variants decode the same static argument
    /// types so both see the same allocated memory pointer.
    function consumeSentinelTuplesUnallocatedExternal(Sentinel sentinel, uint256 words, bool consume)
        external
        pure
        returns (Pointer upper, Pointer allocated)
    {
        Pointer lower;
        assembly ("memory-safe") {
            allocated := mload(0x40)
            lower := allocated
            upper := add(lower, mul(words, 0x20))
            mstore(lower, sentinel)
        }
        if (consume) {
            (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, 2);
            (sentinelPointer);
            (tuplesPointer);
        }
    }

    /// A stack above the allocated memory pointer is where the tuples array
    /// that describes it would be built, so consuming it would overwrite it.
    /// This is refused rather than returning a well formed array of corrupt
    /// references.
    function testConsumeSentinelTuplesUnallocatedStackError(Sentinel sentinel, uint8 tupleCount) external {
        // An odd number of words puts the sentinel at the bottom of the stack
        // in alignment with the 2 item tuples above it.
        uint256 words = (uint256(tupleCount) % 8) * 2 + 1;

        (Pointer upper, Pointer allocated) = this.consumeSentinelTuplesUnallocatedExternal(sentinel, words, false);
        assertEq(Pointer.unwrap(upper), Pointer.unwrap(allocated) + words * 0x20);

        vm.expectRevert(abi.encodeWithSelector(UnallocatedStack.selector, upper, allocated));
        this.consumeSentinelTuplesUnallocatedExternal(sentinel, words, true);
    }

    /// Stages a stack above the allocated memory pointer and leaves it as the
    /// untouched (therefore zero) memory it already is, so it cannot contain a
    /// non zero sentinel.
    function consumeSentinelTuplesUnallocatedMissingExternal(Sentinel sentinel) external pure {
        Pointer lower;
        Pointer upper;
        assembly ("memory-safe") {
            lower := mload(0x40)
            upper := add(lower, 0x60)
        }
        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, 2);
        (sentinelPointer);
        (tuplesPointer);
    }

    /// The search for the sentinel only reads memory, so a stack above the
    /// allocated memory pointer with no sentinel in it is reported as a missing
    /// sentinel. Nothing is allocated on that path so there is nothing to
    /// overwrite.
    function testConsumeSentinelTuplesUnallocatedMissingSentinel(Sentinel sentinel) external {
        // A zero sentinel would be found in the untouched memory the stack
        // sits in.
        vm.assume(Sentinel.unwrap(sentinel) != 0);

        vm.expectRevert(abi.encodeWithSelector(MissingSentinel.selector, sentinel));
        this.consumeSentinelTuplesUnallocatedMissingExternal(sentinel);
    }

    /// A stack that ends exactly at the allocated memory pointer is entirely
    /// within allocated memory, so it is consumed and the tuples array is built
    /// directly above it, leaving the stack it references intact.
    function testConsumeSentinelTuplesUpperAtAllocated(Sentinel sentinel, uint256 item0, uint256 item1) external pure {
        vm.assume(Sentinel.unwrap(sentinel) != item0);
        vm.assume(Sentinel.unwrap(sentinel) != item1);

        Pointer lower;
        assembly ("memory-safe") {
            lower := mload(0x40)
            mstore(0x40, add(lower, 0x60))
            mstore(lower, sentinel)
            mstore(add(lower, 0x20), item0)
            mstore(add(lower, 0x40), item1)
        }
        Pointer upper = lower.unsafeAddWords(3);
        assertEq(Pointer.unwrap(upper), Pointer.unwrap(LibPointer.allocatedMemoryPointer()));

        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, 2);
        assertEq(Pointer.unwrap(sentinelPointer), Pointer.unwrap(lower));
        assertEq(Pointer.unwrap(tuplesPointer), Pointer.unwrap(upper));

        uint256[2][] memory tuples;
        assembly ("memory-safe") {
            tuples := tuplesPointer
        }
        assertEq(tuples.length, 1);
        assertEq(tuples[0][0], item0);
        assertEq(tuples[0][1], item1);
        // The stack is left intact because the tuples array is built above it.
        assertEq(lower.unsafeReadWord(), bytes32(Sentinel.unwrap(sentinel)));
        assertEq(lower.unsafeAddWord().unsafeReadWord(), bytes32(item0));
        assertEq(lower.unsafeAddWords(2).unsafeReadWord(), bytes32(item1));
    }

    function testConsumeSentinelTuplesGas0() external pure {
        Pointer lower;
        Pointer upper;
        Sentinel sentinel = Sentinel.wrap(50);
        assembly ("memory-safe") {
            lower := mload(0x40)
            upper := add(lower, 0x20)
            // Allocate the stack so that it sits at or below the allocated
            // memory pointer.
            mstore(0x40, upper)
            mstore(lower, sentinel)
        }
        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, 2);
        (sentinelPointer);
        (tuplesPointer);
    }

    function testConsumeSentinelTuplesGas1() public pure {
        Pointer lower;
        Pointer upper;
        Sentinel sentinel = Sentinel.wrap(50);
        assembly ("memory-safe") {
            lower := mload(0x40)
            upper := add(lower, 0x60)
            // Allocate the stack so that it sits at or below the allocated
            // memory pointer.
            mstore(0x40, upper)
            mstore(lower, sentinel)
        }
        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, 2);
        (sentinelPointer);
        (tuplesPointer);
    }

    function testConsumeSentinelTuplesGas2() public pure {
        Pointer lower;
        Pointer upper;
        Sentinel sentinel = Sentinel.wrap(50);
        assembly ("memory-safe") {
            lower := mload(0x40)
            upper := add(lower, 0xa0)
            // Allocate the stack so that it sits at or below the allocated
            // memory pointer.
            mstore(0x40, upper)
            mstore(lower, sentinel)
        }
        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, 2);
        (sentinelPointer);
        (tuplesPointer);
    }

    function testConsumeSentinelTuplesGas3() public pure {
        Pointer lower;
        Pointer upper;
        Sentinel sentinel = Sentinel.wrap(50);
        assembly ("memory-safe") {
            lower := mload(0x40)
            upper := add(lower, 0xe0)
            // Allocate the stack so that it sits at or below the allocated
            // memory pointer.
            mstore(0x40, upper)
            mstore(lower, sentinel)
        }
        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, 2);
        (sentinelPointer);
        (tuplesPointer);
    }
}
