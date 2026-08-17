// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibStackPointer} from "src/lib/LibStackPointer.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {Pointer} from "src/lib/LibPointer.sol";

/// Harness for `LibStackPointer.unsafeList`.
///
/// Every probe runs its whole scenario inside a single external call, so an
/// implementation that fails loudly takes only this frame down and the test can
/// observe "reverted" as an outcome rather than suffering it as a test failure.
/// The probes return plain words, so the test never has to touch the memory
/// this frame allocated.
contract LibStackPointerWrapHarness {
    using LibStackPointer for Pointer;
    using LibBytes32Array for bytes32[];

    /// Planted in a neighbouring allocation. Survival of this value is the
    /// invariant under test.
    bytes32 public constant CANARY = bytes32(uint256(0xC0FFEE));

    /// Written through the array `unsafeList` returns. Finding this value in
    /// the neighbour means the write escaped the stack `unsafeList` was handed.
    bytes32 public constant SCRIBBLE = bytes32(uint256(0xBADBAD));

    /// What a caller can observe about a `unsafeList` result and its
    /// surroundings without any assembly of its own.
    /// @param claimedLength The length word `unsafeList` minted, read back as
    /// `tail.length`.
    /// @param neighbourLength The length word of an unrelated array allocated
    /// before the call.
    /// @param neighbourFirst The first element of that unrelated array.
    struct Observation {
        uint256 claimedLength;
        uint256 neighbourLength;
        bytes32 neighbourFirst;
    }

    /// Builds a four item stack with an unrelated four item array allocated
    /// immediately above it, lists `length` items off the stack, then writes
    /// `SCRIBBLE` through the returned array at `index` using ordinary bounds
    /// checked Solidity.
    ///
    /// Solidity's bounds check consults the length word `unsafeList` just
    /// minted, so the library's own output is what licenses the write. There is
    /// no assembly on the write path.
    /// @param length Passed straight through to `unsafeList`.
    /// @param index The index written through the returned array.
    /// @return observation See `Observation`.
    function listThenWriteThroughResult(uint256 length, uint256 index)
        external
        pure
        returns (Observation memory observation)
    {
        return scenario(length, index);
    }

    /// The same scenario, but `length` comes from an `unchecked` subtraction
    /// with the operands the wrong way around rather than from a literal. This
    /// is the shape of an ordinary off by one in a consumer, not a hand
    /// authored constant.
    /// @param have The minuend.
    /// @param want The subtrahend.
    /// @param index The index written through the returned array.
    /// @return observation See `Observation`.
    function listUncheckedDifference(uint256 have, uint256 want, uint256 index)
        external
        pure
        returns (Observation memory observation)
    {
        uint256 length;
        unchecked {
            length = have - want;
        }
        return scenario(length, index);
    }

    /// Lists `length` items and reports only the minted length word, writing
    /// nothing through the result.
    /// @param length Passed straight through to `unsafeList`.
    /// @return claimedLength The length word `unsafeList` minted.
    function listClaimedLength(uint256 length) external pure returns (uint256 claimedLength) {
        bytes32[] memory stack = new bytes32[](4);
        (, bytes32[] memory tail) = stack.endPointer().unsafeList(length);
        return tail.length;
    }

    /// The scenario shared by `listThenWriteThroughResult` and
    /// `listUncheckedDifference`.
    /// @param length Passed straight through to `unsafeList`.
    /// @param index The index written through the returned array.
    /// @return observation See `Observation`.
    function scenario(uint256 length, uint256 index) internal pure returns (Observation memory observation) {
        bytes32[] memory stack = new bytes32[](4);
        stack[0] = bytes32(uint256(0xA0));
        stack[1] = bytes32(uint256(0xA1));
        stack[2] = bytes32(uint256(0xA2));
        stack[3] = bytes32(uint256(0xA3));

        bytes32[] memory neighbour = new bytes32[](4);
        neighbour[0] = CANARY;
        neighbour[1] = CANARY;
        neighbour[2] = CANARY;
        neighbour[3] = CANARY;

        (, bytes32[] memory tail) = stack.endPointer().unsafeList(length);
        observation.claimedLength = tail.length;

        tail[index] = SCRIBBLE;

        observation.neighbourLength = neighbour.length;
        observation.neighbourFirst = neighbour[0];
    }
}
