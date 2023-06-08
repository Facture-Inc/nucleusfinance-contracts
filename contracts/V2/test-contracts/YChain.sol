// SPDX-License-Identifier: GPL 3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../imports/SERC20.sol";
import {SafeTransferLib} from "../imports//SafeTransferLib.sol";
import {FixedPointMathLib} from "../imports//FixedPointMathLib.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";

contract YChain is
    SERC20,
    NonblockingLzApp,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    using SafeTransferLib for SERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    uint16 internal immutable destChainId;
    uint256 public withdrawalRequests;
    uint256 public totalVaultAssets;
    address internal immutable mesonSwapContract;
    address public maintainer;

    constructor(
        ERC20 _asset,
        address _maintainer,
        address _lzEndpoint,
        uint16 _dstChainId,
        address _mesonSwapContract,
        string memory _name,
        string memory _symbol
    ) SERC20(_name, _symbol, _asset.decimals()) NonblockingLzApp(_lzEndpoint) {
        asset = _asset;
        maintainer = _maintainer;
        destChainId = _dstChainId;
        mesonSwapContract = _mesonSwapContract;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTAINER_ROLE, _maintainer);
    }

    /*//////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS AND MODIFIERS
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

    function pause() external onlyMaintainer {
        _pause();
    }

    function unpause() external onlyMaintainer {
        _unpause();
    }

    function isInvalidAddress(address _address) internal view returns (bool) {
        return _address == address(this) || _address == address(0);
    }

    /*//////////////////////////////////////////////////////////////
                            LAYER ZERO
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
        bytes memory payload = abi.encode(withdrawalRequests);
        (nativeFee, ) = lzEndpoint.estimateFees(
            destChainId,
            address(this),
            payload,
            false,
            bytes("")
        );
        return nativeFee;
    }

    function sendMessage() external payable nonReentrant onlyMaintainer {
        bytes memory payload = abi.encode(withdrawalRequests);
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
        // update mapping of money to be redeemed
    }

    /*//////////////////////////////////////////////////////////////
                                MESON
    //////////////////////////////////////////////////////////////*/

    function isAuthorized(address _addr) external view returns (bool) {
        return maintainer == _addr;
    }
}
