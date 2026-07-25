# rain.solmem

Solidity memory libraries — pointer arithmetic, byte-level copying, and dynamic
arrays/matrices that don't go through Solidity's safety-checked allocator.

## Libraries

| Library            | What it does                                                              |
| ------------------ | ------------------------------------------------------------------------- |
| `LibPointer`       | Raw memory pointer arithmetic, with explicit `Pointer` user-defined type. |
| `LibMemCpy`        | Word-aligned and byte-aligned `memcpy` between memory pointers.           |
| `LibBytes`         | In-place mutation, slicing, and pointer-level access for `bytes`.         |
| `LibUint256Array`  | Dynamic `uint256[]` operations: extend, copy, dedup-sort, truncate.       |
| `LibBytes32Array`  | Dynamic `bytes32[]` mirror of `LibUint256Array`.                          |
| `LibUint256Matrix` | `uint256[][]` operations.                                                 |
| `LibBytes32Matrix` | `bytes32[][]` operations.                                                 |
| `LibStackPointer`  | Stack-style push/pop on a memory region accessed via `Pointer`.           |
| `LibStackSentinel` | Sentinel-terminated stack walks for unknown-length data.                  |

These libraries assume the caller knows what they're doing with memory. Out-of-
bounds access, double-frees, and aliasing are the caller's responsibility.

## Install

Via [soldeer](https://soldeer.xyz) (in your foundry project's root):

```sh
forge soldeer install rain-solmem~<version>
```

Versioned remappings end up in `dependencies/rain-solmem-<version>/`. Add the
remapping to `remappings.txt` or `foundry.toml`.

## Develop

This repo uses [nix](https://nixos.org/download.html) for its dev shell. The
default shell is the slim Solidity-only `sol-shell` from
[rainix](https://github.com/rainlanguage/rainix) — no rust, node, or chromium.

```sh
nix develop          # enter the shell
forge soldeer install # install dependencies declared in foundry.toml
forge test
```

Tasks exposed via the shell (delegate to rainix):

- `rainix-sol-test` — `forge test`
- `rainix-sol-static` — slither
- `rainix-sol-legal` — `reuse lint`
- `rainix-sol-artifacts` — `forge build`

Use the nix-pinned `forge` for all development to keep versions consistent.

## Publish

Tag `v<x.y.z>` on `main`. The
[`Publish to Soldeer`](.github/workflows/publish-soldeer.yaml) workflow runs
`forge soldeer push rain-solmem~<x.y.z>` on every `v*` tag. The package name is
derived from the repo name with `.` substituted for `-`.

## Audit

External audit reports live in `audit/protofire/`. The **filename encodes the
audited git ref**, which is what lets tooling measure drift against the exact
state that was reviewed rather than guessing from the file's commit date:

```
rain.solmem.228b35c6725877e7fbcd2432b4c692357f16f510.jan-2026.pdf
            ^ the audited commit
```

Two anchor forms are recognised, and a **tag wins** if a filename carries both:

- A `[sol-]v<x.y.z>` tag. The `sol-` prefix is part of the tag rather than
  decoration, and the result MUST be a tag that actually exists in this repo.
  The newest tag here is `sol-v0.1.4`; there is no bare `v0.1.4`, so a filename
  saying `v0.1.4` would resolve to nothing.
- A 7–40 character hex commit sha, which MUST resolve to a real commit in this
  repo. A hex-looking token that resolves to nothing is not an error — it
  silently degrades to unanchored.

Because the anchor is a real ref, "has this been audited?" and "has the audited
source changed since?" are separate questions with separate answers — a release
tag alone does not tell you the second one.

### An unanchored report is dated by the wrong commit

A report named without a resolvable anchor still counts as audited, but its
drift is dated from **the most recent commit to touch the PDF**, not the commit
that added it. Any later move, rename or re-commit silently resets that base to
the day it happened.

This repo is its own example. The PDF was moved into `audit/protofire/` on
2026-07-15, while the commit it anchors, `228b35c6`, dates from 2025-12-06.
Strip the anchor out of the filename and the audit reads as ~10 days old when
the reviewed source is in fact 231 days stale.

### The scope is exactly `audit/protofire/`

A PDF anywhere else under `audit/` is **not counted as an external audit**. The
scan deliberately walks `audit/protofire/` and only two levels deep, so a report
left at `audit/report.pdf` is silently invisible rather than merely misfiled.

### Also under `audit/`

`audit/mutation-test-scans.json` is the adversarial-mutation-test scan record: a
JSON array of run objects at the `audit/` root, one per run. It is read for the
newest entry **by timestamp**, never by position, so entries may be appended out
of order.

`audit/` and `.audit/` are different directories, with different owners and
different consumers. `.audit/` holds the audit skill's own run stamp
(`.audit/runs.jsonl`), written by that skill; `audit/` holds artifacts committed
deliberately. This repo has no `.audit/` yet, so the first audit-skill run
creates one — do not file its output under `audit/`, or vice versa.

### Nothing enforces any of this

The convention is kept by discipline. No CI check in this repo validates
filenames, the directory layout, or the presence of any of these files. Every
violation degrades silently: an unresolvable anchor, a misplaced PDF and a
malformed scan record all read downstream as "less audited" rather than failing
a check.

## License

DecentraLicense 1.0 (DCL-1.0) — full text in
[`LICENSES/`](LICENSES/LicenseRef-DCL-1.0.txt). Roughly `CAL-1.0`
([opensource.org](https://opensource.org/license/cal-1-0)) plus user-data
disclosure obligations consistent with permissionless-blockchain assumptions.
"Not your keys, not your coins" aware, in legalese.

This repo is [REUSE 3.2](https://reuse.software/spec-3.2/) compliant. Verify
locally:

```sh
nix develop -c rainix-sol-legal
```

## Contributions

Welcome under the same license. Contributors warrant that their contributions
are compliant.
