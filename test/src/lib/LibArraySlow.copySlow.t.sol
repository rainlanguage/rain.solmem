// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibUint256ArraySlow} from "../../lib/LibUint256ArraySlow.sol";
import {LibBytes32ArraySlow} from "../../lib/LibBytes32ArraySlow.sol";

/// `copySlow` snapshots an input before it is handed to an implementation under
/// test, so the differential tests can build their expected values from memory
/// that implementation cannot reach. A snapshot that aliased its input would
/// hand the implementation's own scribbles back to the reference implementation
/// and cancel them out of every comparison, so the copy owning its own memory is
/// the property the differential tests rest on.
contract LibArraySlowCopySlowTest is Test {
    using LibUint256ArraySlow for uint256[];
    using LibBytes32ArraySlow for bytes32[];

    function testCopySlowUint256OwnsItsMemory(uint256[] memory a) external pure {
        uint256[] memory b = a.copySlow();

        assertEq(b, a, "copy contents");

        if (a.length > 0) {
            uint256 original = a[0];
            b[0] = ~original;
            assertEq(a[0], original, "writing the copy must not write the original");
        }
    }

    function testCopySlowBytes32OwnsItsMemory(bytes32[] memory a) external pure {
        bytes32[] memory b = a.copySlow();

        assertEq(b, a, "copy contents");

        if (a.length > 0) {
            bytes32 original = a[0];
            b[0] = ~original;
            assertEq(a[0], original, "writing the copy must not write the original");
        }
    }
}
