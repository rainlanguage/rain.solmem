# Changelog

The version a merge to `main` publishes is `[package].version` in
`foundry.toml` at merge time. A PR that changes the shipped package adds its
entry under that version, and raises it beyond a patch when the change breaks a
consumer.

## 0.1.16

- Ship this changelog in the package.

## 0.1.15

- Docs: the `evm_version = "cancun"` compile floor and the `mcopy` runtime
  requirement are stated in the shipped README.

## 0.1.14

- Docs: `endPointer` on both matrix libraries returns one word past the last
  inner-array reference, not the end of an allocation; writing there corrupts
  the inner arrays. The `bytes` and array end pointers are derived from the
  current length word, which `truncate` moves below the real allocation.

## 0.1.13

- `unsafeExtend(a, a)` allocates and copies instead of rewriting `a`'s length
  word in place, which mutated the array it documents as untouched. Both array
  libraries.

## 0.1.12

- No change to the shipped source.

## 0.1.11

- **Breaking:** `LibStackPointer` removed.
- `consumeSentinelTuples` reverts with `MissingSentinel` when the sentinel it
  finds lies at or above
  `upper`, which a stride within a few words of `2**256` reached by wrapping
  the cursor upward out of the caller's range.

## 0.1.10

- Word scaling in `LibStackSentinel` and `LibStackPointer` is done in checked
  Solidity, so a tuple count or length too large to scale reverts with an
  overflow panic instead of wrapping to a small stride.
- `itemCount` reverts on overflow, and `flatten` no longer mints an array whose
  declared length exceeds its allocation. Both matrix libraries.

## 0.1.9

- `consumeSentinelTuples` reverts with `UnallocatedStack` when `upper` is above
  the allocated memory pointer, where the tuples array is allocated over the
  stack it references.

## 0.1.8

- `consumeSentinelTuples` reverts with `UnalignedStackPointer` when `lower` and
  `upper` are not word aligned with each other, which returned tuples assembled
  from straddled words.

## 0.1.7

- No change to the shipped source.

## 0.1.6

- Docs: `unsafeCopyWordsTo` can silently overflow.

## 0.1.5

- Docs: `toIndexSigned` needs relative, not absolute, alignment.

## 0.1.4

- `unsafeExtend` reads `extend.length` before overwriting `base`'s length word.
  With `base == extend` the two are the same word, so the re-read yielded the
  combined length and the copy ran past the free memory pointer. Both array
  libraries.
