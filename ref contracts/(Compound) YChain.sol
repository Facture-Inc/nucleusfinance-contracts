// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../import contracts/LazerZero/lzApp/NonblockingLzApp.sol";

interface CUSDC {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);
}

interface USDC {
    function increaseAllowance(
        address spender,
        uint256 increment
    ) external returns (bool);
}

contract YChain is Ownable, NonblockingLzApp {
    CUSDC public cusdc;
    USDC public usdc;
    uint256 public data = 0;
    uint16 destChainId;
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        address _cusdc,
        address _usdc,
        address _lzEndpoint
    ) NonblockingLzApp(_lzEndpoint) {
        cusdc = CUSDC(_cusdc);
        usdc = USDC(_usdc);
        if (_lzEndpoint == 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23)
            destChainId = 10106;
    }

    //CUSD - 0x73506770799Eb04befb5AaE4734e58C2C624F493
    //USDC - 0x07865c6E87B9F70255377e024ace6630C1Eaa37F```````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````

    function updateCUSDCadd(address _cusdc) external onlyOwner {
        cusdc = CUSDC(_cusdc);
    }

    function updateUSDCadd(address _usdc) external onlyOwner {
        usdc = USDC(_usdc);
    }

    function myIncreaseAllowance(
        address _spender,
        uint256 _amount
    ) external onlyOwner {
        usdc.increaseAllowance(_spender, _amount);
    }

    //_spender - 0x73506770799Eb04befb5AaE4734e58C2C624F493
    //_amount - 10000000 (10 USDC)

    // function invest(uint256 _mintAmount) external onlyOwner {
    //     cusdc.mint(_mintAmount);
    // }

    function invest() external onlyOwner {
        cusdc.mint(data);
    }

    // function withdraw(uint256 _redeemTokens) external onlyOwner {
    //     cusdc.redeem(_redeemTokens);
    // }

    function withdraw() external onlyOwner {
        cusdc.redeem(data);
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        data = abi.decode(_payload, (uint256));
    }

    function trustAddress(address _otherContract) public onlyOwner {
        trustedRemoteLookup[destChainId] = abi.encodePacked(
            _otherContract,
            address(this)
        );
    }
}
