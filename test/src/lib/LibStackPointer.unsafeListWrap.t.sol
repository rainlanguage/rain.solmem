// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibStackPointerWrapHarness} from "test/src/lib/LibStackPointerWrapHarness.sol";

/// Reproduces the `unsafeList` half of issue #54.
///
/// `unsafeList` positions the array header with `sub(pointer, add(0x20,
/// mul(length, 0x20)))` and then stamps the length word with `mstore(tail,
/// length)`. The multiply is Yul, so it is mod `2**256`, but the `mstore` is
/// not scaled at all. The two halves of the same expression therefore disagree
/// for any `length >= 2**251`: the header is placed as if `length mod 2**251`
/// items were requested, while the length word says `length`.
///
/// The result is that `unsafeList` MINTS a `bytes32[]` whose declared length is
/// astronomically larger than the memory behind it, and hands it back to
/// ordinary Solidity. Solidity's own bounds check then consults that forged
/// length word and licenses reads and writes across the whole heap. The
/// corruption escapes the `unsafe` boundary into code containing no assembly.
///
/// The invariant asserted here is: `unsafeList` either fails loudly, or does
/// not hand back an array that can write outside the stack it was given.
///
/// Every assertion lives in the success branch of a `try`, so the tests are
/// agnostic to the shape of a fix: a checked multiply, an explicit bound with a
/// custom error, or anything else that reverts all take the empty `catch`
/// branch and pass. They fail only when the call returns successfully having
/// minted a forged length word.
contract LibStackPointerUnsafeListWrapTest is Test {
    /// `2**251` is the exact point at which `length * 0x20` wraps: `(2**251 -
    /// 1) * 0x20 == 2**256 - 0x20` still fits, `2**251 * 0x20` is `2**256`,
    /// which is `0`.
    uint256 internal constant WRAP_PERIOD = 1 << 251;

    /// The stack handed to `unsafeList` in every scenario holds this many
    /// items, so no honest `length` can exceed it.
    uint256 internal constant STACK_LENGTH = 4;

    LibStackPointerWrapHarness internal harness;

    function setUp() external {
        harness = new LibStackPointerWrapHarness();
    }

    /// At `length == 2**251` the scaled offset wraps to zero, so the header
    /// lands one word below the stack top, entirely inside live memory, and the
    /// unwrapped `2**251` is stamped there as the length word. The returned
    /// array claims `2**251` items over four words of stack, and writing
    /// through index zero lands on the next allocation's own length word.
    function testUnsafeListWrappedLengthMintsForgedArrayOverLiveMemory() external view {
        try harness.listThenWriteThroughResult(WRAP_PERIOD, 0) returns (
            LibStackPointerWrapHarness.Observation memory observation
        ) {
            assertEq(
                observation.neighbourLength,
                STACK_LENGTH,
                "writing through unsafeList's result destroyed a neighbouring array's length word"
            );
            assertEq(
                observation.neighbourFirst,
                harness.CANARY(),
                "writing through unsafeList's result destroyed a neighbouring array's contents"
            );
            assertLe(
                observation.claimedLength,
                STACK_LENGTH,
                "unsafeList minted a length word larger than the stack it was given"
            );
        } catch {
            // A loud failure is the documented and acceptable outcome for an
            // out of range length. Only a silent success is a defect.
        }
    }

    /// The same defect reached by an ordinary consumer bug rather than a hand
    /// authored constant. `unchecked { 2 - 3 }` is `type(uint256).max`, whose
    /// residue mod `2**251` is `2**251 - 1`, so the scaled offset wraps to zero
    /// minus a word and the header lands ABOVE the stack top, directly on the
    /// neighbouring array's length word. `unsafeList` overwrites it with
    /// `type(uint256).max` before the caller does anything at all.
    function testUnsafeListUncheckedUnderflowMintsForgedArrayOverNeighbour() external view {
        try harness.listUncheckedDifference(2, 3, 0) returns (
            LibStackPointerWrapHarness.Observation memory observation
        ) {
            assertEq(
                observation.neighbourLength,
                STACK_LENGTH,
                "unsafeList placed its header on a neighbouring array's length word"
            );
            assertEq(
                observation.neighbourFirst,
                harness.CANARY(),
                "writing through unsafeList's result destroyed a neighbouring array's contents"
            );
            assertLe(
                observation.claimedLength,
                STACK_LENGTH,
                "unsafeList minted a length word larger than the stack it was given"
            );
        } catch {
            // A loud failure is the documented and acceptable outcome.
        }
    }

    /// The wrap is periodic rather than a tail, so it is not confined to one
    /// pathological constant. `2**251 + k` places the header `k + 1` words
    /// below the stack top for every small `k`, each time minting the full
    /// unwrapped `2**251 + k` as the length word.
    function testUnsafeListWrappedLengthMintsForgedArrayAcrossTheResidueWindow() external view {
        for (uint256 residue = 0; residue < STACK_LENGTH; residue++) {
            try harness.listClaimedLength(WRAP_PERIOD + residue) returns (uint256 claimedLength) {
                assertLe(
                    claimedLength, STACK_LENGTH, "unsafeList minted a length word larger than the stack it was given"
                );
            } catch {
                // A loud failure is the documented and acceptable outcome.
            }
        }
    }

    /// Premise control, and the reason this is a bug rather than a caller
    /// error.
    ///
    /// An out of range `length` that does NOT wrap behaves exactly as
    /// `LibStackPointer` documents: the subtraction underflows to an
    /// unaddressable pointer and the `mload` exhausts gas. `2**100 * 0x20` is
    /// `2**105`, which fits in a `uint256`, so nothing wraps and the failure
    /// stays loud.
    ///
    /// This test passes on `main` and is expected to keep passing under any
    /// fix. It pins the behaviour the tests above are contrasted against: the
    /// wrap is precisely what converts this loud failure into a silent success,
    /// and relocates the damage from unaddressable space back into live memory.
    function testUnsafeListNonWrappingOutOfRangeLengthFailsLoudly() external view {
        bool returnedSuccessfully;
        try harness.listClaimedLength{gas: 10_000_000}(1 << 100) returns (uint256) {
            returnedSuccessfully = true;
        } catch {}
        assertFalse(
            returnedSuccessfully, "premise: a non wrapping out of range length is documented to fail loudly on gas"
        );
    }
}
