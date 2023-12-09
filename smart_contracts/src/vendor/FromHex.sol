// SPDX-License-Identifier: UNKNOWN
// source: https://ethereum.stackexchange.com/questions/39989/solidity-convert-hex-string-to-bytes
pragma solidity ^0.8.13;

function fromHexChar(uint8 c) pure returns (uint8) {
    if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
        return c - uint8(bytes1('0'));
    }
    if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
        return 10 + c - uint8(bytes1('a'));
    }
    if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
        return 10 + c - uint8(bytes1('A'));
    }
    revert("fail");
}

// Convert an hexadecimal string to raw bytes
function fromHex(string memory s) pure returns (bytes memory) {
    bytes memory ss = bytes(s);
    require(ss.length%2 == 0); // length must be even
    bytes memory r = new bytes(ss.length/2);
    for (uint i=0; i<ss.length/2; ++i) {
        r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                    fromHexChar(uint8(ss[2*i+1])));
    }
    return r;
}