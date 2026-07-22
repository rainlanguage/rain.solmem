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

Either a `v<x.y.z>` tag or a 7–40 character commit sha is recognised. A report
named without one still counts as an audit, but its drift is dated from the
commit that added the PDF, which is less precise.

Because the anchor is a real ref, "has this been audited?" and "has the audited
source changed since?" are separate questions with separate answers — a release
tag alone does not tell you the second one.

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
