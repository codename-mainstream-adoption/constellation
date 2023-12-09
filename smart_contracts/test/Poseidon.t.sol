// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IPoseidon} from "../src/vendor/PoseidonInterface.sol";
import "../src/vendor/FromHex.sol";


contract PoseidonTest is Test {
    IPoseidon public hasher;

    function setUp() public {
        bytes memory createCode = fromHex(vm.readFile("./poseidon.txt"));
        address poseidonAddr;
        assembly {
            poseidonAddr := create(0, add(createCode, 0x20), mload(createCode))
        }
        hasher = IPoseidon(poseidonAddr);
    }

    function test_poseidonHash() public {
        assertEq(
            hasher.poseidon([uint256(1), 2]),
            0x115cc0f5e7d690413df64c6b9662e9cf2a3617f2743245519e19607a4417189a
        );
    }
}
