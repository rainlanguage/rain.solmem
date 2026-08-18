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

Tasks in the shell:

- `forge build` — compile.
- `forge test` — the test suite.
- `forge fmt --check` — formatting.
- `slither .` — static analysis, config in `slither.config.json`.
- `reuse lint` — REUSE compliance.

CI runs all of those except `forge build`, plus `rainix-sol-single-contract`,
which this repo's pinned rainix does not provide.

`rainix-sol-artifacts` is on `PATH` too and is not a build. It runs
`forge selectors up --all` against the public selector registry, then
`forge script script/Deploy.sol` against `$ETH_RPC_URL` signed with
`DEPLOYMENT_KEY`, broadcasting when `DEPLOY_BROADCAST` is set. There is no
`script/` directory here. Do not run it.

Use the nix-pinned `forge` for all development to keep versions consistent.

## Publish

Tag `v<x.y.z>` on `main`. The
[`Publish to Soldeer`](.github/workflows/publish-soldeer.yaml) workflow runs
`forge soldeer push rain-solmem~<x.y.z>` on every `v*` tag. The package name is
derived from the repo name with `.` substituted for `-`.

## License

DecentraLicense 1.0 (DCL-1.0) — full text in
[`LICENSES/`](LICENSES/LicenseRef-DCL-1.0.txt). Roughly `CAL-1.0`
([opensource.org](https://opensource.org/license/cal-1-0)) plus user-data
disclosure obligations consistent with permissionless-blockchain assumptions.
"Not your keys, not your coins" aware, in legalese.

This repo is [REUSE 3.2](https://reuse.software/spec-3.2/) compliant. Verify
locally:

```sh
nix develop -c reuse lint
```

## Contributions

Welcome under the same license. Contributors warrant that their contributions
are compliant.
