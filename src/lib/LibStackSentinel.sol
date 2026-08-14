// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibPointer, Pointer} from "./LibPointer.sol";
import {UnalignedStackPointer} from "../error/ErrStackPointer.sol";

/// Thrown when the sentinel tuple size is zero.
error ZeroSentinelTupleSize();

/// Thrown when the sentinel cannot be found. This can be because the sentinel
/// was not in the stack, but also if the sentinel is in the stack but not
/// aligned with the tuples size.
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
/// - Most underflows manifest as either a "missing sentinel" or a read from an
///   unaddressable position, which revert due to an explicit check and gas
///   limits respectively. This is NOT universal: see the failure modes
///   documented on `consumeSentinelTuples` for the strides that underflow to a
///   position the scan can keep reading from.
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

    /// Given two stack pointers that bound a stack build an array of `n` item
    /// tuples above the given sentinel value. The sentinel will be skipped and
    /// a pointer below it returned alongside the tuples list.
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
    /// `n` is scaled to a byte stride in checked Solidity, so an `n` too large
    /// to scale (`n > type(uint256).max / 0x20`) WILL REVERT with an arithmetic
    /// overflow panic. That is the only bound on `n`. There is no check that
    /// the stack is large enough to hold whole tuples of that stride, and the
    /// failure modes for a stride the stack cannot hold are NOT uniform:
    ///
    /// - A stride larger than the stack but no larger than `upper` steps the
    ///   scan below `lower` after its first probe, which ends the scan. Unless
    ///   the sentinel is the top word of the stack, that reverts with
    ///   `MissingSentinel`.
    /// - A stride larger than `upper` steps the scan past zero and back to
    ///   `2**256 - size` above the cursor. For most strides that is an
    ///   unaddressable position and the read exhausts gas, but for a stride
    ///   within a few words of `2**256` it is a small step UPWARD, and the scan
    ///   then reads above `upper`, outside the range the caller supplied. Such
    ///   a scan CAN find a sentinel valued word out of range and return a
    ///   `sentinelPointer` above `upper` without reverting.
    ///
    /// So an out of range `n` is not guaranteed to fail loudly. The caller MUST
    /// ensure the stack between `lower` and `upper` holds a whole number of `n`
    /// item tuples above the sentinel.
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
    /// @param n The number of items per tuple.
    /// @return sentinelPointer Pointer to the sentinel that was found. A missing
    /// sentinel WILL REVERT.
    /// @return tuplesPointer Pointer to the n-item tuples array that was built.
    function consumeSentinelTuples(Pointer lower, Pointer upper, Sentinel sentinel, uint256 n)
        internal
        pure
        returns (Pointer sentinelPointer, Pointer tuplesPointer)
    {
        if (n == 0) {
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
        // Solidity, so an `n` too large to express as a byte stride reverts
        // with an arithmetic overflow panic rather than wrapping to a small
        // stride and serving the request as if a much smaller `n` had been
        // asked for.
        uint256 size = n * 0x20;

        // First pass to find the sentinel.
        assembly ("memory-safe") {
            // `size` is a whole number of words and the stack is a whole number
            // of words, so a stride that fits the stack walks `cursor` down to
            // `lower` exactly. A stride that does not fit steps `cursor` below
            // `lower` and the loop ends, unless the step underflows past zero,
            // in which case `cursor` lands back at `add(cursor, sub(0, size))`
            // and the scan continues from there. There is no explicit bound on
            // where that lands, so the caller MUST size the stack for `n`.
            for { let cursor := upper } gt(cursor, lower) { cursor := sub(cursor, size) } {
                let potentialSentinelPointer := sub(cursor, 0x20)
                if eq(mload(potentialSentinelPointer), sentinel) {
                    sentinelPointer := potentialSentinelPointer
                    break
                }
            }
        }

        // We revert if the sentinel was not found.
        if (Pointer.unwrap(sentinelPointer) == 0) {
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
