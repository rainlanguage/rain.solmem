// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// Thrown if a truncated length is longer than the data being truncated. It is
/// not possible to truncate something and increase its length as the memory
/// region after it MAY be allocated for something else already. Thrown by
/// `LibBytes`, `LibUint256Array` and `LibBytes32Array` alike.
/// @param currentLength The current length of the data.
/// @param truncatedLength The requested, longer, length.
error OutOfBoundsTruncate(uint256 currentLength, uint256 truncatedLength);
