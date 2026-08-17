// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test, Vm} from "forge-std-1.16.1/src/Test.sol";

/// @title PackageRequirementsTest
/// The published soldeer package is `LICENSE`, `LICENSES/`, `README.md`,
/// `REUSE.toml` and `src/**`. `.soldeerignore` excludes `foundry.toml`, so
/// `README.md` is the only file a consumer receives that can state which
/// compiler and which EVM version these sources require. The requirements the
/// sources actually impose are load bearing: `mcopy` is cancun only, so cancun
/// bytecode deployed to a chain without cancun reverts with `invalid opcode` at
/// runtime rather than failing to build.
///
/// These tests hold the README's statement of the requirements to the config
/// and the sources it describes, so the shipped statement cannot drift away
/// from the shipped code.
contract PackageRequirementsTest is Test {
    /// The README states the `evm_version` the sources are built against.
    function testReadmeStatesTheEvmVersion() external view {
        string memory evmVersion = vm.parseTomlString(vm.readFile("foundry.toml"), ".profile.default.evm_version");
        string memory statement = string.concat("evm_version = \"", evmVersion, "\"");
        assertTrue(
            vm.contains(vm.readFile("README.md"), statement), string.concat("README.md must state `", statement, "`")
        );
    }

    /// Every shipped source declares the same pragma, and the README states it.
    function testReadmeStatesTheSolidityPragma() external view {
        string[] memory sources = sourcePaths();
        assertGt(sources.length, 0, "no sources found under src");

        string memory statement = pragmaOf(sources[0]);
        for (uint256 i = 1; i < sources.length; i++) {
            assertEq(pragmaOf(sources[i]), statement, sources[i]);
        }

        assertTrue(
            vm.contains(vm.readFile("README.md"), statement), string.concat("README.md must state `", statement, "`")
        );
    }

    /// Path of every file under `src`, all of which ship in the package.
    function sourcePaths() internal view returns (string[] memory) {
        Vm.DirEntry[] memory entries = vm.readDir("src", type(uint64).max);
        string[] memory paths = new string[](entries.length);
        uint256 length = 0;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].isDir) {
                continue;
            }
            paths[length] = entries[i].path;
            length++;
        }
        assembly ("memory-safe") {
            mstore(paths, length)
        }
        return paths;
    }

    /// The `pragma solidity ...;` statement declared by the source at `path`.
    function pragmaOf(string memory path) internal view returns (string memory) {
        string[] memory lines = vm.split(vm.readFile(path), "\n");
        for (uint256 i = 0; i < lines.length; i++) {
            if (vm.contains(lines[i], "pragma solidity")) {
                return lines[i];
            }
        }
        revert(string.concat("no pragma declared by ", path));
    }
}
