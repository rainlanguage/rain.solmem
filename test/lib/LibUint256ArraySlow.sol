// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

library LibUint256ArraySlow {
    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(uint256 a) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = a;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(uint256 a, uint256 b) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](2);
        array[0] = a;
        array[1] = b;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(uint256 a, uint256 b, uint256 c) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](3);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](4);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        array[3] = d;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](5);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        array[3] = d;
        array[4] = e;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](6);
        array[0] = a;
        array[1] = b;
        array[2] = c;
        array[3] = d;
        array[4] = e;
        array[5] = f;
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f, uint256 g)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](7);
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
    function arrayFromSlow(uint256 a, uint256[] memory tail) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](tail.length + 1);
        array[0] = a;
        for (uint256 i = 0; i < tail.length; i++) {
            array[i + 1] = tail[i];
        }
        return array;
    }

    /// Slow implementation of arrayFrom for testing purposes.
    function arrayFromSlow(uint256 a, uint256 b, uint256[] memory tail) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](tail.length + 2);
        array[0] = a;
        array[1] = b;
        for (uint256 i = 0; i < tail.length; i++) {
            array[i + 2] = tail[i];
        }
        return array;
    }

    /// Slow implementation of truncate for testing purposes.
    function truncateSlow(uint256[] memory a, uint256 newLength) internal pure returns (uint256[] memory) {
        uint256[] memory b = new uint256[](newLength);
        for (uint256 i = 0; i < newLength; i++) {
            b[i] = a[i];
        }
        return b;
    }

    /// Slow implementation of extend for testing purposes.
    function extendSlow(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory) {
        uint256[] memory c = new uint256[](a.length + b.length);
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
    function reverseSlow(uint256[] memory a) internal pure returns (uint256[] memory) {
        uint256[] memory b = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            b[i] = a[a.length - i - 1];
        }
        return b;
    }
}
