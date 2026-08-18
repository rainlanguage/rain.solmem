// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {OutOfBoundsTruncate} from "src/error/ErrTruncate.sol";
import {LibBytes} from "src/lib/LibBytes.sol";
import {LibBytes32Array} from "src/lib/LibBytes32Array.sol";
import {LibUint256Array} from "src/lib/LibUint256Array.sol";

contract ErrTruncateTest is Test {
    function truncateBytesExternal(uint256 length, uint256 truncatedLength) external pure {
        LibBytes.truncate(new bytes(length), truncatedLength);
    }

    function truncateUint256ArrayExternal(uint256 length, uint256 truncatedLength) external pure {
        LibUint256Array.truncate(new uint256[](length), truncatedLength);
    }

    function truncateBytes32ArrayExternal(uint256 length, uint256 truncatedLength) external pure {
        LibBytes32Array.truncate(new bytes32[](length), truncatedLength);
    }

    /// `bytes`, `uint256[]` and `bytes32[]` all report an over long truncation
    /// with byte identical revert data, so one selector and one parameter order
    /// covers every truncation in the library.
    function testEveryTruncationRevertsIdentically(uint8 length, uint8 excess) public view {
        uint256 truncatedLength = uint256(length) + uint256(excess) + 1;
        bytes memory expected = abi.encodeWithSelector(OutOfBoundsTruncate.selector, length, truncatedLength);

        (bool bytesSuccess, bytes memory bytesData) =
            address(this).staticcall(abi.encodeCall(this.truncateBytesExternal, (length, truncatedLength)));
        (bool uint256ArraySuccess, bytes memory uint256ArrayData) =
            address(this).staticcall(abi.encodeCall(this.truncateUint256ArrayExternal, (length, truncatedLength)));
        (bool bytes32ArraySuccess, bytes memory bytes32ArrayData) =
            address(this).staticcall(abi.encodeCall(this.truncateBytes32ArrayExternal, (length, truncatedLength)));

        assertFalse(bytesSuccess, "bytes");
        assertFalse(uint256ArraySuccess, "uint256[]");
        assertFalse(bytes32ArraySuccess, "bytes32[]");

        assertEq(bytesData, expected, "bytes revert data");
        assertEq(uint256ArrayData, expected, "uint256[] revert data");
        assertEq(bytes32ArrayData, expected, "bytes32[] revert data");
    }
}
