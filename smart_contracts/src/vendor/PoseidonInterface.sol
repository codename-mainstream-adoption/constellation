// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;


interface IPoseidon {
    function poseidon(uint256[2] memory inputs) external pure returns (uint256);
    function poseidon(bytes32[2] memory inputs) external pure returns (bytes32);
}