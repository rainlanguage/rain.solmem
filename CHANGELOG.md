# Changelog

What changed in every published `rain-solmem` revision, so a consumer can tell a
memory corruption fix from a comment edit without diffing two package zips.

This file ships inside the Soldeer package, so it is readable at
`dependencies/rain-solmem-<version>/CHANGELOG.md`.

Each heading is a Soldeer revision. The top heading is the version in
`[package].version` of `foundry.toml`: the next, unpublished revision, which is
what the package is published under the next time its content changes. Dates are
the revision's registry timestamp, UTC, and are filled in once it is published.

Every pull request that changes `src/**` adds an entry under the top heading.

Revisions below `0.1.2` predate the Soldeer registry's record of this package.

## 0.1.11

### Added

- This changelog.

## 0.1.10 — 2026-08-17

### Fixed

- `LibStackPointer.unsafeList` scaled `length` to a byte offset in unchecked
  assembly. A `length` above `type(uint256).max / 0x20` wrapped that offset
  while the length word written into the header did not, so the header landed as
  if a small array had been requested and then claimed the full `length`.
  Solidity's own bounds check trusts that length word, so the result was a read
  and write primitive over the whole heap, reachable from callers containing no
  assembly. The scaling is now checked and reverts with an arithmetic overflow
  panic.
- `LibStackSentinel.consumeSentinelTuples` scaled the tuple size `n` to a byte
  stride in unchecked assembly, so an oversized `n` wrapped to a small stride
  and the scan served the request as if a much smaller `n` had been asked for.
  The scaling is now checked and reverts with an arithmetic overflow panic.
- `LibUint256Matrix.itemCount` and `LibBytes32Matrix.itemCount` summed sub array
  lengths unchecked, so a wrapping total returned a count smaller than one of
  the sub arrays it was totalling. The running total now reverts with
  `Panic(uint256)` code `0x11` on wrap, byte for byte what checked Solidity
  arithmetic produces.
- `LibUint256Matrix.flatten` and `LibBytes32Matrix.flatten` scaled the item
  count to an allocation size unchecked. A wrapping scale sized the allocation
  from one number while stamping the length word from another, handing back an
  array whose declared length far exceeded the memory reserved for it. The
  scaling is now checked and reverts with an arithmetic overflow panic.

### Documentation

- `LibStackSentinel.consumeSentinelTuples` documents that the failure modes for
  a tuple stride the stack cannot hold are not uniform, and that an out of range
  `n` is not guaranteed to fail loudly.
- `LibUint256Matrix.flatten` and `LibBytes32Matrix.flatten` state the premise
  their copy loop's no-wrap argument rests on: the loop only writes above the
  free memory pointer as it stood on entry, so the sub array length words it
  re-reads are the ones `itemCount` summed.

## 0.1.9 — 2026-08-05

### Changed

- `LibStackSentinel.consumeSentinelTuples` reverts with the new error
  `UnallocatedStack(Pointer upper, Pointer allocated)` when the stack extends
  above the allocated memory pointer. The tuples array is allocated at that
  pointer and grows upward, so such a stack was overwritten by the very array
  that referenced it. Inputs that previously returned now revert.

## 0.1.8 — 2026-08-05

### Changed

- `LibStackSentinel.consumeSentinelTuples` checks its stack bounds before
  scanning. An `upper` below `lower` reverts with `InvalidStackBounds` up front
  rather than only on the missing sentinel path, and an `upper` that is not a
  whole number of words above `lower` reverts with `UnalignedStackPointer`.
  Unaligned bounds previously scanned across the boundary of two of the caller's
  stack items. Inputs that previously returned now revert.

### Documentation

- The `MissingSentinel` doc no longer lists `upper` below `lower` as one of its
  triggers, which is now its own error.

## 0.1.7 — 2026-07-25

No library source changes. Packaging metadata only.

## 0.1.6 — 2026-07-25

### Documentation

- `LibMemCpy.unsafeCopyWordsTo` documents that its byte count `length * 32` is
  computed in unchecked assembly, that the resulting wrap is periodic at every
  multiple of `2**251` rather than a tail above one threshold, and that an
  affordable residue larger than the caller's allocation over-copies past it and
  returns successfully. No behaviour change.

## 0.1.5 — 2026-07-25

### Documentation

- `LibStackPointer.toIndexSigned` documents that its two pointers must be word
  aligned with each other, not aligned in absolute terms, and that `upper` may
  be below `lower` for a negative index. No behaviour change.

## 0.1.4 — 2026-07-25

### Fixed

- `LibUint256Array.unsafeExtend` and `LibBytes32Array.unsafeExtend` read
  `extend`'s length word after overwriting `base`'s. When `extend` aliases
  `base` those are the same word, so the copy ran on the already combined length
  and wrote past the free memory pointer. The length is now read once, before
  the write.

## 0.1.3 — 2026-05-09

No library source changes. CI configuration only, none of which is part of the
package, so this revision's contents are identical to `0.1.2`'s.

## 0.1.2 — 2026-05-09

No library source changes. A README rewrite and a publish workflow change, of
which only the README is part of the package.
