// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibPointer, Pointer} from "./LibPointer.sol";
import {UnalignedStackPointer} from "../error/ErrStackPointer.sol";
import {
    InvalidStackBounds,
    MissingSentinel,
    UnallocatedStack,
    ZeroSentinelTupleSize
} from "../error/ErrStackSentinel.sol";

/// > In computer programming, a sentinel value (also referred to as a flag
/// > value, trip value, rogue value, signal value, or dummy data)[1] is a
/// > special value in the context of an algorithm which uses its presence as a
/// > condition of termination, typically in a loop or recursive algorithm.
/// >
/// > The sentinel value is a form of in-band data that makes it possible to
/// > detect the end of the data when no out-of-band data (such as an explicit
/// > size indication) is provided. The value should be selected in such a way
/// > that it is guaranteed to be distinct from all legal data values since
/// > otherwise, the presence of such values would prematurely signal the end of
/// > the data (the semipredicate problem).
/// >
/// > - [Wikipedia](https://en.wikipedia.org/wiki/Sentinel_value)
type Sentinel is uint256;

/// @title LibStackSentinel
/// @notice Reads a sentinel terminated list off a stack. A stack region is
/// scanned downwards for a sentinel value and the words above it are rebuilt
/// in place as an array of fixed size tuples, which can be cast to structs.
/// The sentinel stands in for a length prefix, so the length is O(n) to
/// recover rather than O(1).
library LibStackSentinel {
    /// Given two stack pointers that bound a stack build an array of
    /// `tupleSize` item tuples above the given sentinel value. The sentinel is
    /// excluded from the tuples and a pointer TO it is returned alongside the
    /// tuples list.
    ///
    /// The tuples can be cast (via assembly) to structs.
    ///
    /// The caller MUST consider the region of memory consumed for the structs as
    /// mutated/truncated/deallocated and reallocated insitu to the tuples.
    ///
    /// The sentinel MUST be chosen to have a negligible chance of colliding with
    /// a real value in the array, otherwise an intended array item will be
    /// interpreted as a sentinel.
    ///
    /// An expression author that wants to model an empty/optional/absent value
    /// MAY provide a sentinel for a zero length array and the calling contract
    /// SHOULD handle this.
    ///
    /// `tupleSize` is scaled to a byte stride in checked Solidity, so a
    /// `tupleSize` too large to scale (`tupleSize > type(uint256).max / 0x20`)
    /// WILL REVERT with an arithmetic overflow panic. That and zero are the
    /// only bounds on `tupleSize`. There is no check that the stack is large
    /// enough to hold whole tuples of that stride, so the scan steps down from
    /// `upper` in strides of `tupleSize * 0x20` BYTES and a stride that the
    /// remaining range cannot be stepped down by steps the cursor past zero and
    /// wraps it. There is no explicit underflow check and the resulting failure
    /// is deliberately not uniform: almost every wrapped cursor lands at an
    /// unaddressable position, where the read exhausts the whole gas allowance
    /// of the call frame, but a stride within a few words of `2**256` wraps to
    /// a small step UPWARD and the scan reads above `upper` instead.
    ///
    /// What IS guaranteed is that an underflowing scan cannot silently
    /// succeed. `sentinelPointer` is ALWAYS within `[lower, upper)`, and a scan
    /// that walked out of that range reverts with `MissingSentinel` exactly as
    /// a scan that found nothing at all does. Gas exhaustion is therefore a
    /// tolerated mechanism rather than a promise: a caller MUST NOT depend on
    /// WHICH of these failures it gets, only that it gets one.
    ///
    /// The scan steps in whole words down from `upper`, so `lower` and `upper`
    /// MUST be aligned WITH EACH OTHER to 32 bytes, i.e. the distance between
    /// them MUST be a whole number of words. Neither pointer need be 32 byte
    /// aligned in absolute terms, as a shared sub-word offset cancels out of
    /// the distance. Pointers that are not word aligned with each other WILL
    /// REVERT with `UnalignedStackPointer`.
    ///
    /// The tuples array is allocated at the allocated memory pointer and grows
    /// upward from there, so a stack that extends above the allocated memory
    /// pointer would be overwritten by the very array that references it. The
    /// stack therefore MUST be within allocated memory. A stack that extends
    /// above the allocated memory pointer and contains the sentinel WILL REVERT
    /// with `UnallocatedStack`. The search for the sentinel only reads memory,
    /// so the same stack without the sentinel in it reverts with
    /// `MissingSentinel` instead.
    ///
    /// @param lower Pointer to the bottom of the stack range. MUST NOT be above
    /// `upper` or this reverts with `InvalidStackBounds`.
    /// @param upper Pointer to the top of the stack range. MUST be a whole
    /// number of words above `lower` and MUST NOT be above the allocated memory
    /// pointer.
    /// @param sentinel The value to expect as the sentinel. MUST be present in
    /// the stack ON A TUPLE BOUNDARY or this reverts with `MissingSentinel`.
    /// MUST NOT collide with valid stack items (or be cryptographically
    /// improbable to do so).
    /// @param tupleSize The number of items per tuple. MUST NOT be zero or this
    /// reverts with `ZeroSentinelTupleSize`.
    /// @return sentinelPointer Pointer to the word holding the sentinel that
    /// was found, ALWAYS within `[lower, upper)`.
    /// @return tuplesPointer Pointer to the `tupleSize` item tuples array that
    /// was built.
    function consumeSentinelTuples(Pointer lower, Pointer upper, Sentinel sentinel, uint256 tupleSize)
        internal
        pure
        returns (Pointer sentinelPointer, Pointer tuplesPointer)
    {
        if (tupleSize == 0) {
            revert ZeroSentinelTupleSize();
        }
        if (Pointer.unwrap(upper) < Pointer.unwrap(lower)) {
            revert InvalidStackBounds(lower, upper);
        }
        // The scan steps in whole words down from `upper`, so an `upper` that
        // is not a whole number of words above `lower` puts every probe and
        // every tuple reference across the boundary of two of the caller's
        // stack items.
        if ((Pointer.unwrap(upper) - Pointer.unwrap(lower)) % 0x20 != 0) {
            revert UnalignedStackPointer(lower, upper);
        }

        // Each tuple takes this much space in memory. Scaled in checked
        // Solidity, so a `tupleSize` too large to express as a byte stride
        // reverts with an arithmetic overflow panic rather than wrapping to a
        // small stride and serving the request as if a much smaller
        // `tupleSize` had been asked for.
        uint256 size = tupleSize * 0x20;

        // First pass to find the sentinel.
        assembly ("memory-safe") {
            // `size` is a whole number of words and the bounds are word
            // aligned with each other, so the cursor is always congruent to
            // `lower` modulo 32 no matter how many times it wraps.
            // `gt(cursor, lower)` therefore implies `cursor >= lower + 0x20`,
            // and the probe at `sub(cursor, 0x20)` can never fall below
            // `lower`.
            //
            // A stride the cursor cannot be stepped down by wraps past zero.
            // Almost always that is an unaddressable position and the read
            // exhausts gas, but a stride within a few words of `2**256` wraps
            // to a small step UPWARD and the scan walks out above `upper`,
            // reading memory the caller never described. The `>= upper` check
            // below is what stops that being reported as a success.
            for { let cursor := upper } gt(cursor, lower) { cursor := sub(cursor, size) } {
                let potentialSentinelPointer := sub(cursor, 0x20)
                if eq(mload(potentialSentinelPointer), sentinel) {
                    sentinelPointer := potentialSentinelPointer
                    break
                }
            }
        }

        // We revert if the sentinel was not found, and equally if it was
        // "found" outside the range the caller described. A scan whose cursor
        // wrapped upward reads above `upper`, where a sentinel valued word
        // belongs to whoever owns that memory, not to this stack. The probe can
        // never fall below `lower` (see the scan loop), so the upper bound is
        // the whole of the range check.
        if (Pointer.unwrap(sentinelPointer) == 0 || Pointer.unwrap(sentinelPointer) >= Pointer.unwrap(upper)) {
            revert MissingSentinel(sentinel);
        }

        // The tuples array is allocated at the allocated memory pointer and
        // grows upward, so a stack above the allocated memory pointer is
        // overlapped and overwritten by the array that references it.
        {
            Pointer allocated = LibPointer.allocatedMemoryPointer();
            if (Pointer.unwrap(upper) > Pointer.unwrap(allocated)) {
                revert UnallocatedStack(upper, allocated);
            }
        }

        // Second pass to build references _in order_ from the sentinel back up
        // to upper.
        assembly ("memory-safe") {
            tuplesPointer := mload(0x40)
            let tuplesCursor := add(tuplesPointer, 0x20)
            for { let cursor := add(sentinelPointer, 0x20) } lt(cursor, upper) {
                tuplesCursor := add(tuplesCursor, 0x20)
                cursor := add(cursor, size)
            } {
                // Write the reference to the tuple.
                mstore(tuplesCursor, cursor)
            }
            // Update allocated memory pointer past the tuples.
            mstore(0x40, tuplesCursor)
            // Store tuples length.
            mstore(tuplesPointer, sub(div(sub(tuplesCursor, tuplesPointer), 0x20), 1))
        }
    }
}
