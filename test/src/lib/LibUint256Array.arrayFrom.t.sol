// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibUint256Array, Pointer} from "src/lib/LibUint256Array.sol";
import {LibPointer} from "src/lib/LibPointer.sol";

import {LibUint256ArraySlow} from "test/lib/LibUint256ArraySlow.sol";

contract LibUint256ArrayArrayFromTest is Test {
    using LibUint256Array for uint256;
    using LibUint256ArraySlow for uint256;
    using LibUint256Array for uint256[];
    using LibUint256ArraySlow for uint256[];

    function testArrayFromA(uint256 a) public pure {
        uint256[] memory array = a.arrayFrom();
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow());
    }

    function testArrayFromAGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom();
    }

    function testArrayFromAGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow();
    }

    function testArrayFromAB(uint256 a, uint256 b) public pure {
        uint256[] memory array = a.arrayFrom(b);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b));
    }

    function testArrayFromABGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(2);
    }

    function testArrayFromABGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(2);
    }

    function testArrayFromABC(uint256 a, uint256 b, uint256 c) public pure {
        uint256[] memory array = a.arrayFrom(b, c);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, c));
    }

    function testArrayFromABCGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(2, 3);
    }

    function testArrayFromABCGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(2, 3);
    }

    function testArrayFromABCD(uint256 a, uint256 b, uint256 c, uint256 d) public pure {
        uint256[] memory array = a.arrayFrom(b, c, d);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, c, d));
    }

    function testArrayFromABCDGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(2, 3, 4);
    }

    function testArrayFromABCDGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(2, 3, 4);
    }

    function testArrayFromABCDE(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) public pure {
        uint256[] memory array = a.arrayFrom(b, c, d, e);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, c, d, e));
    }

    function testArrayFromABCDEGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(2, 3, 4, 5);
    }

    function testArrayFromABCDEGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(2, 3, 4, 5);
    }

    function testArrayFromABCDEF(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f) public pure {
        uint256[] memory array = a.arrayFrom(b, c, d, e, f);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, c, d, e, f));
    }

    function testArrayFromABCDEFGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(2, 3, 4, 5, 6);
    }

    function testArrayFromABCDEFGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(2, 3, 4, 5, 6);
    }

    function testArrayFromABCDEFG(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f, uint256 g)
        public
        pure
    {
        uint256[] memory array;
        {
            array = a.arrayFrom(b, c, d, e, f, g);
            assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
            assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        }

        uint256[] memory arraySlow;
        {
            arraySlow = a.arrayFromSlow(b, c, d, e, f, g);
        }
        assertEq(array, arraySlow);
    }

    function testArrayFromABCDEFGGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(2, 3, 4, 5, 6, 7);
    }

    function testArrayFromABCDEFGGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(2, 3, 4, 5, 6, 7);
    }

    struct Vals {
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
        uint256 e;
        uint256 f;
        uint256 g;
        uint256 h;
    }

    /// Test A through H.
    function testArrayFromABCDEFGH(Vals memory vals) public pure {
        uint256[] memory array;
        {
            array = vals.a.arrayFrom(vals.b, vals.c, vals.d, vals.e, vals.f, vals.g, vals.h);
            assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
            assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        }

        uint256[] memory arraySlow;
        {
            arraySlow = vals.a.arrayFromSlow(vals.b, vals.c, vals.d, vals.e, vals.f, vals.g, vals.h);
        }
        assertEq(array, arraySlow);
    }

    function testArrayFromABCDEFGHGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(2, 3, 4, 5, 6, 7, 8);
    }

    function testArrayFromABCDEFGHGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(2, 3, 4, 5, 6, 7, 8);
    }

    function testArrayFromATail(uint256 a, uint256[] memory tail) public pure {
        uint256[] memory array = a.arrayFrom(tail);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(tail));
    }

    function testArrayFromATailGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(uint256(2).arrayFrom(3, 4));
    }

    function testArrayFromATailGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(uint256(2).arrayFrom(3, 4));
    }

    function testArrayFromABTail(uint256 a, uint256 b, uint256[] memory tail) public pure {
        uint256[] memory array = a.arrayFrom(b, tail);
        assertEq(Pointer.unwrap(LibPointer.allocatedMemoryPointer()), Pointer.unwrap(array.endPointer()));
        assertEq(Pointer.unwrap(array.endPointer()) - Pointer.unwrap(array.dataPointer()), array.length * 0x20);
        assertEq(array, a.arrayFromSlow(b, tail));
    }

    function testArrayFromABTailGas0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFrom(2, uint256(3).arrayFrom(4, 5));
    }

    function testArrayFromABTailGasSlow0() public pure returns (uint256[] memory) {
        return uint256(1).arrayFromSlow(2, uint256(3).arrayFrom(4, 5));
    }
}
