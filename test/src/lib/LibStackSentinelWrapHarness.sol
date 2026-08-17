// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibStackSentinel, Sentinel} from "src/lib/LibStackSentinel.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";
import {Pointer} from "src/lib/LibPointer.sol";

/// Harness for `LibStackSentinel.consumeSentinelTuples`.
///
/// The stack region has to be built in the same frame that calls the library,
/// because an external call gets a fresh memory frame and any region planted by
/// the caller simply would not exist in it. So the probe builds the region,
/// calls the library and reduces the result to plain words, all inside one
/// external call. The external boundary is what lets the test observe a loud
/// failure as an outcome instead of suffering it as a test failure.
contract LibStackSentinelWrapHarness {
    using LibUint256Array for uint256[];

    /// The sentinel planted at the bottom of the probe's stack region.
    Sentinel public constant SENTINEL = Sentinel.wrap(uint256(keccak256("rain.solmem.test.sentinel")));

    /// The probe's stack region is this many words: the sentinel plus
    /// `STACK_WORDS - 1` items above it.
    uint256 public constant STACK_WORDS = 4;

    /// Builds a `STACK_WORDS` word region with the sentinel at the bottom and
    /// consumes it as tuples of `n` items each, reporting what came back.
    /// @param n The tuple size, passed straight through to the library.
    /// @return sentinelPointer The pointer the library reported the sentinel at.
    /// @return tuplesLength The number of tuples the library reported building.
    /// @return firstTuple The first tuple pointer, or zero if there are none.
    function consume(uint256 n)
        external
        pure
        returns (uint256 sentinelPointer, uint256 tuplesLength, uint256 firstTuple)
    {
        uint256[] memory stack = new uint256[](STACK_WORDS);
        stack[0] = Sentinel.unwrap(SENTINEL);
        for (uint256 i = 1; i < STACK_WORDS; i++) {
            stack[i] = i;
        }

        (Pointer foundSentinel, Pointer tuplesPointer) =
            LibStackSentinel.consumeSentinelTuples(stack.dataPointer(), stack.endPointer(), SENTINEL, n);

        uint256[] memory tuples;
        assembly ("memory-safe") {
            tuples := tuplesPointer
        }

        sentinelPointer = Pointer.unwrap(foundSentinel);
        tuplesLength = tuples.length;
        firstTuple = tuplesLength > 0 ? tuples[0] : 0;
    }
}
