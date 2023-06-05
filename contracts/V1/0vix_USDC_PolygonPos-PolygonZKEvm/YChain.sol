// SPDX-License-Identifier: None
// NewYChain
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";

/*//////////////////////////////////////////////////////////////
                            INTERFACES
//////////////////////////////////////////////////////////////*/

interface vixUSDC {
    function mint(uint mintAmount) external;

    function balanceOf(address account) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function redeemUnderlying(uint redeemAmount) external;
}

interface USDC {
    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

/**
 * @custom:todo update interfaces and their state vars
 * @custom:todo fig out previewRedeemOfContract()
 */
contract YChain0VixUSDC is
    NonblockingLzApp,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Invested(uint256 amount);
    event Withdrawn(uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    vixUSDC public immutable vixUsdc;
    USDC public immutable asset;
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    uint16 internal immutable destChainId = 109;
    uint256[2] public data;
    uint256 public totalVaultAssets;
    address internal immutable swapAdd =
        0x25aB3Efd52e6470681CE037cD546Dc60726948D3;
    address public maintainer;
    address public vault;

    constructor(
        address _asset,
        address _vault
    ) NonblockingLzApp(0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4) {
        asset = USDC(_asset);
        vixUsdc = vixUSDC(_vault);
        vault = _vault;
        maintainer = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTAINER_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error invalidAddress();
    error insufficientAssets();
    error insufficientShares();
    error invalidAccessControl(address _add);

    /*//////////////////////////////////////////////////////////////
                        MODIFIERS AND HELPER FUNCTIONS
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

    function isInvalidAddress(address _address) internal view returns (bool) {
        return _address == address(this) || _address == address(0);
    }

    /*//////////////////////////////////////////////////////////////
                    PAUSABLE AND ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyMaintainer {
        _pause();
    }

    function unpause() external onlyMaintainer {
        _unpause();
    }

    function updateMaintainer(address _addr) external onlyAdmin {
        if ((isInvalidAddress(_addr) == true) || (_addr == maintainer))
            revert invalidAddress();
        if (hasRole(MAINTAINER_ROLE, _addr) == false)
            revert invalidAccessControl(_addr);
        maintainer = _addr;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function invest() public onlyMaintainer nonReentrant whenNotPaused {
        if (asset.balanceOf(address(this)) < data[0])
            revert insufficientAssets();
        uint256 amount = data[0];
        data[0] = 0;
        vixUsdc.mint(amount);
        emit Invested(amount);
    }

    function withdrawfromVault()
        public
        onlyMaintainer
        nonReentrant
        whenNotPaused
    {
        uint256 amount = data[1];
        data[1] = 0;
        vixUsdc.redeemUnderlying(amount);
        emit Withdrawn(amount);
    }

    function previewRedeemOfContract() public view returns (uint256) {
        uint256 balance = vixUsdc.balanceOf(address(this));
        return ((vixUsdc.exchangeRateStored() * balance) / 10 ** 18);
    }

    function assetAllowance() external onlyAdmin {
        asset.approve(swapAdd, 2 ** 256 - 1);
        asset.approve(vault, 2 ** 256 - 1);
    }

    function updateData(uint a, uint b) public onlyAdmin {
        data[0] = a;
        data[1] = b;
    }

    /*//////////////////////////////////////////////////////////////
                            MESSAGE PASSING
    //////////////////////////////////////////////////////////////*/

    function trustAddress(address _otherContract) external onlyAdmin {
        trustedRemoteLookup[destChainId] = abi.encodePacked(
            _otherContract,
            address(this)
        );
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

    function send() external payable onlyMaintainer {
        totalVaultAssets = previewRedeemOfContract();
        bytes memory payload = abi.encode(totalVaultAssets);
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

    /*//////////////////////////////////////////////////////////////
                        CROSSCHAIN TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function isAuthorized(address _addr) external view returns (bool) {
        return maintainer == _addr;
    }
}
