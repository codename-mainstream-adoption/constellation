// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {OptimisticVerimedian} from "../src/OptimisticVerimedian.sol";
import "../src/vendor/FromHex.sol";


contract OptimisticVerimedianTest is Test {
    OptimisticVerimedian public optimisticVerimedian;

    function setUp() public {
        bytes memory createCode = fromHex(vm.readFile("./poseidon.txt"));
        address poseidonAddr;
        assembly {
            poseidonAddr := create(0, add(createCode, 0x20), mload(createCode))
        }
        optimisticVerimedian = new OptimisticVerimedian(poseidonAddr);
    }

    function test_keccakHash() public {
        assertEq(
            optimisticVerimedian.keccakHash(1, 2),
            0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0
        );
    }

    function test_keccakHashChain() public {
        uint[77] memory values = [
            uint256(13), 31, 71, 63, 51, 3, 61, 11, 32, 6, 47, 1, 45, 10, 67,
            26, 55, 60, 7, 21, 33, 56, 65, 53, 18, 17, 74, 37, 2, 27, 0, 29, 52,
            73, 76, 35, 28, 48, 46, 14, 64, 9, 44, 39, 54, 68, 25, 69, 12, 40,
            23, 4, 59, 15, 38, 58, 57, 50, 16, 36, 41, 22, 75, 42,  24, 62, 70,
            49, 8, 66, 34, 30, 72, 43, 20, 5, 19
        ];

        assertEq(
            optimisticVerimedian.keccakHashChain(values, 0),
            0x95007ecbac97d7d1410ab8a06a1b2a147c2c75d7e8401e1f0baa096ae7371e0c
        );
    }

    function test_poseidonHash() public {
        assertEq(
            optimisticVerimedian.poseidonHash(1, 2),
            0x115cc0f5e7d690413df64c6b9662e9cf2a3617f2743245519e19607a4417189a
        );
    }

    function test_poseidonHashChain() public {
        uint[77] memory values = [
            uint256(13), 31, 71, 63, 51, 3, 61, 11, 32, 6, 47, 1, 45, 10, 67,
            26, 55, 60, 7, 21, 33, 56, 65, 53, 18, 17, 74, 37, 2, 27, 0, 29, 52,
            73, 76, 35, 28, 48, 46, 14, 64, 9, 44, 39, 54, 68, 25, 69, 12, 40,
            23, 4, 59, 15, 38, 58, 57, 50, 16, 36, 41, 22, 75, 42,  24, 62, 70,
            49, 8, 66, 34, 30, 72, 43, 20, 5, 19
        ];

        assertEq(
            optimisticVerimedian.poseidonHashChain(values, 0),
            0x53e009aea3ff3c3b7d9cfcc6eb53e3eace0a11e4a2bc7938e5ef48075ec86f3
        );
    }

    function test_performUpkeep() public {
        optimisticVerimedian.performUpkeep("");
        assertEq(uint(1), 1);
    }

    function test_medianCheck() public {
        int256[77] memory raw = [
            int256(13), 31, 71, 63, 51,  3, 61, 11, 32,  6, 47,  1, 45, 10, 67,
            26, 55, 60,  7, 21, 33, 56, 65, 53, 18, 17, 74, 37,  2, 27,  0, 29,
            52, 73, 76, 35, 28, 48, 46, 14, 64,  9, 44, 39, 54, 68, 25, 69, 12,
            40, 23, 4, 59, 15, 38, 58, 57, 50, 16, 36, 41, 22, 75, 42, 24, 62,
            70, 49, 8, 66, 34, 30, 72, 43, 20,  5, 19
        ];

        uint N = 11;
        int256[] memory values = new int256[](77 * N);
        for (uint i; i < 77; i++) {
            for (uint j; j<N; j++) {
                values[i+(j*77)] = raw[i];
            }
        }

        int256 m = optimisticVerimedian.medianCheck(values);
        assertEq(m, int256(38));
    }
}
