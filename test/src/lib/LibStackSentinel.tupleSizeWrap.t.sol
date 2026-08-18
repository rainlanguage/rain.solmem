// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";
import {LibStackSentinelWrapHarness} from "./LibStackSentinelWrapHarness.sol";

/// Reproduces the `consumeSentinelTuples` half of issue #54.
///
/// `consumeSentinelTuples` scales the tuple size with `size := mul(n, 0x20)`
/// inside Yul, so the byte stride is `32 * (n mod 2**251)` rather than `32 * n`.
/// For `n = 2**251 + k` the function therefore behaves exactly as if `n = k` had
/// been requested, and returns successfully.
///
/// This function is not prefixed `unsafe`, and it does not document a single
/// precondition on `n`. The only constraint it
/// states is `n != 0`, and that one IS enforced with `ZeroSentinelTupleSize`.
/// What it does state, twice, is that a bad `n` fails LOUDLY: the NatSpec says
/// an underflow "will result in the evm immediately running out of gas", and
/// the inline comment beside the loop says "An underflow here always results in
/// a revert due to gas". These tests falsify that claim.
///
/// Assertions live in the success branch of a `try`, so any fix that rejects an
/// `n` it cannot scale to bytes takes the empty `catch` branch and passes,
/// whether that is a checked multiply or an explicit bound with a custom error.
contract LibStackSentinelTupleSizeWrapTest is Test {
    /// `2**251` is the exact point at which `n * 0x20` wraps.
    uint256 internal constant WRAP_PERIOD = 1 << 251;

    LibStackSentinelWrapHarness internal harness;

    function setUp() external {
        harness = new LibStackSentinelWrapHarness();
    }

    /// The probe's region is four words, one of which is the sentinel, so at
    /// most `3 / n` tuples of `n` items each can exist in it. At `n = 2**251 +
    /// 1` that bound is zero, and the library reports three.
    function testConsumeSentinelTuplesWrappedSizeReturnsMoreTuplesThanTheStackHolds() external view {
        uint256 n = WRAP_PERIOD + 1;
        uint256 itemsAboveSentinel = harness.STACK_WORDS() - 1;
        uint256 maxTuples = itemsAboveSentinel / n;

        try harness.consume(n) returns (uint256, uint256 tuplesLength, uint256) {
            assertLe(
                tuplesLength, maxTuples, "consumeSentinelTuples built more tuples than the stack it was given can hold"
            );
        } catch {
            // Rejecting an `n` that cannot be scaled to a byte stride is the
            // acceptable outcome. Only a silent success is a defect.
        }
    }

    /// The stride collapse is total, not approximate: `n = 2**251 + 1` produces
    /// byte for byte the same result as `n = 1`. A caller asking for tuples of
    /// `2**251 + 1` items is silently served tuples of one item.
    function testConsumeSentinelTuplesWrappedSizeAliasesTheSmallResidue() external view {
        (uint256 sentinelOne, uint256 lengthOne, uint256 firstOne) = harness.consume(1);

        try harness.consume(WRAP_PERIOD + 1) returns (
            uint256 sentinelWrapped, uint256 lengthWrapped, uint256 firstWrapped
        ) {
            assertFalse(
                sentinelWrapped == sentinelOne && lengthWrapped == lengthOne && firstWrapped == firstOne,
                "consumeSentinelTuples silently served n = 2**251 + 1 as n = 1"
            );
        } catch {
            // Rejecting the unscalable `n` is the acceptable outcome.
        }
    }

    /// The collapse is periodic, not a one off at a single pathological
    /// constant: `n = m * 2**251 + 1` is served as `n = 1` for every `m`.
    function testConsumeSentinelTuplesWrappedSizeCollapsesAtEveryMultiple() external view {
        uint256 itemsAboveSentinel = harness.STACK_WORDS() - 1;

        for (uint256 multiple = 1; multiple < 4; multiple++) {
            uint256 n = WRAP_PERIOD * multiple + 1;
            try harness.consume(n) returns (uint256, uint256 tuplesLength, uint256) {
                assertLe(
                    tuplesLength,
                    itemsAboveSentinel / n,
                    "consumeSentinelTuples built more tuples than the stack it was given can hold"
                );
            } catch {
                // Rejecting the unscalable `n` is the acceptable outcome.
            }
        }
    }

    /// Premise control, and the reason this is a bug rather than a caller
    /// error.
    ///
    /// An out of range `n` that does NOT wrap behaves exactly as the NatSpec
    /// and the inline comment promise: `sub(cursor, size)` underflows, the loop
    /// runs from near `2**256` and the call dies on gas. `1000 * 0x20` is
    /// `32000`, well clear of the wrap, so the failure stays loud.
    ///
    /// This test passes on `main` and is expected to keep passing under any
    /// fix. It pins the documented behaviour that the tests above show is false
    /// near `2**251`.
    function testConsumeSentinelTuplesNonWrappingOversizedTupleFailsLoudly() external view {
        bool returnedSuccessfully;
        try harness.consume{gas: 10_000_000}(1000) returns (uint256, uint256, uint256) {
            returnedSuccessfully = true;
        } catch {}
        assertFalse(
            returnedSuccessfully,
            "premise: a non wrapping oversized tuple size is documented to always revert due to gas"
        );
    }
}
