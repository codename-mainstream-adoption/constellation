// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import { AutomationCompatible } from "@chainlink/v0.8/AutomationCompatible.sol";
import { LinkTokenReceiver } from "./vendor/LinkTokenReceiver.sol";
import { Chainlink } from "./vendor/Chainlink.sol";
import { OracleRequester } from "./vendor/OracleRequester.sol";
import { Groth16Verifier } from "./vendor/verifier.sol";
import { IPoseidon } from "./vendor/PoseidonInterface.sol";
import { Median } from "./vendor/Median.sol";


contract OptimisticVerimedian is
    AutomationCompatible,
    LinkTokenReceiver,
    OracleRequester
{
    /**
     * Chainlink / Optimistic Prover settings. This is a proof of concept, so
     * none of the parameters are optimized, secure, or production ready.
     */
    using Chainlink for Chainlink.Request;
    address constant LINK_ADDR = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    uint256 public minPayment;
    uint256 public minStake;

    uint256 public fraudProofWindow;
    uint256 public lastProofTimestamp;
    uint256 public currentMedianIndex;
    uint256 public pendingMedianIndex;

    mapping (uint256 => uint256) public medians;
    mapping (uint256 => bytes32) public proofHashes;
    mapping (uint256 => uint256) public proofTimestamps;
    mapping (address => bool) public provers;

    /**
     * External contracts.
     */
    IPoseidon public hasher;
    Groth16Verifier public verifier;

    /**
     * Automation settings.
     * Use an INTERVAL in seconds and a timestamp to slow execution of Upkeep.
     * INTERVAL is such that it is called roughly 77 times a day.
     */
    uint256 constant INTERVAL = uint256(24 hours) / uint256(77);
    uint256 public lastSnapshotTimestamp;

    /**
     * Snapshot settings.
     * Asset prices should be less than base field size P, but here make it
     * smaller so the values are easier to read.
     */
    uint256 constant MAX_VALUE = 7777777 + 1;
    uint256 constant MAX_HISTORY_LENGTH = 77 * 7; // 1 week
    uint256 public currentHashIndex;
    mapping (uint256 => uint256) public snapshotHashes;
    mapping (uint256 => uint256) public snapshotPrices;

    constructor(address _poseidonAddr) {
        uint chainId;
        assembly { chainId := chainid() }
        if (chainId == 11155111) {
            hasher = IPoseidon(0x0d0ED917a46Ce705D43CCca104C3e48F26740FB5);
        } else {
            hasher = IPoseidon(_poseidonAddr);
        }

        // External contract so we can use try/catch
        verifier = new Groth16Verifier();
        lastSnapshotTimestamp = block.timestamp;
    }

    /**
     * Keccak hash function with two inputs.
     */
    function keccakHash(uint256 x, uint256 y) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(x, y)));
    }

    /**
     * Keccak hash 77 values in a row. The reason to prefer this over using a
     * merkle tree is so that it can be integrated into a data source.
     */
    function keccakHashChain(uint256[77] memory values, uint256 initialHash)
        public
        pure
        returns (uint256)
    {
        for (uint i; i < 77; i++) {
            initialHash = keccakHash(initialHash, values[i]);
        }
        return initialHash;
    }

    /**
     * Poseidon hash function with two inputs.
     */
    function poseidonHash(uint256 x, uint256 y) public view returns (uint256) {
        return hasher.poseidon([x, y]);
    }

    /**
     * Poseidon hash 77 values in a row. Only used in a fraud proof.
     */
    function poseidonHashChain(uint256[77] memory values, uint256 initialHash)
        public
        view
        returns (uint256)
    {
        for (uint i; i < 77; i++) {
            initialHash = poseidonHash(initialHash, values[i]);
        }
        return initialHash;
    }

    /**
     * The upkeep is eligible for automation 77 times per day.
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastSnapshotTimestamp) > INTERVAL;
        return (upkeepNeeded, "");
    }

    /**
     * Hash the price and update the index of the history.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastSnapshotTimestamp) > INTERVAL) {
            lastSnapshotTimestamp = block.timestamp;
        }
        ( uint256 simPrice,
          uint256 currentIndex,
          uint256 nextHash,
          uint256 nextIndex
        ) = _simulatePriceCapture();
        snapshotHashes[currentIndex] = nextHash;
        snapshotPrices[currentIndex] = simPrice;
        currentHashIndex = nextIndex;
    }

    function _simulatePriceCapture()
        internal
        view
        returns (
            uint256 simPrice,
            uint256 currentIndex,
            uint256 nextHash,
            uint256 nextIndex
        )
    {
        simPrice = uint256(blockhash(block.number)) % MAX_VALUE;
        currentIndex = currentHashIndex;
        nextHash = keccakHash(snapshotHashes[currentIndex], simPrice);
        nextIndex = currentIndex + 1;
        // nextIndex = (currentIndex + 1) % MAX_HISTORY_LENGTH;
    }

    function requestProof(address requester, uint256 payment)
        public
        validateFromLINK
    {
        require(payment >= minPayment, "Must pay enough LINK");
    }

    function commitProof(
        address prover,
        uint256 stake,
        uint256 proofIndex,
        uint256 snapshotStartIndex,
        uint256[2] memory proofA,
        uint256[2][2] memory proofB,
        uint256[2] memory proofC,
        uint256[3] memory publicSignals // valuesHash, initialHash, median
    ) public validateFromLINK {
        require(provers[prover], "Must be authorized prover");
        require(stake >= minStake, "Must stake enough LINK");
        require(proofHashes[proofIndex] == bytes32(0), "Must be a new proof");
        uint256 snapshotStartHash = snapshotHashes[snapshotStartIndex];
        require(snapshotStartHash != 0, "Must be recorded price interval");
        uint256 snapshotEndHash = snapshotHashes[snapshotStartIndex+77];
        require(snapshotEndHash != 0, "Must be recorded price interval");


        bytes32 proofHash = keccak256(abi.encodePacked(
            prover,
            stake,
            proofIndex,
            snapshotStartIndex,
            proofA,
            proofB,
            proofC,
            publicSignals
        ));

        uint256 median = publicSignals[2];
        proofHashes[proofIndex] = proofHash;
    }

    function fraudProof(
        address prover,
        uint256 stake,
        uint256 proofIndex,
        uint256[2] memory proofA,
        uint256[2][2] memory proofB,
        uint256[2] memory proofC,
        uint256[3] memory publicSignals
    ) public {
        bytes32 proofHash = keccak256(abi.encodePacked(
            prover,
            stake,
            proofIndex,
            proofA,
            proofB,
            proofC,
            publicSignals
        ));
        require(
            proofHash == proofHashes[proofIndex],
            "Must be a pending proof!"
        );


        bool isFraudOrFails = false;
        try verifier.verifyProof(
            proofA, proofB, proofC, publicSignals
        ) returns (bool isValid) {
            if (!isValid) {
                isFraudOrFails = true;
            }
        } catch {
            isFraudOrFails = true;
        }

        if (isFraudOrFails) {

        }
    }

    function medianCheck(int256[] memory values) public pure returns (int256) {
        return Median.calculate(values);
    }

    function _validateTokenTransferAction(
        bytes4 funcSelector,
        bytes memory data
    )
        internal
        pure
        override
    {
        if (funcSelector == this.commitProof.selector) {
            // validate calldata for commitProof function
            require(data.length == 57, "Invalid calldata length");

        } else if (funcSelector == this.requestProof.selector) {
            // validate calldata for requestProof function
            require(data.length == 48, "Invalid calldata length");

        } else {
            revert("Must use whitelisted functions");
        }
    }

    function getChainlinkToken() public pure override returns (address) {
        return LINK_ADDR;
    }
}
