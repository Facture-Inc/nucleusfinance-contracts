// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/NonblockingLzApp.sol";

contract YLayerZeroTest is NonblockingLzApp {
    uint256[2] public data;
    bytes public PAYLOAD;
    uint16 internal immutable destChainId = 10109;
    address _lzEndpoint = 0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf;

    constructor() NonblockingLzApp(_lzEndpoint) {}

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
