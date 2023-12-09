// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Groth16Verifier} from "../src/vendor/verifier.sol";


contract VerimedianTest is Test {
    Groth16Verifier public verifier;

    function setUp() public {
        verifier = new Groth16Verifier();
    }

    function test_verifyProof() public {
        bool isValid = verifier.verifyProof(
            [
                0x16caf0fdd2a35aa5323fe97efccc6f9d76acc3983fffca6d21c5f466f89cb8dc,
                0x14de5a9f321bb9ef519a6f478362231a6d25ea23eac826fafed594c225e52c40
            ],
            [
                [
                    0x145ddc6f6f2be5291e04159b7447b5c9beffce32b9dbe108a81770a88d230c70,
                    0x1c9edbc205043ee23beea0f51d1db383fa82ab5c1475d731fb4b7486ccd8cbb0
                ],
                [
                    0x11241a009555d43e42589a4c7d613df8276347542856663cc9b743df8ce4f7c6,
                    0x010a3447108d86248405707ba5b9b18d776035469379c6ed1522bd3045132f1d
                ]
            ],
            [
                0x216af7389620d2583d2370dc69acaa82aca1ae644ccea35cbe8b3a05a30ee68a,
                0x242284823ee57d22b9ca42a372608948e9f52a067293abc38bd4cc8d55f911a7
            ],
            [
                0x01249e1bf9bf0e74b4cd8bd0a608ea55876e997f71e6a85b137a1a6c83b4a86b,
                0,
                38
            ]
        );
        assertEq(isValid, true);
    }
}
