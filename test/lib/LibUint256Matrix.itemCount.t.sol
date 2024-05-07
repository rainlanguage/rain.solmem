// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibUint256Matrix} from "src/lib/LibUint256Matrix.sol";
import {LibUint256MatrixSlow} from "./LibUint256MatrixSlow.sol";

contract LibUint256MatrixItemCountTest is Test {
    using LibUint256Matrix for uint256[][];
    using LibUint256MatrixSlow for uint256[][];

    function testItemCountReference(uint256[][] memory matrix) external {
        assertEq(matrix.itemCount(), matrix.itemCountSlow());
    }
}
