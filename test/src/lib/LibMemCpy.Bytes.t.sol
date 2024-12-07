// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibMemCpy} from "src/lib/LibMemCpy.sol";
import {Pointer, LibBytes} from "src/lib/LibBytes.sol";
import {LibPointer} from "src/lib/LibPointer.sol";

contract LibMemCpyBytesTest is Test {
    using LibPointer for Pointer;
    using LibBytes for bytes;

    function testCopyFuzz(bytes memory source, uint256 suffix) public pure {
        bytes memory target = new bytes(source.length);
        uint256 end;
        assembly {
            end := add(add(target, 0x20), mload(target))
            mstore(0x40, add(end, 0x20))
            mstore(end, suffix)
        }
        LibMemCpy.unsafeCopyBytesTo(source.dataPointer(), target.dataPointer(), source.length);
        assertEq(source, target);
        uint256 suffixAfter;
        assembly {
            suffixAfter := mload(end)
        }
        assertEq(suffix, suffixAfter);
    }

    function testCopyMultiWordFuzz(bytes memory source, uint256 suffix) public pure {
        vm.assume(source.length > 0x20);
        testCopyFuzz(source, suffix);
    }

    function testCopyMaxSuffixFuzz(bytes memory source) public pure {
        testCopyFuzz(source, type(uint256).max);
    }

    function testCopySimple() public pure {
        testCopyFuzz(hex"010203", type(uint256).max);
    }

    // Uses somewhat circular logic to test that existing data in target cannot
    // corrupt copying from source somehow.
    function testCopyDirtyTargetFuzz(bytes memory source, bytes memory target) public pure {
        vm.assume(target.length >= source.length);
        bytes memory remainder = new bytes(target.length - source.length);
        LibMemCpy.unsafeCopyBytesTo(
            target.dataPointer().unsafeAddBytes(source.length), remainder.dataPointer(), remainder.length
        );
        bytes memory remainderCopy = new bytes(remainder.length);
        LibMemCpy.unsafeCopyBytesTo(remainder.dataPointer(), remainderCopy.dataPointer(), remainder.length);

        LibMemCpy.unsafeCopyBytesTo(source.dataPointer(), target.dataPointer(), source.length);
        target.truncate(source.length);
        assertEq(source, target);
        assertEq(remainder, remainderCopy);
    }

    function testCopyGas0() public pure {
        bytes memory a = hex"";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas1() public pure {
        bytes memory a = hex"01";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas2() public pure {
        bytes memory a = hex"0102";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas3() public pure {
        bytes memory a = hex"010203";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas4() public pure {
        bytes memory a = hex"01020304";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas5() public pure {
        bytes memory a = hex"0102030405";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas6() public pure {
        bytes memory a = hex"010203040506";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas7() public pure {
        bytes memory a = hex"01020304050607";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas8() public pure {
        bytes memory a = hex"0102030405060708";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas9() public pure {
        bytes memory a = hex"010203040506070809";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas10() public pure {
        bytes memory a = hex"01020304050607080910";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas11() public pure {
        bytes memory a = hex"0102030405060708091011";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas12() public pure {
        bytes memory a = hex"010203040506070809101112";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas13() public pure {
        bytes memory a = hex"01020304050607080910111213";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas14() public pure {
        bytes memory a = hex"0102030405060708091011121314";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas15() public pure {
        bytes memory a = hex"010203040506070809101112131415";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas16() public pure {
        bytes memory a = hex"01020304050607080910111213141516";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas17() public pure {
        bytes memory a = hex"0102030405060708091011121314151617";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas18() public pure {
        bytes memory a = hex"010203040506070809101112131415161718";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas19() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas20() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas21() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas22() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819202122";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas23() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas24() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021222324";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas25() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819202122232425";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas26() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas27() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021222324252627";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas28() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819202122232425262728";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas29() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526272829";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas30() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021222324252627282930";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas31() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819202122232425262728293031";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas32() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526272829303132";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas33() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021222324252627282930313233";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas34() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819202122232425262728293031323334";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas35() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526272829303132333435";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas36() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021222324252627282930313233343536";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas37() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819202122232425262728293031323334353637";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas38() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526272829303132333435363738";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas39() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021222324252627282930313233343536373839";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas40() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas41() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas42() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021222324252627282930313233343536373839404142";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas43() public pure {
        bytes memory a = hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas44() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas45() public pure {
        bytes memory a = hex"010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas46() public pure {
        bytes memory a =
            hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas47() public pure {
        bytes memory a =
            hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas48() public pure {
        bytes memory a =
            hex"010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas49() public pure {
        bytes memory a =
            hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas50() public pure {
        bytes memory a =
            hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas51() public pure {
        bytes memory a =
            hex"010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas52() public pure {
        bytes memory a =
            hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas53() public pure {
        bytes memory a =
            hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas54() public pure {
        bytes memory a =
            hex"010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas55() public pure {
        bytes memory a =
            hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas56() public pure {
        bytes memory a =
            hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas57() public pure {
        bytes memory a =
            hex"010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas58() public pure {
        bytes memory a =
            hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas59() public pure {
        bytes memory a =
            hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556575859";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas60() public pure {
        bytes memory a =
            hex"010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas61() public pure {
        bytes memory a =
            hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas62() public pure {
        bytes memory a =
            hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556575859606162";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas63() public pure {
        bytes memory a =
            hex"010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas64() public pure {
        bytes memory a =
            hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas128() public pure {
        bytes memory a =
            hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556575859606162636401020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }

    function testCopyGas256() public pure {
        bytes memory a =
            hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263640102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556575859606162636401020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364";
        LibMemCpy.unsafeCopyBytesTo(a.dataPointer(), LibPointer.allocatedMemoryPointer(), a.length);
    }
}
