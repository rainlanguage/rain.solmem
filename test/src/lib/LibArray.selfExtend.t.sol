// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";

/// Extending an array by itself. Base and extend are then ONE array, so the in
/// place path would rewrite the length word both of them read through, mutating
/// the extend array that the NatSpec promises is only ever copied from. Self
/// extension therefore allocates: the input array is left exactly as it was and
/// the doubled result is a new region.
contract LibArraySelfExtendTest is Test {
    using LibUint256Array for uint256[];
    using LibBytes32Array for bytes32[];

    /// Words of free memory poisoned above the free memory pointer.
    uint256 internal constant POISON_WORDS = 12;

    /// Every poisoned word that lies at or above the FINAL free memory pointer
    /// is still free memory and must therefore be untouched. Words below it
    /// were allocated by the call and hold the extended array.
    function _assertNothingWrittenPastFmp(uint256[POISON_WORDS] memory captured, uint256 fmpBefore, uint256 fmpAfter)
        internal
        pure
    {
        for (uint256 i = 0; i < POISON_WORDS; i++) {
            if (fmpBefore + i * 0x20 < fmpAfter) {
                continue;
            }
            assertEq(captured[i], 0xF00D0000 + i, "wrote past the free memory pointer");
        }
    }

    /// The extend array is never mutated, and when base IS extend that is the
    /// input array in its entirety: length word and every data word.
    function testSelfExtendUint256LeavesTheArrayUnmutated() external pure {
        uint256[] memory a = new uint256[](3);
        a[0] = 0x11;
        a[1] = 0x22;
        a[2] = 0x33;

        a.unsafeExtend(a);

        // Deliberately NOT ("memory-safe"): the array is read back out of raw
        // memory so the optimizer answers from memory as it stands after the
        // call rather than from the values written above.
        uint256 lengthAfter;
        uint256 word0;
        uint256 word1;
        uint256 word2;
        assembly {
            lengthAfter := mload(a)
            word0 := mload(add(a, 0x20))
            word1 := mload(add(a, 0x40))
            word2 := mload(add(a, 0x60))
        }

        assertEq(lengthAfter, 3, "length word mutated");
        assertEq(word0, 0x11, "0");
        assertEq(word1, 0x22, "1");
        assertEq(word2, 0x33, "2");
    }

    /// Leaving the array unmutated is only possible by returning a different
    /// region, so the returned pointer must differ from the one passed in even
    /// though the base array is the most recent allocation.
    function testSelfExtendUint256AllocatesRatherThanExtendingInPlace() external pure {
        uint256[] memory a = new uint256[](3);
        a[0] = 0x11;
        a[1] = 0x22;
        a[2] = 0x33;

        uint256[] memory extended = a.unsafeExtend(a);

        // Deliberately NOT ("memory-safe") — see above.
        uint256 aPointer;
        uint256 extendedPointer;
        assembly {
            aPointer := a
            extendedPointer := extended
        }

        assertTrue(extendedPointer != aPointer, "extended in place");
    }

    /// Self-extension copies the original elements once, so the result is the
    /// array doubled rather than a longer run of whatever the copy overran.
    function testSelfExtendUint256DoublesTheContents() external pure {
        uint256[] memory a = new uint256[](3);
        a[0] = 0x11;
        a[1] = 0x22;
        a[2] = 0x33;

        uint256[] memory extended = a.unsafeExtend(a);

        assertEq(extended.length, 6);
        assertEq(extended[0], 0x11);
        assertEq(extended[1], 0x22);
        assertEq(extended[2], 0x33);
        assertEq(extended[3], 0x11);
        assertEq(extended[4], 0x22);
        assertEq(extended[5], 0x33);
    }

    /// The free memory pointer must end up EXACTLY at the end of the extended
    /// array. The allocating path allocates twice, once for the copy of base
    /// and once for the extension on top of it, and the second allocation must
    /// subsume the first rather than sit on top of it.
    function testSelfExtendUint256AllocatesExactly() external pure {
        uint256[] memory a = new uint256[](3);
        a[0] = 0x11;
        a[1] = 0x22;
        a[2] = 0x33;

        uint256[] memory extended = a.unsafeExtend(a);
        // Read the free memory pointer IMMEDIATELY after the call under test.
        // Assertions allocate, so any assertion made first moves the pointer
        // and destroys the measurement.
        uint256 fmpAfter;
        uint256 endOfExtended;
        assembly {
            fmpAfter := mload(0x40)
            endOfExtended := add(extended, add(0x20, mul(mload(extended), 0x20)))
        }

        assertEq(extended.length, 6, "length");
        assertEq(fmpAfter, endOfExtended, "fmp must sit exactly at the end of the extended array");
    }

    /// The assembly is annotated ("memory-safe"), which promises the compiler
    /// nothing is written at or above the free memory pointer the block leaves.
    /// Self extension allocates, so the words it writes are below that pointer;
    /// poison at or above it must survive.
    function testSelfExtendUint256WritesNothingAboveFreeMemoryPointer() external pure {
        uint256[POISON_WORDS] memory captured;

        uint256[] memory a = new uint256[](3);
        a[0] = 0x11;
        a[1] = 0x22;
        a[2] = 0x33;

        // Poison, then the call under test, then snapshot and capture. The two
        // assembly blocks sit flush against the call so the only boundary the
        // poison crosses is the call being measured. Deliberately NOT
        // ("memory-safe"): this writes above the free memory pointer on
        // purpose, and claiming memory safety here would let the optimizer
        // assume the region is untouched and fold the reads below into
        // constants, so the test could pass even after a regression.
        uint256 fmpBefore;
        assembly {
            fmpBefore := mload(0x40)
            for { let i := 0 } lt(i, POISON_WORDS) { i := add(i, 1) } {
                mstore(add(fmpBefore, mul(i, 0x20)), add(0xF00D0000, i))
            }
        }
        uint256[] memory extended = a.unsafeExtend(a);
        uint256 fmpAfter;
        assembly {
            fmpAfter := mload(0x40)
            for { let i := 0 } lt(i, POISON_WORDS) { i := add(i, 1) } {
                mstore(add(captured, mul(i, 0x20)), mload(add(fmpBefore, mul(i, 0x20))))
            }
        }

        assertEq(extended.length, 6, "length");
        _assertNothingWrittenPastFmp(captured, fmpBefore, fmpAfter);
    }

    function testSelfExtendBytes32LeavesTheArrayUnmutated() external pure {
        bytes32[] memory a = new bytes32[](3);
        a[0] = bytes32(uint256(0x11));
        a[1] = bytes32(uint256(0x22));
        a[2] = bytes32(uint256(0x33));

        a.unsafeExtend(a);

        // Deliberately NOT ("memory-safe") — see above.
        uint256 lengthAfter;
        uint256 word0;
        uint256 word1;
        uint256 word2;
        assembly {
            lengthAfter := mload(a)
            word0 := mload(add(a, 0x20))
            word1 := mload(add(a, 0x40))
            word2 := mload(add(a, 0x60))
        }

        assertEq(lengthAfter, 3, "length word mutated");
        assertEq(word0, 0x11, "0");
        assertEq(word1, 0x22, "1");
        assertEq(word2, 0x33, "2");
    }

    function testSelfExtendBytes32AllocatesRatherThanExtendingInPlace() external pure {
        bytes32[] memory a = new bytes32[](3);
        a[0] = bytes32(uint256(0x11));
        a[1] = bytes32(uint256(0x22));
        a[2] = bytes32(uint256(0x33));

        bytes32[] memory extended = a.unsafeExtend(a);

        // Deliberately NOT ("memory-safe") — see above.
        uint256 aPointer;
        uint256 extendedPointer;
        assembly {
            aPointer := a
            extendedPointer := extended
        }

        assertTrue(extendedPointer != aPointer, "extended in place");
    }

    function testSelfExtendBytes32DoublesTheContents() external pure {
        bytes32[] memory a = new bytes32[](2);
        a[0] = bytes32(uint256(0xAA));
        a[1] = bytes32(uint256(0xBB));

        bytes32[] memory extended = a.unsafeExtend(a);

        assertEq(extended.length, 4);
        assertEq(extended[0], bytes32(uint256(0xAA)));
        assertEq(extended[1], bytes32(uint256(0xBB)));
        assertEq(extended[2], bytes32(uint256(0xAA)));
        assertEq(extended[3], bytes32(uint256(0xBB)));
    }

    function testSelfExtendBytes32AllocatesExactly() external pure {
        bytes32[] memory a = new bytes32[](3);
        a[0] = bytes32(uint256(0x11));
        a[1] = bytes32(uint256(0x22));
        a[2] = bytes32(uint256(0x33));

        bytes32[] memory extended = a.unsafeExtend(a);
        // Read the free memory pointer IMMEDIATELY after the call under test.
        uint256 fmpAfter;
        uint256 endOfExtended;
        assembly {
            fmpAfter := mload(0x40)
            endOfExtended := add(extended, add(0x20, mul(mload(extended), 0x20)))
        }

        assertEq(extended.length, 6, "length");
        assertEq(fmpAfter, endOfExtended, "fmp must sit exactly at the end of the extended array");
    }

    function testSelfExtendBytes32WritesNothingAboveFreeMemoryPointer() external pure {
        uint256[POISON_WORDS] memory captured;

        bytes32[] memory a = new bytes32[](3);
        a[0] = bytes32(uint256(0x11));
        a[1] = bytes32(uint256(0x22));
        a[2] = bytes32(uint256(0x33));

        // Poison, call, snapshot and capture — see above.
        uint256 fmpBefore;
        assembly {
            fmpBefore := mload(0x40)
            for { let i := 0 } lt(i, POISON_WORDS) { i := add(i, 1) } {
                mstore(add(fmpBefore, mul(i, 0x20)), add(0xF00D0000, i))
            }
        }
        bytes32[] memory extended = a.unsafeExtend(a);
        uint256 fmpAfter;
        assembly {
            fmpAfter := mload(0x40)
            for { let i := 0 } lt(i, POISON_WORDS) { i := add(i, 1) } {
                mstore(add(captured, mul(i, 0x20)), mload(add(fmpBefore, mul(i, 0x20))))
            }
        }

        assertEq(extended.length, 6, "length");
        _assertNothingWrittenPastFmp(captured, fmpBefore, fmpAfter);
    }
}
