// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

import {Pointer} from "../lib/LibMemCpy.sol";

/// Throws if a stack pointer is not aligned to 32 bytes.
error UnalignedStackPointer(Pointer pointer);
