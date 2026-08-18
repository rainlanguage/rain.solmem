# rain.solmem

Solidity memory libraries — pointer arithmetic, byte-level copying, and dynamic
arrays/matrices built in raw assembly rather than through Solidity's
bounds-checked, zeroing array handling. Allocating functions still read and
update the free memory pointer at `0x40`; the safety checks are skipped, the
allocator is not.

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

## Safety contract

These libraries assume the caller knows what they're doing with memory. There is
no `free` in EVM memory, so the hazards are out-of-bounds reads and writes,
silent pointer wraparound, and aliasing.

- A `Pointer` is a bare `uint256`. `LibPointer` arithmetic wraps silently and is
  checked against neither `0x40` nor the length prefix of the structure the
  pointer came from.
- `unsafe*` functions perform no bounds checks. The caller MUST establish, at
  its own call sites, that every read is in bounds and every write lands in
  memory the caller owns.
- Functions that allocate read and update `0x40` themselves, so they MUST NOT be
  interleaved with hand-written assembly that caches `0x40` across the call.
- `unsafeExtend` MAY mutate its base argument in place and MAY return a pointer
  to it. Use the returned array only.
- Overlap between arguments is the caller's problem. Every array or `bytes`
  argument MUST be a valid Solidity memory structure that owns the region its
  own length word describes.
- Every assembly block in `src/` is annotated `("memory-safe")`. That annotation
  is an assertion to the compiler, not a guarantee to the caller: it holds for
  these functions only while the obligations above hold. The functions are
  `internal` and inline, so the assertion lands inside the consumer's own
  compilation unit.

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

## Audit

Protofire reviewed rain.solmem in January 2026. The
[report](audit/protofire/rain.solmem.228b35c6725877e7fbcd2432b4c692357f16f510.jan-2026.pdf)
covers two reviews — `228b35c6` on the 13th and `26bce619` on the 26th, the
latter being the end of the audited tree. Scope was the twelve contracts listed
in [`audit/audits.json`](audit/audits.json), which were all of `src/` at those
commits.

`src/` today is not that tree: some of the audited files have since been
deleted, and some of what is there now the audit never saw. To see how far it
has moved:

```sh
git diff --stat 26bce6197383f193e35326bab4d4424cf6eafde7..HEAD -- src/
```

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
