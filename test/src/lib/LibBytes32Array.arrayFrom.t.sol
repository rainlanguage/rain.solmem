// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibBytes32Array, Pointer} from "src/lib/LibBytes32Array.sol";
import {LibPointer} from "src/lib/LibPointer.sol";

import {LibBytes32ArraySlow} from "test/lib/LibBytes32ArraySlow.sol";

contract LibBytes32ArrayArrayFromTest is Test {
    using LibBytes32Array for bytes32;
    using LibBytes32ArraySlow for bytes32;
    using LibBytes32Array for bytes32[];
    using LibBytes32ArraySlow for bytes32[];

    function testArrayFromA(bytes32 a) public pure {
        bytes32[] memory array = a.arrayFrom();
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow());
    }

    function testArrayFromAGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom();
    }

    function testArrayFromAGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow();
    }

    function testArrayFromAB(bytes32 a, bytes32 b) public pure {
        bytes32[] memory array = a.arrayFrom(b);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b));
    }

    function testArrayFromABGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(bytes32(uint256(2)));
    }

    function testArrayFromABGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow(bytes32(uint256(2)));
    }

    function testArrayFromABC(bytes32 a, bytes32 b, bytes32 c) public pure {
        bytes32[] memory array = a.arrayFrom(b, c);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, c));
    }

    function testArrayFromABCGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(bytes32(uint256(2)), bytes32(uint256(3)));
    }

    function testArrayFromABCGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow(bytes32(uint256(2)), bytes32(uint256(3)));
    }

    function testArrayFromABCD(bytes32 a, bytes32 b, bytes32 c, bytes32 d) public pure {
        bytes32[] memory array = a.arrayFrom(b, c, d);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, c, d));
    }

    function testArrayFromABCDGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(bytes32(uint256(2)), bytes32(uint256(3)), bytes32(uint256(4)));
    }

    function testArrayFromABCDGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow(bytes32(uint256(2)), bytes32(uint256(3)), bytes32(uint256(4)));
    }

    function testArrayFromABCDE(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e) public pure {
        bytes32[] memory array = a.arrayFrom(b, c, d, e);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, c, d, e));
    }

    function testArrayFromABCDEGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(
            bytes32(uint256(2)), bytes32(uint256(3)), bytes32(uint256(4)), bytes32(uint256(5))
        );
    }

    function testArrayFromABCDEGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow(
            bytes32(uint256(2)), bytes32(uint256(3)), bytes32(uint256(4)), bytes32(uint256(5))
        );
    }

    function testArrayFromABCDEF(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e, bytes32 f) public pure {
        bytes32[] memory array = a.arrayFrom(b, c, d, e, f);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, c, d, e, f));
    }

    function testArrayFromABCDEFGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(
            bytes32(uint256(2)), bytes32(uint256(3)), bytes32(uint256(4)), bytes32(uint256(5)), bytes32(uint256(6))
        );
    }

    function testArrayFromABCDEFGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow(
            bytes32(uint256(2)), bytes32(uint256(3)), bytes32(uint256(4)), bytes32(uint256(5)), bytes32(uint256(6))
        );
    }

    function testArrayFromABCDEFG(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e, bytes32 f, bytes32 g)
        public
        pure
    {
        bytes32[] memory array;
        {
            array = a.arrayFrom(b, c, d, e, f, g);
            assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
            assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        }

        bytes32[] memory arraySlow;
        {
            arraySlow = a.arrayFromSlow(b, c, d, e, f, g);
        }
        assertEq(array, arraySlow);
    }

    function testArrayFromABCDEFGGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(
            bytes32(uint256(2)),
            bytes32(uint256(3)),
            bytes32(uint256(4)),
            bytes32(uint256(5)),
            bytes32(uint256(6)),
            bytes32(uint256(7))
        );
    }

    function testArrayFromABCDEFGGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow(
            bytes32(uint256(2)),
            bytes32(uint256(3)),
            bytes32(uint256(4)),
            bytes32(uint256(5)),
            bytes32(uint256(6)),
            bytes32(uint256(7))
        );
    }

    struct Vals {
        bytes32 a;
        bytes32 b;
        bytes32 c;
        bytes32 d;
        bytes32 e;
        bytes32 f;
        bytes32 g;
        bytes32 h;
    }

    /// Test A through H.
    function testArrayFromABCDEFGH(Vals memory vals) public pure {
        bytes32[] memory array;
        {
            array = vals.a.arrayFrom(vals.b, vals.c, vals.d, vals.e, vals.f, vals.g, vals.h);
            assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
            assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        }

        bytes32[] memory arraySlow;
        {
            arraySlow = vals.a.arrayFromSlow(vals.b, vals.c, vals.d, vals.e, vals.f, vals.g, vals.h);
        }
        assertEq(array, arraySlow);
    }

    function testArrayFromABCDEFGHGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(
            bytes32(uint256(2)),
            bytes32(uint256(3)),
            bytes32(uint256(4)),
            bytes32(uint256(5)),
            bytes32(uint256(6)),
            bytes32(uint256(7)),
            bytes32(uint256(8))
        );
    }

    function testArrayFromABCDEFGHGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow(
            bytes32(uint256(2)),
            bytes32(uint256(3)),
            bytes32(uint256(4)),
            bytes32(uint256(5)),
            bytes32(uint256(6)),
            bytes32(uint256(7)),
            bytes32(uint256(8))
        );
    }

    function testArrayFromATail(bytes32 a, bytes32[] memory tail) public pure {
        bytes32 afterAllocated;
        assembly ("memory-safe") {
            afterAllocated := mload(mload(0x40))
        }
        assertEq(bytes32(0), afterAllocated);

        bytes32[] memory array = a.arrayFrom(tail);
        assembly ("memory-safe") {
            afterAllocated := mload(mload(0x40))
        }
        assertEq(bytes32(0), afterAllocated);

        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(tail));
    }

    function testArrayFromATailGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(bytes32(uint256(2)).arrayFrom(bytes32(uint256(3)), bytes32(uint256(4))));
    }

    function testArrayFromATailGasSlow0() public pure returns (bytes32[] memory) {
        return
            bytes32(uint256(1)).arrayFromSlow(bytes32(uint256(2)).arrayFrom(bytes32(uint256(3)), bytes32(uint256(4))));
    }

    function testArrayFromABTail(bytes32 a, bytes32 b, bytes32[] memory tail) public pure {
        bytes32[] memory array = a.arrayFrom(b, tail);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, tail));
    }

    function testArrayFromABTailGas0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFrom(
            bytes32(uint256(2)), bytes32(uint256(3)).arrayFrom(bytes32(uint256(4)), bytes32(uint256(5)))
        );
    }

    function testArrayFromABTailGasSlow0() public pure returns (bytes32[] memory) {
        return bytes32(uint256(1)).arrayFromSlow(
            bytes32(uint256(2)), bytes32(uint256(3)).arrayFrom(bytes32(uint256(4)), bytes32(uint256(5)))
        );
    }
}
