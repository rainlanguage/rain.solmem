// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Pointer} from "../lib/LibPointer.sol";
import {Sentinel} from "../lib/LibStackSentinel.sol";

/// Thrown when the sentinel tuple size is zero.
error ZeroSentinelTupleSize();

/// Thrown when the sentinel cannot be found. This can be because the sentinel
/// was not in the stack, but also if the sentinel is in the stack but not
/// aligned with the tuples size, or if the scan stepped outside the stack
/// bounds and only found a sentinel valued word out there, which is not the
/// caller's sentinel.
/// @param sentinel The sentinel that was not found.
error MissingSentinel(Sentinel sentinel);

/// Thrown when the stack bounds are invalid because the lower is above the
/// upper.
/// @param lower The lower stack pointer.
/// @param upper The upper stack pointer.
error InvalidStackBounds(Pointer lower, Pointer upper);

/// Thrown when the top of the stack is above the allocated memory pointer, so
/// the tuples array cannot be built without overwriting the stack it describes.
/// @param upper The upper stack pointer.
/// @param allocated The allocated memory pointer.
error UnallocatedStack(Pointer upper, Pointer allocated);
