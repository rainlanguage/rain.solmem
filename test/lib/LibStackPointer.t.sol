// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import "forge-std/Test.sol";

import "src/lib/LibPointer.sol";
import "src/lib/LibStackPointer.sol";
import "src/lib/LibUint256Array.sol";

contract LibStackPointerTest is Test {
    using LibPointer for Pointer;
    using LibStackPointer for Pointer;
    using LibUint256Array for uint256[];

    function testUnsafePeek(uint256 a, uint256 b) public {
        Pointer pointer = LibPointer.allocatedMemoryPointer();
        Pointer peekable = pointer.unsafeAddWord();

        pointer.unsafeWriteWord(a);
        assertEq(a, peekable.unsafePeek());

        // Check that peek is non destructive.
        assertEq(a, peekable.unsafePeek());

        pointer.unsafeWriteWord(b);

        assertEq(b, peekable.unsafePeek());
    }

    function testUnsafePeek2(uint256 a, uint256 b, uint256 c, uint256 d) public {
        Pointer pointer = LibPointer.allocatedMemoryPointer();
        Pointer peekable = pointer.unsafeAddWords(2);

        pointer.unsafeWriteWord(a);
        pointer.unsafeAddWord().unsafeWriteWord(b);

        (uint256 peek0, uint256 peek1) = peekable.unsafePeek2();
        assertEq(peek0, a);
        assertEq(peek1, b);

        // Check that peek2 is non destructive.
        (uint256 peek2, uint256 peek3) = peekable.unsafePeek2();
        assertEq(peek2, a);
        assertEq(peek3, b);

        pointer.unsafeWriteWord(c);
        pointer.unsafeAddWord().unsafeWriteWord(d);
        (uint256 peek4, uint256 peek5) = peekable.unsafePeek2();
        assertEq(peek4, c);
        assertEq(peek5, d);
    }

    function testUnsafePop(uint256 a, uint256 b) public {
        Pointer pointer = LibPointer.allocatedMemoryPointer();
        Pointer poppable = pointer.unsafeAddWord();

        pointer.unsafeWriteWord(a);
        //slither-disable-next-line similar-names
        (Pointer poppedPointer0, uint256 pop0) = poppable.unsafePop();

        // Pop is "destructive" in that it returns a new pointer below what it
        // reads. But isn't really destroying anything.
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(poppedPointer0));
        assertEq(a, pop0);

        //slither-disable-next-line similar-names
        (Pointer poppedPointer1, uint256 pop1) = poppable.unsafePop();
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(poppedPointer1));
        assertEq(a, pop1);

        pointer.unsafeWriteWord(b);

        //slither-disable-next-line similar-names
        (Pointer poppedPointer2, uint256 pop2) = poppable.unsafePop();
        assertEq(Pointer.unwrap(pointer), Pointer.unwrap(poppedPointer2));
        assertEq(b, pop2);
    }

    function testUnsafePush(uint256 a, uint256 b) public {
        Pointer pointer = LibPointer.allocatedMemoryPointer();

        Pointer push0 = pointer.unsafePush(a);
        assertEq(Pointer.unwrap(push0), Pointer.unwrap(pointer.unsafeAddWord()));
        assertEq(pointer.unsafeReadWord(), a);

        Pointer push1 = pointer.unsafePush(b);
        assertEq(Pointer.unwrap(push1), Pointer.unwrap(pointer.unsafeAddWord()));
        assertEq(pointer.unsafeReadWord(), b);
    }

    function testUnsafeList(uint256[] memory array, uint8 length) public {
        vm.assume(length < array.length);
        Pointer pointer = array.endPointer();

        uint256 expectedHead = array[array.length - length - 1];
        uint256[] memory expectedTail = new uint256[](length);
        uint256 j = 0;
        for (uint256 i = array.length - length; i < array.length; i++) {
            expectedTail[j] = array[i];
            j++;
        }

        (uint256 head, uint256[] memory tail) = pointer.unsafeList(length);
        assertEq(expectedHead, head);
        assertEq(expectedTail, tail);

        // array will be mutated due to the unsafety of the list.
        assertEq(array[array.length - length - 1], length);
    }
}
