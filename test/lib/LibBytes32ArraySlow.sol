// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

library LibBytes32ArraySlow {
    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a) internal pure returns (bytes32[] memory) {
        bytes32[] memory array = new bytes32[](1);
        array[0] = a;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32 b) internal pure returns (bytes32[] memory) {
        bytes32[] memory array = new bytes32[](2);
        array[0] = a;
        array[1] = b;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32 b, bytes32 c) internal pure returns (bytes32[] memory) {
        bytes32[] memory array = new bytes32[](3);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32 b, bytes32 c, bytes32 d) internal pure returns (bytes32[] memory) {
        bytes32[] memory array = new bytes32[](4);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        array[3] = d;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e)
        internal
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory array = new bytes32[](5);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        array[3] = d;
        array[4] = e;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e, bytes32 f)
        internal
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory array = new bytes32[](6);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        array[3] = d;
        array[4] = e;
        array[5] = f;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e, bytes32 f, bytes32 g)
        internal
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory array = new bytes32[](7);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        array[3] = d;
        array[4] = e;
        array[5] = f;
        array[6] = g;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32 b, bytes32 c, bytes32 d, bytes32 e, bytes32 f, bytes32 g, bytes32 h)
        internal
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory array = new bytes32[](8);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        array[3] = d;
        array[4] = e;
        array[5] = f;
        array[6] = g;
        array[7] = h;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32[] memory tail) internal pure returns (bytes32[] memory) {
        bytes32[] memory array = new bytes32[](tail.length + 1);
        array[0] = a;
        for (uint256 i = 0; i < tail.length; i++) {
            array[i + 1] = tail[i];
        }
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(bytes32 a, bytes32 b, bytes32[] memory tail) internal pure returns (bytes32[] memory) {
        bytes32[] memory array = new bytes32[](tail.length + 2);
        array[0] = a;
        array[1] = b;
        for (uint256 i = 0; i < tail.length; i++) {
            array[i + 2] = tail[i];
        }
        return array;
    }

    /// Slow implementation of truncate for testing purposes.
    function truncateSlow(bytes32[] memory a, uint256 newLength) internal pure returns (bytes32[] memory) {
        bytes32[] memory b = new bytes32[](newLength);
        for (uint256 i = 0; i < newLength; i++) {
            b[i] = a[i];
        }
        return b;
    }

    /// Slow implementation of extend for testing purposes.
    function extendSlow(bytes32[] memory a, bytes32[] memory b) internal pure returns (bytes32[] memory) {
        bytes32[] memory c = new bytes32[](a.length + b.length);
        uint256 i = 0;
        for (; i < a.length; i++) {
            c[i] = a[i];
        }
        for (; i < a.length + b.length; i++) {
            c[i] = b[i - a.length];
        }
        return c;
    }

    /// Slow implementation of reverse for testing purposes.
    function reverseSlow(bytes32[] memory a) internal pure returns (bytes32[] memory) {
        bytes32[] memory b = new bytes32[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            b[i] = a[a.length - i - 1];
        }
        return b;
    }
}
