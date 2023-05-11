// SPDX-License-Identifier: None
// VP_USDT_Polygon-BSC
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";

/*//////////////////////////////////////////////////////////////
                            INTERFACES
//////////////////////////////////////////////////////////////*/

interface VenusUSDT {
    function mint(uint mintAmount) external returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function exchangeRateStored() external view returns (uint);

    function redeem(uint redeemTokens) external returns (uint);
}

interface USDT {
    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

/**
 * @dev         Venus Protocol USDT [Polygon to BSC]
 * @custom:todo add proper natspec comments for all functions
 * @custom:todo figure out previewRedeem()
 */
contract YChain is NonblockingLzApp, AccessControl, Pausable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Invested(uint256 amount);
    event Withdrawn(uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    VenusUSDT public immutable venusUsdt;
    USDT public immutable asset;
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    uint16 internal immutable destChainId = 109;
    uint256[2] public data;
    uint256 public totalVaultAssets;
    address internal immutable _lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal immutable swapAdd =
        0x25aB3Efd52e6470681CE037cD546Dc60726948D3;
    address internal maintainer;
    address internal vault;

    constructor(
        address _asset,
        address _vault,
        address _maintainer
    ) NonblockingLzApp(_lzEndpoint) {
        asset = USDT(_asset);
        venusUsdt = VenusUSDT(_vault);
        vault = _vault;
        maintainer = _maintainer;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTAINER_ROLE, _maintainer);
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
        venusUsdt.mint(amount);
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
        venusUsdt.redeem(amount);
        emit Withdrawn(amount);
    }

    function previewRedeemOfContract() internal view virtual returns (uint256) {
        uint256 balance = venusUsdt.balanceOf(address(this));
        return (venusUsdt.exchangeRateStored() * balance) / 10 ** 30;
    }

    function assetAllowance() external onlyAdmin {
        asset.approve(swapAdd, 2 ** 256 - 1);
        asset.approve(vault, 2 ** 256 - 1);
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
