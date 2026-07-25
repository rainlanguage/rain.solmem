// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibMatrixFlattenWrapHarness} from "test/src/lib/LibMatrixFlattenWrapHarness.sol";

/// Reproduces issue #62 for `LibUint256Matrix` and its byte identical
/// `LibBytes32Matrix` twin.
///
/// Two unchecked operations combine:
///
/// - `itemCount` accumulates the inner length words with `count := add(count,
///   mload(mload(cursor)))` in Yul, so the total wraps mod `2**256`.
/// - `flatten` then sizes its allocation from the WRAPPED product
///   `mul(length, 0x20)` while stamping the UNWRAPPED `length` into the length
///   word with `mstore(array, length)`.
///
/// The two halves of the same expression disagree for any `length >= 2**251`,
/// so `flatten` returns an ordinary `uint256[]` declaring vastly more items
/// than it reserved memory for. Solidity's own bounds check consults that
/// length word, so reads and writes anywhere below the declared length are
/// waved through, and the whole thing sits inside `assembly ("memory-safe")`,
/// which asserts the opposite to the optimiser.
///
/// Neither `itemCount` nor `flatten` carries the `unsafe` prefix, and neither
/// documents any precondition on its input matrix.
///
/// Every assertion lives in the success branch of a `try`, so any fix that
/// rejects a count it cannot scale to bytes takes the empty `catch` branch and
/// passes, whether that is a checked multiply, a checked sum, or an explicit
/// bound with a custom error.
contract LibMatrixFlattenWrapTest is Test {
    /// `2**251` is the exact point at which `count * 0x20` wraps.
    uint256 internal constant WRAP_PERIOD = 1 << 251;

    /// The pair of inner length words from issue #62. They sum to `2**252 + 5`,
    /// whose scaled size wraps to 160 bytes, so `flatten` reserves 192 bytes in
    /// total and declares `2**252 + 5` items over them.
    uint256 internal constant FORGED_LENGTH_0 = WRAP_PERIOD + 2;
    uint256 internal constant FORGED_LENGTH_1 = WRAP_PERIOD + 3;

    LibMatrixFlattenWrapHarness internal harness;

    function setUp() external {
        harness = new LibMatrixFlattenWrapHarness();
    }

    /// A total cannot be smaller than one of the parts it totals. `itemCount`
    /// reports zero for a matrix of two `2**255` item arrays.
    function testUint256ItemCountUncheckedSumUnderreportsTheTotal() external view {
        try harness.uint256ItemCount(1 << 255, 1 << 255) returns (uint256 count) {
            assertGe(count, 1 << 255, "itemCount reported fewer items than a single sub array declares");
        } catch {
            // Rejecting a total it cannot represent is the acceptable outcome.
        }
    }

    /// `testUint256ItemCountUncheckedSumUnderreportsTheTotal` for the `bytes32`
    /// twin, which is byte identical.
    function testBytes32ItemCountUncheckedSumUnderreportsTheTotal() external view {
        try harness.bytes32ItemCount(1 << 255, 1 << 255) returns (uint256 count) {
            assertGe(count, 1 << 255, "itemCount reported fewer items than a single sub array declares");
        } catch {
            // Rejecting a total it cannot represent is the acceptable outcome.
        }
    }

    /// `flatten` must not hand back an array declaring more items than the
    /// memory it reserved can hold. The reserved memory is one length word plus
    /// the data, so the capacity in items is `(allocatedBytes - 0x20) / 0x20`.
    function testUint256FlattenDeclaresMoreItemsThanItAllocated() external view {
        try harness.uint256Flatten(FORGED_LENGTH_0, FORGED_LENGTH_1) returns (
            LibMatrixFlattenWrapHarness.Allocation memory allocation
        ) {
            uint256 capacity = allocation.allocatedBytes < 0x20 ? 0 : (allocation.allocatedBytes - 0x20) / 0x20;
            assertLe(allocation.declaredLength, capacity, "flatten declared more items than it allocated");
        } catch {
            // A loud failure is the acceptable outcome.
        }
    }

    /// `testUint256FlattenDeclaresMoreItemsThanItAllocated` for the `bytes32`
    /// twin, which is byte identical.
    function testBytes32FlattenDeclaresMoreItemsThanItAllocated() external view {
        try harness.bytes32Flatten(FORGED_LENGTH_0, FORGED_LENGTH_1) returns (
            LibMatrixFlattenWrapHarness.Allocation memory allocation
        ) {
            uint256 capacity = allocation.allocatedBytes < 0x20 ? 0 : (allocation.allocatedBytes - 0x20) / 0x20;
            assertLe(allocation.declaredLength, capacity, "flatten declared more items than it allocated");
        } catch {
            // A loud failure is the acceptable outcome.
        }
    }

    /// The forged length word is not merely cosmetic. `flatten` leaves the free
    /// memory pointer just past its undersized allocation, so the next ordinary
    /// Solidity allocation lands inside the region `flatten`'s result claims.
    /// Writing through that result with bounds checked Solidity then overwrites
    /// the neighbour.
    function testUint256FlattenResultWritesOverTheNextAllocation() external view {
        try harness.uint256FlattenThenWriteThroughResult(FORGED_LENGTH_0, FORGED_LENGTH_1) returns (
            uint256 canaryValue
        ) {
            assertEq(canaryValue, harness.CANARY(), "writing through flatten's result overwrote the next allocation");
        } catch {
            // A loud failure is the acceptable outcome.
        }
    }

    /// `testUint256FlattenResultWritesOverTheNextAllocation` for the `bytes32`
    /// twin, which is byte identical.
    function testBytes32FlattenResultWritesOverTheNextAllocation() external view {
        try harness.bytes32FlattenThenWriteThroughResult(FORGED_LENGTH_0, FORGED_LENGTH_1) returns (
            uint256 canaryValue
        ) {
            assertEq(canaryValue, harness.CANARY(), "writing through flatten's result overwrote the next allocation");
        } catch {
            // A loud failure is the acceptable outcome.
        }
    }

    /// The forged length word does not have to come from the test.
    /// `LibStackPointer.unsafeList` mints one from inside this library (issue
    /// #54), and `matrixFrom` then `flatten` launder it, neither of them
    /// prefixed `unsafe` and neither documenting a precondition, into an array
    /// declaring `2**251` items over a 32 byte allocation.
    ///
    /// This is the composition that makes #54 and #62 one question rather than
    /// two. If `unsafeList` is fixed first this test takes the `catch` branch
    /// and passes without `flatten` changing at all, which is exactly the point:
    /// either end of the chain can close it.
    function testMintedLengthWordLaundersThroughMatrixFromAndFlatten() external view {
        try harness.mintThenFlatten(WRAP_PERIOD) returns (
            uint256 mintedLength, LibMatrixFlattenWrapHarness.Allocation memory allocation
        ) {
            uint256 capacity = allocation.allocatedBytes < 0x20 ? 0 : (allocation.allocatedBytes - 0x20) / 0x20;
            assertLe(allocation.declaredLength, capacity, "flatten declared more items than it allocated");
            assertLe(mintedLength, 4, "unsafeList minted a length word larger than the stack it was given");
        } catch {
            // A loud failure at either end of the chain is the acceptable
            // outcome.
        }
    }

    /// Premise control, and the reason this is a bug rather than a caller
    /// error.
    ///
    /// An inner length word that is out of range but does NOT wrap fails
    /// loudly: `flatten` reserves the full scaled size and dies expanding
    /// memory. `2**40 * 0x20` is `2**45` bytes, nowhere near the wrap.
    ///
    /// This test passes on `main` and is expected to keep passing under any
    /// fix. It pins the behaviour the tests above are contrasted against: the
    /// wrap is precisely what converts this loud failure into a cheap silent
    /// success.
    function testFlattenNonWrappingOversizedLengthFailsLoudly() external view {
        bool returnedSuccessfully;
        try harness.uint256Flatten{gas: 10_000_000}(1 << 40, 1 << 40) returns (
            LibMatrixFlattenWrapHarness.Allocation memory
        ) {
            returnedSuccessfully = true;
        } catch {}
        assertFalse(returnedSuccessfully, "premise: a non wrapping oversized inner length is expected to fail loudly");
    }
}
