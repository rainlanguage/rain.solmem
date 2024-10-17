// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

library LibMemory {
    /// Returns true if the free memory pointer is pointing at a multiple of 32
    /// bytes, false otherwise. Recent versions of Solidity can produce unaligned
    /// memory, which means this test is less useful/neccessary than it used to
    /// be.
    /// @return isAligned true if the memory is currently aligned to 32 bytes.
    function memoryIsAligned() internal pure returns (bool isAligned) {
        assembly ("memory-safe") {
            isAligned := iszero(mod(mload(0x40), 0x20))
        }
    }
}
