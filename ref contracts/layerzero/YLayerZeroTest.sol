// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/NonblockingLzApp.sol";

contract YLayerZeroTest is NonblockingLzApp {
    uint256[2] public data;
    uint256 public totalVaultAssets;
    bytes public PAYLOAD;
    uint16 internal immutable destChainId = 10106;
    address _lzEndpoint = 0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1;

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

    function updateTotalVaultAssets(uint _val) public {
        totalVaultAssets = _val;
    }

    function updatePayload() public {
        PAYLOAD = abi.encode(data);
    }

    function estimateFee() external view returns (uint256 nativeFee) {
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
        bytes memory payload = abi.encode(totalVaultAssets / 10 ** 12);
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
