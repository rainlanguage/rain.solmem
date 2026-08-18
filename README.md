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
| `LibStackSentinel` | Sentinel-terminated stack walks for unknown-length data.                  |

These libraries assume the caller knows what they're doing with memory. Out-of-
bounds access, double-frees, and aliasing are the caller's responsibility.

## Requirements

- **solc `^0.8.25`**, which every source file declares.
- **`evm_version = "cancun"` or later, and a chain with cancun activated.**
  Every copy path compiles to the `mcopy` opcode. Building below cancun fails at
  compile time; cancun bytecode on a chain without cancun reverts with
  `invalid opcode` at runtime.

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

Publishing is merge-driven; there is no release tag to push. On every push to
`main`, [`Package Release`](.github/workflows/package-release.yaml) calls
rainix's `rainix-autopublish`, which compares the package content against the
latest published revision. If it differs, it runs
`forge soldeer push rain-solmem~<version>`, tags `sol-v<version>`, and commits a
bump of `[package] version` back to `main`.

`[package] version` in `foundry.toml` is the **next, unpublished** version, not
the current one. It is always one ahead of the registry; do not "correct" it to
match.

Everything [`.soldeerignore`](.soldeerignore) does not exclude ships — `src/**`,
`README.md`, `LICENSE`, `LICENSES/`, `REUSE.toml` — and any change to it
publishes a new revision, including a comment-only edit. Soldeer revisions are
immutable and cannot be deleted.

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
