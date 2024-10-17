// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

library LibMemorySlow {
    function memoryIsAlignedSlow() internal pure returns (bool) {
        uint256 freeMemPtr;
        assembly {
            freeMemPtr := mload(0x40)
        }
        return freeMemPtr % 0x20 == 0;
    }
}
