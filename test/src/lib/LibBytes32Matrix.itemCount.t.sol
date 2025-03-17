// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibBytes32Matrix} from "src/lib/LibBytes32Matrix.sol";
import {LibBytes32MatrixSlow} from "test/lib/LibBytes32MatrixSlow.sol";

contract LibBytes32MatrixItemCountTest is Test {
    using LibBytes32Matrix for bytes32[][];
    using LibBytes32MatrixSlow for bytes32[][];

    /// forge-config: default.fuzz.runs = 100
    function testItemCountReference(bytes32[][] memory matrix) external pure {
        assertEq(matrix.itemCount(), matrix.itemCountSlow());
    }
}
