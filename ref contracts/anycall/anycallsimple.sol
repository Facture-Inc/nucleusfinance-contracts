// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function context()
        external
        view
        returns (address from, uint256 fromChainID, uint256 nonce);

    function executor() external view returns (address executor);
}

contract Anycalltestboth {
    event NewMsg(string msg);

    // The FTM testnet anycall contract
    address public anycallcontract;

    address public owneraddress;

    address public receivercontract;

    uint public destchain;

    string public test = "hello";

    receive() external payable {}

    fallback() external payable {}

    constructor(address _anycallcontract, uint _destchain) {
        anycallcontract = _anycallcontract;
        owneraddress = msg.sender;
        destchain = _destchain;
    }

    modifier onlyowner() {
        require(msg.sender == owneraddress, "only owner can call this method");
        _;
    }

    function changedestinationcontract(
        address _destcontract
    ) external onlyowner {
        receivercontract = _destcontract;
    }

    function step1_initiateAnyCallSimple_srcfee(
        string calldata _msg
    ) external payable {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress) {
            CallProxy(anycallcontract).anyCall{value: msg.value}(
                receivercontract,
                // sending the encoded bytes of the string msg and decode on the destination chain
                abi.encode(_msg),
                destchain,
                // Using 0 flag to pay fee on the source chain
                0,
                ""
            );
        }
    }

    function updateString(string memory _msg) internal {
        test = _msg;
    }

    // anyExecute has to be role controlled by onlyMPC so it's only called by MPC
    function anyExecute(
        bytes memory _data
    ) external returns (bool success, bytes memory result) {
        string memory _msg = abi.decode(_data, (string));
        emit NewMsg(_msg);
        success = true;
        result = "";
    }
}
