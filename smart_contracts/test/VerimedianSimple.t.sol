// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {VerimedianSimple} from "../src/VerimedianSimple.sol";
import {LinkTokenInterface} from "../src/vendor/LinkTokenInterface.sol";
import "../src/vendor/FromHex.sol";


contract VerimedianSimpleTest is Test {
    VerimedianSimple public verimedian;
    LinkTokenInterface public linkToken;

    function setUp() public {
        bytes memory createCode = fromHex(vm.readFile("./poseidon.txt"));
        address poseidonAddr;
        assembly {
            poseidonAddr := create(0, add(createCode, 0x20), mload(createCode))
        }

        // Deploy
        bytes memory bytecode =
            abi.encodePacked(vm.getCode("LinkToken.sol:LinkToken"));
        address linkTokenAddr;
        assembly {
            linkTokenAddr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        linkToken = LinkTokenInterface(linkTokenAddr);

        verimedian = new VerimedianSimple(poseidonAddr, linkTokenAddr);
    }

    function test_checkUpkeep() public {
        (bool upkeepNeeded, ) = verimedian.checkUpkeep("");
        assertEq(upkeepNeeded, false);

        uint256 interval = verimedian.getSnapshotInterval() + 1;
        vm.warp(block.timestamp + interval);

        (upkeepNeeded, ) = verimedian.checkUpkeep("");
        assertEq(upkeepNeeded, true);
    }

    function test_performUpkeep() public {
        uint256 interval = verimedian.getSnapshotInterval() + 1;
        vm.warp(block.timestamp + interval);

        (bool upkeepNeeded, ) = verimedian.checkUpkeep("");
        assertEq(upkeepNeeded, true);

        verimedian.performUpkeep("");
        uint256 latestSnapshotIndex = verimedian.getLatestSnapshotIndex();
        assertEq(latestSnapshotIndex, 1);
    }

    function test_requestLatestPrice() public {
        uint256 interval = verimedian.getSnapshotInterval() + 1;
        uint256 minPayment = verimedian.getMinPayment();
        bool upkeepNeeded;
        uint256 latestSnapshotIndex;

        for (uint i; i < 77; i++) {
            vm.warp(block.timestamp + interval);
            vm.roll(i);
            (upkeepNeeded, ) = verimedian.checkUpkeep("");
            assertEq(upkeepNeeded, true);
            verimedian.performUpkeep("");
            latestSnapshotIndex = verimedian.getLatestSnapshotIndex();
            assertEq(latestSnapshotIndex, i+1);
        }

        bytes memory data = abi.encodePacked(
            bytes4(VerimedianSimple.requestLatestPrice.selector),
            uint256(uint160(address(msg.sender))),
            uint256(minPayment)
        );

        linkToken.transferAndCall(
            address(verimedian),
            minPayment,
            data
        );

        assertEq(verimedian.getLatestSnapshotIndexRequested(), 77);

        // use this to get the deterministic proof inputs, check logs by running
        // forge test -vvvv --mc=VerimedianSimpleTest
        // (uint256[77] memory prices, uint256 initialHash) =
        //     verimedian.getProofInputs(77);
    }

    function test_submitLatestPrice() public {
        uint256 interval = verimedian.getSnapshotInterval() + 1;
        uint256 minPayment = verimedian.getMinPayment();
        bool upkeepNeeded;
        uint256 latestSnapshotIndex;

        for (uint i; i < 77; i++) {
            vm.warp(block.timestamp + interval);
            vm.roll(i);
            (upkeepNeeded, ) = verimedian.checkUpkeep("");
            assertEq(upkeepNeeded, true);
            verimedian.performUpkeep("");
            latestSnapshotIndex = verimedian.getLatestSnapshotIndex();
            assertEq(latestSnapshotIndex, i+1);
        }

        bytes memory data = abi.encodePacked(
            bytes4(VerimedianSimple.requestLatestPrice.selector),
            uint256(uint160(address(msg.sender))),
            uint256(minPayment)
        );
        linkToken.transferAndCall(
            address(verimedian),
            minPayment,
            data
        );

        uint256 snapshotIndex = verimedian.getLatestSnapshotIndexRequested();
        assertEq(snapshotIndex, 77);

        uint256[2] memory proofA = [
            4174162107883575970410079739563669645446278399503360966215399474756952392201,
            7444771750079423183739538625402560363979395336362259091382419557618314996592
        ];
        uint256[2][2] memory proofB = [
            [
                869262919905829444177961697231447018351201317951872230853283934089297136372,
                10561973251733966214073096206546493659625914219050607434358725178340580240887
            ],
            [
                19533008428324355404142407174665137742201474371807882291658326361224340048597,
                8895788867333528407846294582561934049615347800322827813015370799375307572768
            ]
        ];
        uint256[2] memory proofC = [
            5699258633407461467024740921200482458240178067896270621247428027490814616666,
            9306147052854605504641345039927073803748139647392050854437199742654739695927
        ];
        uint256[3] memory publicSignals = [
            2336069315791744707648359148690690131406345309922973585855015996943626054333,
            0,
            2932010
        ];

        address prover = address(0x420);
        uint256 balanceBefore = linkToken.balanceOf(prover);
        assertEq(balanceBefore, 0);

        verimedian.setProverStatus(prover, true);
        vm.startPrank(prover, prover);
        verimedian.submitLatestPrice(
            snapshotIndex,
            proofA,
            proofB,
            proofC,
            publicSignals
        );
        vm.stopPrank();

        uint256 balanceAfter = linkToken.balanceOf(prover);
        assertEq(balanceAfter, minPayment);

        uint256 latestPrice = verimedian.getLatestPrice();
        assertEq(latestPrice, 2932010);

    }
}
