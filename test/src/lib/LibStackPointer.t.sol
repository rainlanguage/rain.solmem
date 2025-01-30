// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibPointer} from "src/lib/LibPointer.sol";
import {LibStackPointer} from "src/lib/LibStackPointer.sol";
import {LibUint256Array, Pointer} from "src/lib/LibUint256Array.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";

contract LibStackPointerTest is Test {
    using LibPointer for Pointer;
    using LibStackPointer for Pointer;
    using LibUint256Array for uint256[];
    using LibBytes32Array for bytes32[];

    function testUnsafePeek(bytes32 a, bytes32 b) public pure {
        bytes32[] memory array = new bytes32[](1);
        Pointer pointer = array.dataPointer();
        Pointer peekable = pointer.unsafeAddWord();

        pointer.unsafeWriteWord(a);
        assertEq(a, peekable.unsafePeek());

        // Check that peek is non destructive.
        assertEq(a, peekable.unsafePeek());

        pointer.unsafeWriteWord(b);

        assertEq(b, peekable.unsafePeek());
    }

    function testUnsafePeek2(bytes32 a, bytes32 b, bytes32 c, bytes32 d) public pure {
        bytes32[] memory array = new bytes32[](2);
        Pointer pointer = array.dataPointer();
        Pointer peekable = pointer.unsafeAddWords(2);

        pointer.unsafeWriteWord(a);
        pointer.unsafeAddWord().unsafeWriteWord(b);

        (bytes32 peek0, bytes32 peek1) = peekable.unsafePeek2();
        assertEq(peek0, a);
        assertEq(peek1, b);

        // Check that peek2 is non destructive.
        (bytes32 peek2, bytes32 peek3) = peekable.unsafePeek2();
        assertEq(peek2, a);
        assertEq(peek3, b);

        pointer.unsafeWriteWord(c);
        pointer.unsafeAddWord().unsafeWriteWord(d);
        (bytes32 peek4, bytes32 peek5) = peekable.unsafePeek2();
        assertEq(peek4, c);
        assertEq(peek5, d);
    }

    function testUnsafePop(bytes32 a, bytes32 b) public pure {
        bytes32[] memory array = new bytes32[](2);
        Pointer pointer = array.dataPointer();
        Pointer poppable = pointer.unsafeAddWord();

        pointer.unsafeWriteWord(a);
        //slither-disable-next-line similar-names
        (Pointer poppedPointer0, bytes32 pop0) = poppable.unsafePop();

        // Pop is "destructive" in that it returns a new pointer below what it
        // reads. But isn't really destroying anything.
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(poppedPointer0));
        assertEq(a, pop0);

        //slither-disable-next-line similar-names
        (Pointer poppedPointer1, bytes32 pop1) = poppable.unsafePop();
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(poppedPointer1));
        assertEq(a, pop1);

        pointer.unsafeWriteWord(b);

        //slither-disable-next-line similar-names
        (Pointer poppedPointer2, bytes32 pop2) = poppable.unsafePop();
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(poppedPointer2));
        assertEq(b, pop2);
    }

    function testUnsafePush(bytes32 a, bytes32 b) public pure {
        bytes32[] memory array = new bytes32[](1);
        Pointer pointer = array.dataPointer();

        Pointer push0 = pointer.unsafePush(a);
        assertEq(Pointer.unwrap(push0), Pointer.unwrap(pointer.unsafeAddWord()));
        assertEq(pointer.unsafeReadWord(), a);

        Pointer push1 = pointer.unsafePush(b);
        assertEq(Pointer.unwrap(push1), Pointer.unwrap(pointer.unsafeAddWord()));
        assertEq(pointer.unsafeReadWord(), b);
    }

    function testUnsafeList(bytes32[] memory array, uint8 length) public pure {
        vm.assume(length < array.length);
        Pointer pointer = array.endPointer();

        bytes32 expectedHead = array[array.length - length - 1];
        bytes32[] memory expectedTail = new bytes32[](length);
        uint256 j = 0;
        for (uint256 i = array.length - length; i < array.length; i++) {
            expectedTail[j] = array[i];
            j++;
        }

        (bytes32 head, bytes32[] memory tail) = pointer.unsafeList(length);
        assertEq(expectedHead, head);
        assertEq(expectedTail, tail);

        // array will be mutated due to the unsafety of the list.
        assertEq(uint256(array[array.length - length - 1]), length);
    }
}
