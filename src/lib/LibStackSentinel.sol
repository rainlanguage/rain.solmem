// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibPointer, Pointer} from "./LibPointer.sol";
import {UnalignedStackPointer} from "../error/ErrStackPointer.sol";

/// Thrown when the sentinel tuple size is zero.
error ZeroSentinelTupleSize();

/// Thrown when the sentinel cannot be found. This can be because the sentinel
/// was not in the stack, but also if the sentinel is in the stack but not
/// aligned with the tuples size, or if the scan stepped outside the stack
/// bounds and only found a sentinel valued word out there, which is not the
/// caller's sentinel.
/// @param sentinel The sentinel that was not found.
error MissingSentinel(Sentinel sentinel);

/// Thrown when the stack bounds are invalid because the lower is above the
/// upper.
/// @param lower The lower stack pointer.
/// @param upper The upper stack pointer.
error InvalidStackBounds(Pointer lower, Pointer upper);

/// Thrown when the top of the stack is above the allocated memory pointer, so
/// the tuples array cannot be built without overwriting the stack it describes.
/// @param upper The upper stack pointer.
/// @param allocated The allocated memory pointer.
error UnallocatedStack(Pointer upper, Pointer allocated);

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

/// Rainlang has no dynamic list data type as every stack item MUST be explicit
/// in the structure of the code itself. While it would be possible for users to
/// manually code length prefixes into the stack, this would be error prone and
/// generally hostile to the overall DX. Instead we can allow sentinels as an
/// option that is merely awkward rather than downright pathological.
///
/// Rainlang authors can use a single sentinel value that is constant across all
/// their expressions rather than a calculated length prefix. This value can even
/// be aliased in onchain metadata and referenced by name for ease of use. The
/// calling contract defines and consumes sentinels, so the expression author
/// does not need to be aware of or have control over any subtleties in choice of
/// sentinel.
///
/// The main tradeoffs for sentinel terminated lists on a stack are similar to
/// null-terminated strings,
/// as per [Wikipedia](https://en.wikipedia.org/wiki/Null-terminated_string)
///
/// > While simple to implement, this representation has been prone to errors and
/// > performance problems.
///
/// This library attempts to mitigate potential implementation errors with a
/// standard implementation that has been fuzzed and optimized for building lists
/// of tuples (and therefore lists of structs via. a direct type cast). The main
/// implementation issues in null-terminated strings are avoided:
///
/// - Using any sentinel value other than `0`, such as the hash of some well
///   known string, will avoid misinterpreting unallocated memory as a sentinel.
/// - Any underflow manifests as either a "missing sentinel" or a read from an
///   unaddressable position, which revert due to an explicit check and gas
///   limits respectively. An underflowing scan can never report a sentinel
///   from outside the range it was given.
/// - Given that a sentinel is `uint256` it is possible to construct a value that
///   is very unlikely to collide with real values in the implementation domain.
/// - Well behaved integrity checks will ensure the memory for the sentinel is
///   allocated as any other stack item.
///
/// Sadly there is no way to avoid the O(n) performance overhead of searching for
/// a sentinel vs. O(1) of reading a length prefix directly. This is somewhat
/// mitigated by the nature of a hand-written stack being small in
/// computing terms, and that each item being iterated over is an entire struct
/// rather than individual stack values. Assembly is used to keep the looping
/// overhead to a minimum.
library LibStackSentinel {
    using LibStackSentinel for Pointer;

    /// Given two stack pointers that bound a stack build an array of
    /// `tupleSize` item tuples above the given sentinel value. The sentinel
    /// will be skipped and a pointer below it returned alongside the tuples
    /// list.
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
    /// If the sentinel is absent in the stack this WILL REVERT. The intent is
    /// to represent dynamic length arrays without forcing expression authors to
    /// calculate lengths on the stack. If the expression author wants to model
    /// an empty/optional/absent value they MAY provided a sentinel for a zero
    /// length array and the calling contract SHOULD handle this.
    ///
    /// `tupleSize` is scaled to a byte stride in checked Solidity, so a
    /// `tupleSize` too large to scale (`tupleSize > type(uint256).max / 0x20`)
    /// WILL REVERT with an arithmetic overflow panic. Together with
    /// `tupleSize != 0` that is the only bound on `tupleSize`. There is no
    /// check that the stack is large enough to hold whole tuples of that
    /// stride, so the scan steps down from `upper` in strides of
    /// `tupleSize * 0x20` BYTES and a stride that the remaining range cannot
    /// be stepped down by steps the cursor past zero and wraps it. There is no
    /// explicit underflow check and the resulting failure is deliberately not
    /// uniform: almost every wrapped cursor lands at an unaddressable
    /// position, where the read exhausts the whole gas allowance of the call
    /// frame, but a stride within a few words of `2**256` wraps to a small
    /// step UPWARD and the scan reads above `upper` instead.
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
    /// @param upper Pointer to the top of the stack range. MUST NOT be below
    /// `lower`, MUST be a whole number of words above it, and MUST NOT be above
    /// the allocated memory pointer.
    /// @param lower Pointer to the bottom of the stack range.
    /// @param sentinel The value to expect as the sentinel. MUST be present in
    /// the stack or `consumeSentinel` will revert. MUST NOT collide with valid
    /// stack items (or be cryptographically improbable to do so).
    /// @param tupleSize The number of items per tuple.
    /// @return sentinelPointer Pointer to the sentinel that was found, ALWAYS
    /// within `[lower, upper)`. A missing sentinel WILL REVERT.
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
