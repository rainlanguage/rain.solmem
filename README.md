# rain.solmem

Solidity memory libraries — pointer arithmetic, byte-level copying, and dynamic
arrays/matrices that don't go through Solidity's safety-checked allocator.

## Libraries

| Library            | What it does                                                              |
| ------------------ | ------------------------------------------------------------------------- |
| `LibPointer`       | Raw memory pointer arithmetic, with explicit `Pointer` user-defined type. |
| `LibMemCpy`        | Word-aligned and byte-aligned `memcpy` between memory pointers.           |
| `LibBytes`         | In-place `truncate`, plus start/data/end/allocated pointers.              |
| `LibUint256Array`  | `arrayFrom` literals, `unsafeExtend`, `truncate`, `reverse`, pointers.    |
| `LibBytes32Array`  | Dynamic `bytes32[]` mirror of `LibUint256Array`.                          |
| `LibUint256Matrix` | `uint256[][]` operations.                                                 |
| `LibBytes32Matrix` | `bytes32[][]` operations.                                                 |
| `LibStackSentinel` | Sentinel-terminated stack walks for unknown-length data.                  |

These libraries assume the caller knows what they're doing with memory. Out-of-
bounds access, double-frees, and aliasing are the caller's responsibility.

## Errors

| Error                   | Import from                     | Thrown by                                |
| ----------------------- | ------------------------------- | ---------------------------------------- |
| `TruncateError`         | `src/error/ErrBytes.sol`        | `LibBytes.truncate`                      |
| `OutOfBoundsTruncate`   | `src/error/ErrUint256Array.sol` | `truncate` on both array libs            |
| `UnalignedStackPointer` | `src/error/ErrStackPointer.sol` | `LibStackSentinel.consumeSentinelTuples` |
| `ZeroSentinelTupleSize` | `src/lib/LibStackSentinel.sol`  | `LibStackSentinel.consumeSentinelTuples` |
| `MissingSentinel`       | `src/lib/LibStackSentinel.sol`  | `LibStackSentinel.consumeSentinelTuples` |
| `InvalidStackBounds`    | `src/lib/LibStackSentinel.sol`  | `LibStackSentinel.consumeSentinelTuples` |
| `UnallocatedStack`      | `src/lib/LibStackSentinel.sol`  | `LibStackSentinel.consumeSentinelTuples` |

`itemCount` and `flatten` on both matrix libs, and
`LibStackSentinel.consumeSentinelTuples`, also revert with `Panic(uint256)` code
`0x11` on arithmetic overflow.

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
nix develop -c rainix-sol-legal
```

## Contributions

Welcome under the same license. Contributors warrant that their contributions
are compliant.
