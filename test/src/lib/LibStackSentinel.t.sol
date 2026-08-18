// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibPointer, Pointer} from "src/lib/LibPointer.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";
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

    /// A cap on the gas forwarded to a scan that is expected to fail, so that a
    /// failure which exhausts gas burns a bounded amount instead of the whole
    /// test's budget. This is a property of the harness. It asserts nothing
    /// about the implementation and no test may read a claim out of it.
    uint256 internal constant SCAN_GAS_CAP = 1_000_000;

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
        this.consumeSentinelTuplesRawExternal(lower, upper, sentinel, 0);
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

    /// An occurrence of the sentinel VALUE above the terminator that is off the
    /// tuple stride is tuple data, not a terminator, and is built into the
    /// tuples untouched.
    function testConsumeSentinelTuplesOffStrideSentinelIsData(Sentinel sentinel, uint256 item) external pure {
        vm.assume(Sentinel.unwrap(sentinel) != item);

        Pointer lower;
        assembly ("memory-safe") {
            lower := mload(0x40)
            mstore(0x40, add(lower, 0xa0))
            // The scan probes two words apart down from `upper`, so it lands on
            // words 4, 2 and 0. Word 2 terminates it and the sentinel at word 3
            // is never probed.
            mstore(lower, item)
            mstore(add(lower, 0x20), item)
            mstore(add(lower, 0x40), sentinel)
            mstore(add(lower, 0x60), sentinel)
            mstore(add(lower, 0x80), item)
        }

        (Pointer sentinelPointer, Pointer tuplesPointer) =
            lower.consumeSentinelTuples(lower.unsafeAddWords(5), sentinel, 2);
        assertEq(Pointer.unwrap(sentinelPointer), Pointer.unwrap(lower.unsafeAddWords(2)));

        uint256[2][] memory tuples;
        assembly ("memory-safe") {
            tuples := tuplesPointer
        }
        assertEq(tuples.length, 1);
        assertEq(tuples[0][0], Sentinel.unwrap(sentinel));
        assertEq(tuples[0][1], item);
    }

    function consumeSentinelTuplesRawExternal(Pointer lower, Pointer upper, Sentinel sentinel, uint256 n)
        external
        pure
        returns (Pointer sentinelPointer, Pointer tuplesPointer)
    {
        return lower.consumeSentinelTuples(upper, sentinel, n);
    }

    /// The safety property the library rests on, stated once and asserted
    /// nowhere else: a scan whose cursor steps outside the range it was given
    /// MUST NOT be reported as a success. A `sentinelPointer` outside
    /// `[lower, upper)` is an answer about memory the caller never described,
    /// and a caller consuming down to it reads whatever else lives there.
    ///
    /// HOW such a scan fails is NOT part of the property and MUST NOT be
    /// pinned. Gas exhaustion on an unaddressable read, an arithmetic panic and
    /// a typed `MissingSentinel` all satisfy it equally, and an implementation
    /// that traded one for another would still be safe. A test that demanded
    /// empty revert data, or a full burn of the forwarded gas, would forbid
    /// strictly better implementations while proving nothing extra about
    /// safety.
    function assertScanCannotSucceedSilently(bool success, Pointer lower, Pointer upper, Pointer sentinelPointer)
        internal
        pure
    {
        if (success) {
            assertGe(Pointer.unwrap(sentinelPointer), Pointer.unwrap(lower), "sentinel reported from below the range");
            assertLt(
                Pointer.unwrap(sentinelPointer), Pointer.unwrap(upper), "sentinel reported from at or above the range"
            );
        }
    }

    /// Every draw derives bounds and an `n` whose byte stride is strictly
    /// greater than `upper`, so the FIRST decrement of a cursor that starts at
    /// `upper` steps past zero. Every draw is therefore a genuine underflow,
    /// derived rather than assumed: the assumption this test replaced compared
    /// a byte address against a tuple count, so it admitted draws that never
    /// underflowed at all and were satisfied by an ordinary missing sentinel.
    function testConsumeSentinelTuplesUnderflowCannotSucceedSilently(
        Sentinel sentinel,
        uint8 lowerWords,
        uint8 rangeWords,
        uint8 excessTuples
    ) public {
        // A sentinel that is easy to collide with could match one of the words
        // the scan reads, ending the scan before it underflows.
        vm.assume(Sentinel.unwrap(sentinel) > type(uint128).max);

        // `0x80` is where the callee frame's free memory pointer starts, and
        // that frame decodes only static arguments, so it never allocates. At
        // `lowerWords == 0` the range therefore starts exactly AT the free
        // memory pointer and at higher draws above it; either way every word
        // the scan reads is untouched, therefore zero, therefore never the
        // sentinel. The bounds guards all pass: `upper` is above `lower` and a
        // whole number of words above it, so the scan runs. The range is at or
        // above the allocated memory pointer, but that is only checked once a
        // sentinel has been found, which never happens here.
        Pointer lower = Pointer.wrap(0x80 + uint256(lowerWords) * 0x20);
        Pointer upper = Pointer.wrap(Pointer.unwrap(lower) + (uint256(rangeWords) + 1) * 0x20);

        // Both pointers are word aligned so `n * 0x20` is strictly greater than
        // `upper`, which makes the first decrement of the cursor wrap below
        // zero. `n` stays small enough that `n * 0x20` itself cannot wrap.
        uint256 n = Pointer.unwrap(upper) / 0x20 + 1 + uint256(excessTuples);

        (bool success, bytes memory data) = address(this).call{gas: SCAN_GAS_CAP}(
            abi.encodeCall(this.consumeSentinelTuplesRawExternal, (lower, upper, sentinel, n))
        );

        Pointer sentinelPointer;
        if (success) {
            (sentinelPointer,) = abi.decode(data, (Pointer, Pointer));
        }
        assertScanCannotSucceedSilently(success, lower, upper, sentinelPointer);
    }

    /// The number of words staged above `upper` by
    /// `consumeSentinelTuplesAboveUpperExternal`, and therefore the exclusive
    /// bound on the `plantWords` it accepts. `plantWords == 0` plants at
    /// `upper` itself, the very first word outside the range, which is the
    /// boundary the range check has to get exactly right.
    uint256 internal constant ABOVE_UPPER_WORDS = 4;

    /// Stages a four word stack at the callee's allocated memory pointer with
    /// TWO sentinels: one at `lower`, in range, which an honest scan finds, and
    /// one `plantWords` words above `upper`, out of range, which only a scan
    /// that walked out of the top of the range can reach. The whole staged
    /// region including the out of range plant is allocated, so reads there are
    /// cheap and the `UnallocatedStack` guard cannot fire on `upper`.
    ///
    /// A cursor stepping UP one word at a time probes `upper` and then each
    /// word above it in turn, so a scan with a stride congruent to `-32` walks
    /// onto the plant wherever it is put. Returns the staged bounds alongside
    /// whatever the scan reported, so the caller can check the answer against
    /// the range without having to predict the callee's free memory pointer.
    function consumeSentinelTuplesAboveUpperExternal(Sentinel sentinel, uint256 n, uint256 plantWords)
        external
        pure
        returns (Pointer lower, Pointer upper, Pointer sentinelPointer)
    {
        require(plantWords < ABOVE_UPPER_WORDS, "plant outside the staged region");
        assembly ("memory-safe") {
            lower := mload(0x40)
            upper := add(lower, 0x80)
            // Allocate the stack AND every word above it that the plant or the
            // upward walk can reach, so `upper` is below the allocated memory
            // pointer and the plant is inside allocated memory.
            let end := add(upper, mul(ABOVE_UPPER_WORDS, 0x20))
            mstore(0x40, end)
            // Zero the whole staged region so the only two words that can
            // match the sentinel are the two planted next.
            for { let cursor := lower } lt(cursor, end) { cursor := add(cursor, 0x20) } { mstore(cursor, 0) }
            mstore(lower, sentinel)
            mstore(add(upper, mul(plantWords, 0x20)), sentinel)
        }
        (sentinelPointer,) = lower.consumeSentinelTuples(upper, sentinel, n);
    }

    /// `type(uint256).max / 0x20` is `2**251 - 1`, the largest `n` that scales
    /// to a byte stride at all, and it does NOT overflow: the product is
    /// `2**256 - 32`, which is congruent to `-32`. `sub(cursor, size)` with
    /// that stride steps the cursor UP one word per iteration, so the scan
    /// walks straight out of the top of the range the caller supplied and keeps
    /// reading. This test does not care whether that is caught by a bound on
    /// the stride, by a check on the answer, or by dying on gas — only that the
    /// out of range sentinel is never handed back as this stack's sentinel.
    function testConsumeSentinelTuplesNegativeStrideCannotSucceedSilently(Sentinel sentinel) public {
        // A zero sentinel would also match the zeroed words in range, which
        // would end the scan before it left the range.
        vm.assume(Sentinel.unwrap(sentinel) != 0);

        uint256 n = type(uint256).max / 0x20;
        // The premise of the whole test: this `n` is inside the scalable range,
        // so no overflow check anywhere can be what saves the scan.
        assertEq(n * 0x20, type(uint256).max - 31, "the stride MUST NOT overflow");

        // Control, on the same staged layout: an honest single word stride
        // finds the in range sentinel at `lower` and reports it. Without this a
        // property that only forbids a bad success would be satisfied
        // vacuously by an implementation that never succeeds at all.
        (bool controlSuccess, bytes memory controlData) = address(this).call{gas: SCAN_GAS_CAP}(
            abi.encodeCall(this.consumeSentinelTuplesAboveUpperExternal, (sentinel, 1, 0))
        );
        assertTrue(controlSuccess, "the staged layout MUST be able to succeed");
        (Pointer controlLower, Pointer controlUpper, Pointer controlSentinelPointer) =
            abi.decode(controlData, (Pointer, Pointer, Pointer));
        assertEq(
            Pointer.unwrap(controlSentinelPointer),
            Pointer.unwrap(controlLower),
            "control MUST find the in range sentinel"
        );
        assertScanCannotSucceedSilently(controlSuccess, controlLower, controlUpper, controlSentinelPointer);

        // Sweep the plant from `upper` itself outward, so the word immediately
        // outside the range is covered as well as ones further out.
        for (uint256 plantWords = 0; plantWords < ABOVE_UPPER_WORDS; plantWords++) {
            //slither-disable-next-line calls-loop
            (bool success, bytes memory data) = address(this).call{gas: SCAN_GAS_CAP}(
                abi.encodeCall(this.consumeSentinelTuplesAboveUpperExternal, (sentinel, n, plantWords))
            );

            // The staging is deterministic, so a call that failed staged the
            // same bounds the control reported.
            Pointer lower = controlLower;
            Pointer upper = controlUpper;
            Pointer sentinelPointer;
            if (success) {
                (lower, upper, sentinelPointer) = abi.decode(data, (Pointer, Pointer, Pointer));
            }
            assertScanCannotSucceedSilently(success, lower, upper, sentinelPointer);
        }
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
        this.consumeSentinelTuplesRawExternal(lower, upper, sentinel, n);
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

    /// Stages a four word stack, zeroed, with the sentinel in the word
    /// immediately below `lower`. Four words is a whole number of strides for
    /// every `n` the caller passes, so a cursor that is not stopped at `lower`
    /// steps exactly onto it and probes the word below.
    function consumeSentinelTuplesBelowLowerNotFoundExternal(Sentinel sentinel, uint256 n)
        external
        pure
        returns (Pointer, Pointer)
    {
        Pointer lower;
        assembly ("memory-safe") {
            let base := mload(0x40)
            mstore(0x40, add(base, 0xc0))
            mstore(base, sentinel)
            lower := add(base, 0x20)
            mstore(lower, 0)
            mstore(add(lower, 0x20), 0)
            mstore(add(lower, 0x40), 0)
            mstore(add(lower, 0x60), 0)
        }
        return lower.consumeSentinelTuples(lower.unsafeAddWords(4), sentinel, n);
    }

    /// A sentinel below `lower` is outside the range the caller described and is
    /// not this stack's sentinel. The sentinel is non zero, so the boundary is
    /// pinned without a zero sentinel colliding with zeroed memory.
    function testConsumeSentinelTuplesBelowLowerNotFound(Sentinel sentinel) external {
        vm.assume(Sentinel.unwrap(sentinel) != 0);

        vm.expectRevert(abi.encodeWithSelector(MissingSentinel.selector, sentinel));
        this.consumeSentinelTuplesBelowLowerNotFoundExternal(sentinel, 1);

        vm.expectRevert(abi.encodeWithSelector(MissingSentinel.selector, sentinel));
        this.consumeSentinelTuplesBelowLowerNotFoundExternal(sentinel, 2);
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

    /// Inverted bounds are rejected by the explicit `upper < lower` check ahead
    /// of the scan. The cursor is never decremented and nothing underflows.
    function testConsumeSentinelTuplesInvertedBoundsError(Pointer lower, Pointer upper, Sentinel sentinel) public {
        vm.assume(Pointer.unwrap(upper) < Pointer.unwrap(lower));

        vm.expectRevert(abi.encodeWithSelector(InvalidStackBounds.selector, lower, upper));
        this.consumeSentinelTuplesRawExternal(lower, upper, sentinel, 2);
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
