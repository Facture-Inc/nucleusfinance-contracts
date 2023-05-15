// SPDX-License-Identifier: None
// PF_USDC_Polygon-Fantom
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";

/*//////////////////////////////////////////////////////////////
                            INTERFACES
//////////////////////////////////////////////////////////////*/

interface PainUSDCCrypt {
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function maxRedeem(address owner) external returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256);
}

interface USDC {
    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

/**
 * @dev         Pain Finance USDC Crypt [Avalanche to Fantom]
 * @custom:todo add proper natspec comments for all functions
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

    PainUSDCCrypt public immutable painUsdcCrypt =
        PainUSDCCrypt(0xd55C59Da5872DE866e39b1e3Af2065330ea8Acd6);
    USDC public immutable asset =
        USDC(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    uint16 internal immutable destChainId = 106;
    uint256[2] public data;
    uint256 public totalVaultAssets;
    address internal immutable swapAdd =
        0x25aB3Efd52e6470681CE037cD546Dc60726948D3;
    address internal maintainer;
    address internal vault;

    constructor() NonblockingLzApp(0x3c2269811836af69497E5F486A85D7316753cf62) {
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

    function invest() internal nonReentrant whenNotPaused {
        if (asset.balanceOf(address(this)) < data[0])
            revert insufficientAssets();
        uint256 amount = data[0];
        data[0] = 0;
        painUsdcCrypt.deposit(amount, address(this));
        emit Invested(amount);
    }

    function withdrawfromVault() internal nonReentrant whenNotPaused {
        if (previewRedeemOfContract() < data[1]) revert insufficientShares();
        uint256 amount = data[1];
        data[1] = 0;
        painUsdcCrypt.withdraw(amount, address(this), address(this));
        emit Withdrawn(amount);
    }

    function previewRedeemOfContract() internal view virtual returns (uint256) {
        uint256 balance = painUsdcCrypt.balanceOf(address(this));
        return painUsdcCrypt.previewRedeem(balance);
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
        if (data[0] != 0) invest();
        else withdrawfromVault();
    }

    /*//////////////////////////////////////////////////////////////
                        CROSSCHAIN TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function isAuthorized(address _addr) external view returns (bool) {
        return maintainer == _addr;
    }
}
