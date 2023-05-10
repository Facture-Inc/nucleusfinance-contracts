// SPDX-License-Identifier: None
// VP_USDT_Polygon-BSC
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../imports/SERC20.sol";
import {SafeTransferLib} from "../imports//SafeTransferLib.sol";
import {FixedPointMathLib} from "../imports//FixedPointMathLib.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";

/**
 * @dev         Venus Protocol USDT [Polygon to BSC]
 * @custom:todo add proper natspec comments for all functions
 */
contract XChain is
    SERC20,
    NonblockingLzApp,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    using SafeTransferLib for SERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed sender, uint256 assets, uint256 shares);
    event WithdrawalRequested(
        address indexed sender,
        uint256 shares,
        uint256 assets
    );
    event Redeem(address indexed reciever, uint256 assets);

    /*//////////////////////////////////////////////////////////////
                                INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    uint16 internal immutable destChainId = 102;
    uint16 public feePercentage;
    uint256[2] public data;
    uint256 public actSupply;
    uint256 public totalVaultAssets;
    uint256 internal supplytoAdd;
    uint256 internal supplytoDeduct;
    address internal immutable _lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal immutable swapAdd =
        0x25aB3Efd52e6470681CE037cD546Dc60726948D3;
    address internal devWallet;
    address internal maintainer;
    mapping(address => uint256) public withdrawalRequests;

    constructor(
        ERC20 _asset,
        address _maintainer
    )
        SERC20("NucleusVenusUSDT", "nVenusUSDT", _asset.decimals())
        NonblockingLzApp(_lzEndpoint)
    {
        asset = _asset;
        devWallet = msg.sender;
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
    error insufficientRedeemAmount();
    error invalidPercentage();
    error invalidAccessControl(address _add);
    error ZeroShares();
    error ZeroAssets();

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
                            PAUSABLE
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyMaintainer {
        _pause();
    }

    function unpause() external onlyMaintainer {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isInvalidAddress(address _address) internal view returns (bool) {
        return _address == address(this) || _address == address(0);
    }

    function setVaultFees(uint16 _feePercentage) external onlyAdmin {
        if ((_feePercentage > 100) || (_feePercentage < 0))
            revert invalidPercentage();
        feePercentage = _feePercentage;
    }

    function calculateVaultFees(
        uint256 amount
    ) internal view returns (uint256) {
        return (amount * feePercentage) / 10000;
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function updateDevWallet(address _addr) external onlyAdmin {
        if ((isInvalidAddress(_addr) == true) || (_addr == devWallet))
            revert invalidAddress();
        if (hasRole(DEFAULT_ADMIN_ROLE, _addr) == false)
            revert invalidAccessControl(_addr);
        devWallet = _addr;
    }

    function updateMaintainer(address _addr) external onlyAdmin {
        if ((isInvalidAddress(_addr) == true) || (_addr == maintainer))
            revert invalidAddress();
        if (hasRole(MAINTAINER_ROLE, _addr) == false)
            revert invalidAccessControl(_addr);
        maintainer = _addr;
    }

    function deposit(
        uint256 assets
    ) external virtual whenNotPaused nonReentrant returns (uint256 shares) {
        if (asset.balanceOf(msg.sender) < assets) revert insufficientAssets();
        shares = previewDeposit(assets);
        if (shares <= 0) revert ZeroShares();
        supplytoAdd += shares;
        data[0] += assets;
        asset.transferFrom(msg.sender, address(this), assets);
        _mint(msg.sender, shares);
        emit Deposit(msg.sender, assets, shares);
    }

    function requestWithdrawal(
        uint256 shares
    ) external virtual whenNotPaused nonReentrant returns (uint256 assets) {
        if (balanceOf[msg.sender] < shares) revert insufficientShares();
        assets = previewRedeem(shares);
        if (assets <= 0) revert ZeroAssets();
        withdrawalRequests[msg.sender] += assets;
        supplytoDeduct += shares;
        data[1] += assets;
        _burn(msg.sender, shares);
        emit WithdrawalRequested(msg.sender, shares, assets);
    }

    function redeem(
        uint256 amount
    ) external virtual nonReentrant whenNotPaused {
        if (withdrawalRequests[msg.sender] < amount)
            revert insufficientRedeemAmount();
        uint256 feeAmount = calculateVaultFees(amount);
        withdrawalRequests[msg.sender] -= amount;
        if (feeAmount != 0) {
            asset.transfer(devWallet, feeAmount);
        }
        asset.transfer(msg.sender, amount - feeAmount);
        emit Redeem(msg.sender, amount - feeAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256) {
        return totalVaultAssets;
    }

    function convertToShares(
        uint256 assets
    ) public view virtual returns (uint256) {
        uint256 supply = actSupply;
        if (supply == 0) {
            return assets;
        } else {
            return
                totalAssets() == 0
                    ? assets
                    : assets.mulDivDown(supply, totalAssets());
        }
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256) {
        uint256 supply = actSupply;
        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(
        uint256 assets
    ) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewRedeem(
        uint256 shares
    ) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                            MESSAGE PASSING
    //////////////////////////////////////////////////////////////*/

    function trustAddress(
        address _otherContract
    ) external nonReentrant onlyAdmin {
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

    function send() external payable nonReentrant onlyMaintainer {
        if (data[0] > data[1]) {
            data[0] = (data[0] - data[1]) * 10 ** 12;
            data[1] = 0;
        } else if (data[1] > data[0]) {
            data[1] = (data[1] - data[0]) * 10 ** 12;
            data[0] = 0;
        } else {
            revert("No need to invest");
        }
        bytes memory payload = abi.encode(data);
        actSupply = (actSupply + supplytoAdd) - supplytoDeduct;
        supplytoAdd = 0;
        supplytoDeduct = 0;
        data[0] = 0;
        data[1] = 0;
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
        totalVaultAssets = abi.decode(_payload, (uint256));
    }

    /*//////////////////////////////////////////////////////////////
                        CROSSCHAIN TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function assetAllowance() external onlyAdmin {
        asset.increaseAllowance(swapAdd, 2 ** 256 - 1);
    }

    function isAuthorized(address _addr) external view returns (bool) {
        return maintainer == _addr;
    }
}
