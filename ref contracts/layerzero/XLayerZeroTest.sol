// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract XLayerZeroTest is NonblockingLzApp, AccessControl {
    uint256[2] public data;
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes public PAYLOAD;
    uint16 internal immutable destChainId = 10112;
    address _lzEndpoint = 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8;

    constructor() NonblockingLzApp(_lzEndpoint) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTAINER_ROLE, 0x27F527B6a4E69E9d9CCd4d6DE07E0c81148b36b1);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyMaintainer() {
        require(
            hasRole(MAINTAINER_ROLE, msg.sender),
            "maintainer role required"
        );
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin role required");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            MESSAGE PASSING
    //////////////////////////////////////////////////////////////*/

    function trustAddress(address _otherContract) public onlyOwner {
        trustedRemoteLookup[destChainId] = abi.encodePacked(
            _otherContract,
            address(this)
        );
    }

    function updateArray(uint _num1, uint _num2) public {
        data[0] = _num1;
        data[1] = _num2;
    }

    function updatePayload() public {
        PAYLOAD = abi.encode(data);
    }

    function estimateFee() public view returns (uint256 nativeFee) {
        bytes memory payload = abi.encode(data);
        (nativeFee, ) = lzEndpoint.estimateFees(
            destChainId,
            address(this),
            payload,
            false,
            bytes("")
        );
        return nativeFee;
    }

    function send() public payable {
        bytes memory payload = abi.encode(data);
        _lzSend(
            destChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            bytes(""),
            msg.value
        );
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        data = abi.decode(_payload, (uint256[2]));
    }
}
