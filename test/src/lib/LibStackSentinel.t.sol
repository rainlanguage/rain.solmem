// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibPointer, Pointer} from "src/lib/LibPointer.sol";
import {LibUint256Array} from "src/lib/LibStackPointer.sol";
import {LibStackSentinel, Sentinel, MissingSentinel} from "src/lib/LibStackSentinel.sol";

contract LibStackSentinelTest is Test {
    using LibUint256Array for uint256[];
    using LibPointer for Pointer;
    using LibStackSentinel for Pointer;

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

        (Pointer sentinelPointer, Pointer tuplesPointer) =
            stack.dataPointer().consumeSentinelTuples(stack.endPointer(), sentinel, 2);
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

        (Pointer sentinelPointer, Pointer tuplesPointer) =
            stack.dataPointer().consumeSentinelTuples(stack.endPointer(), sentinel, 3);
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

    function testConsumeSentinelTuplesUnderflowError(Pointer lower, Pointer upper, Sentinel sentinel, uint256 n)
        public
    {
        // If the sentinel is easy to collide with then it might just match and
        // not underflow, which defeats the purpose of the test.
        vm.assume(Sentinel.unwrap(sentinel) > type(uint128).max);
        vm.assume(Pointer.unwrap(lower) < n);
        vm.assume(Pointer.unwrap(upper) > Pointer.unwrap(lower));

        // Underflow will revert because it will run out of gas attempting to
        // loop over infinity.
        vm.expectRevert();
        this.consumeSentinelTuplesExternal(lower, upper, sentinel, n);
    }

    function testConsumeSentinelTuplesInitialStateUnderflowError(Pointer lower, Pointer upper, Sentinel sentinel)
        public
    {
        vm.assume(Pointer.unwrap(upper) < Pointer.unwrap(lower));

        vm.expectRevert(abi.encodeWithSelector(MissingSentinel.selector, sentinel));
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
            mstore(lower, sentinel)
        }

        (Pointer sentinelPointer, Pointer tuplesPointer) =
            lower.consumeSentinelTuples(lower.unsafeAddWord(), sentinel, 2);
        assertEq(Pointer.unwrap(sentinelPointer), Pointer.unwrap(lower));
        assertEq(tuplesPointer.unsafeReadWord(), 0);
    }

    function testConsumeSentinelTuplesGas0() external pure {
        Pointer lower;
        Pointer upper;
        Sentinel sentinel = Sentinel.wrap(50);
        assembly ("memory-safe") {
            lower := mload(0x40)
            upper := add(lower, 0x20)
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
            mstore(lower, sentinel)
        }
        (Pointer sentinelPointer, Pointer tuplesPointer) = lower.consumeSentinelTuples(upper, sentinel, 2);
        (sentinelPointer);
        (tuplesPointer);
    }
}
