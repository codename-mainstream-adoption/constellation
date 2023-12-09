// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import { AutomationCompatible } from "@chainlink/v0.8/AutomationCompatible.sol";
import { LinkTokenInterface } from "./vendor/LinkTokenInterface.sol";
import { LinkTokenReceiver } from "./vendor/LinkTokenReceiver.sol";
import { OracleRequester } from "./vendor/OracleRequester.sol";
import { Groth16Verifier } from "./vendor/verifier.sol";
import { IPoseidon } from "./vendor/PoseidonInterface.sol";


contract VerimedianSimple is
    AutomationCompatible,
    LinkTokenReceiver,
    OracleRequester
{
    bytes32 constant REQUEST_SPEC_ID = bytes32(
        0x4206900000000000000000000000000000000000000000000000000000000000
    );
    address private s_owner;
    uint256 private s_minPayment;
    mapping (address => bool) private s_provers;

    address private s_linkAddr;
    IPoseidon private s_hasher;
    Groth16Verifier private s_verifier;

    uint256 constant MED_LENGTH = 77;
    uint256 constant SNAPSHOT_INTERVAL = uint256(24 hours) / MED_LENGTH;
    uint256 private s_lastSnapshotTimestamp;

    uint256 constant MAX_VALUE = 7777777 + 1;
    uint256 private s_latestSnapshotIndex;
    mapping (uint256 => uint256) private s_snapshotHashes;
    mapping (uint256 => uint256) private s_snapshotPrices;

    uint256 constant MINIMUM_PRICE = 1; // assuming 1 wei
    uint256 private s_latestPrice;
    uint256 private s_latestSnapshotIndexRequested;

    mapping(uint256 => uint256) private s_requestStatus;

    constructor(address _poseidonAddr, address _linkAddr) {
        uint chainId;
        assembly { chainId := chainid() }
        if (chainId == 11155111) {
            s_hasher = IPoseidon(0x0d0ED917a46Ce705D43CCca104C3e48F26740FB5);
            s_linkAddr = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

        } else if (chainId == 421614) {
            s_hasher = IPoseidon(0x0213d0479816596AefEeb619ECd2d8921c1754c7);
            s_linkAddr = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
        } else {
            s_hasher = IPoseidon(_poseidonAddr);
            s_linkAddr = _linkAddr;
        }

        s_verifier = new Groth16Verifier();
        s_lastSnapshotTimestamp = block.timestamp;
        s_minPayment = 1 ether;
        s_owner = msg.sender;
        s_provers[msg.sender] = true;
    }

    function _payOracle() internal {
        LinkTokenInterface(getChainlinkToken()).transfer(msg.sender, s_minPayment);
    }

    function _poseidonHash(uint256 x, uint256 y) internal view returns (uint256)
    {
        return s_hasher.poseidon([x, y]);
    }

    function _simulatePriceCapture() internal view returns (uint256 simPrice) {
        simPrice = uint256(keccak256(abi.encode(block.number))) % MAX_VALUE;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded =
            (block.timestamp - s_lastSnapshotTimestamp) > SNAPSHOT_INTERVAL;
        performData = "";
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - s_lastSnapshotTimestamp) > SNAPSHOT_INTERVAL) {
            uint256 latestSnapshotIndex = s_latestSnapshotIndex;
            uint256 simPrice = _simulatePriceCapture();
            simPrice = simPrice == 0 ? MINIMUM_PRICE : simPrice;
            uint256 nextSnapshotHash = _poseidonHash(
                s_snapshotHashes[latestSnapshotIndex],
                simPrice
            );

            s_lastSnapshotTimestamp = block.timestamp;
            s_snapshotPrices[latestSnapshotIndex] = simPrice;
            uint256 nextSnapshotIndex = latestSnapshotIndex + 1;
            s_snapshotHashes[nextSnapshotIndex] = nextSnapshotHash;
            s_latestSnapshotIndex = nextSnapshotIndex;
        }

    }

    function requestLatestPrice(address requester, uint256 payment)
        public
        validateFromLINK
    {
        require(payment >= s_minPayment, "Must meet minimum payment");
        require(requester == s_owner, "Must be the owner address");

        uint256 latestSnapshotIndex = s_latestSnapshotIndex;
        require(
            latestSnapshotIndex >= MED_LENGTH,
            "Must have enough observations"
        );
        uint256 requestStatus = s_requestStatus[latestSnapshotIndex];
        require(requestStatus == 0, "Price has already been requested");
        bytes32 requestId = keccak256(abi.encodePacked(latestSnapshotIndex));
        s_requestStatus[latestSnapshotIndex] = uint256(requestId);
        s_latestSnapshotIndexRequested = latestSnapshotIndex;

        emit OracleRequest(
            REQUEST_SPEC_ID, // specId
            requester, // requester
            requestId, // requestId
            s_minPayment, // payment
            address(this), // callbackAddr
            this.submitLatestPrice.selector, // callbackFunctionId
            0, // cancelExpiration (there's no cancel function)
            2, // dataVersion (operator args = 2, but idk what that means)
            abi.encode(latestSnapshotIndex) // data
        );
    }

    function getProofInputs(uint256 _snapshotIndex)
        public
        view
        returns (uint256[MED_LENGTH] memory values, uint256 initialHash)
    {
        bytes32 requestId =
            keccak256(abi.encodePacked(_snapshotIndex));

        require(
            s_requestStatus[_snapshotIndex] == uint256(requestId),
            "Must be pending request"
        );

        uint256 startIndex = _snapshotIndex - MED_LENGTH;
        for (uint i; i < MED_LENGTH; i++) {
            values[i] = s_snapshotPrices[startIndex + i];
        }
        initialHash = s_snapshotHashes[startIndex];
    }

    function submitLatestPrice(
        uint256 _snapshotIndex,
        uint256[2] memory proofA,
        uint256[2][2] memory proofB,
        uint256[2] memory proofC,
        uint256[3] memory publicSignals // valuesHash, initialHash, median
    ) public {
        require(s_provers[msg.sender], "Must be authorized prover");
        bytes32 requestId = keccak256(abi.encodePacked(_snapshotIndex));
        require(
            s_requestStatus[_snapshotIndex] == uint256(requestId) &&
            s_latestSnapshotIndexRequested == _snapshotIndex,
            "Must be a pending request and the latest requested _snapshotIndex"
        );
        require(
            s_snapshotHashes[_snapshotIndex] == publicSignals[0],
            "Must be valid snapshot values"
        );

        try s_verifier.verifyProof(proofA, proofB, proofC, publicSignals)
            returns (bool isValid)
        {
            require(isValid, "Must be valid proof");
            s_latestPrice = publicSignals[2];
            s_requestStatus[_snapshotIndex] = 1;
            _payOracle();
        } catch {
            revert("Invalid proof");
        }
    }

    function _validateTokenTransferAction(
        bytes4 funcSelector,
        bytes memory data
    )
        internal
        pure
        override
    {
        require(
            funcSelector == this.requestLatestPrice.selector,
            "Must use whitelisted functions"
        );
        require(data.length == 68, "Invalid calldata length");
    }

    function setProverStatus(address prover, bool status) public {
        require(msg.sender == s_owner);

        s_provers[prover] = status;
    }

    function getChainlinkToken() public view override returns (address) {
        return s_linkAddr;
    }

    function getMinPayment() public view returns (uint256) {
        return s_minPayment;
    }

    function getSnapshotInterval() public pure returns (uint256) {
        return SNAPSHOT_INTERVAL;
    }

    function getSnapshotPrice(uint256 snapshotIndex)
        public
        view
        returns (uint256)
    {
        return s_snapshotPrices[snapshotIndex];
    }

    function getSnapshotHash(uint256 snapshotIndex)
        public
        view
        returns (uint256)
    {
        return s_snapshotHashes[snapshotIndex];
    }

    function getLatestSnapshotIndex() public view returns (uint256) {
        return s_latestSnapshotIndex;
    }

    function getLatestSnapshotIndexRequested() public view returns (uint256) {
        return s_latestSnapshotIndexRequested;
    }

    function getLatestPrice() public view returns (uint256) {
        return s_latestPrice;
    }
}