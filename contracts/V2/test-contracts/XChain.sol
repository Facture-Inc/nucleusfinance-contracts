// SPDX-License-Identifier: GPL 3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @custom:todo write comments.
 */
contract XChain is NonblockingLzApp, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                                INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    uint16 public feePercentageBIPS;
    uint256 internal feesCollected;
    address public maintainer;
    uint16 internal destChainId;
    uint256 public data;

    constructor(
        address _lzEndpoint,
        uint16 _dstChainId,
        address _maintainer
    ) NonblockingLzApp(_lzEndpoint) {
        maintainer = _maintainer;
        destChainId = _dstChainId;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTAINER_ROLE, _maintainer);
    }

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error invalidAddress();
    error invalidAccessControl(address _add);
    error invalidBIPS();
    error invalidAmount();

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

    function setVaultFees(uint16 _feePercentageInBIPS) external onlyAdmin {
        if ((_feePercentageInBIPS > 100) || (_feePercentageInBIPS < 0))
            revert invalidBIPS();
        feePercentageBIPS = _feePercentageInBIPS;
    }

    function calculateVaultFees(uint256 amount) public view returns (uint256) {
        return (amount * feePercentageBIPS) / 10000;
    }

    function withdrawFee(address _token) external onlyMaintainer {
        if (isInvalidAddress(_token)) revert invalidAddress();
        uint256 fees = feesCollected;
        feesCollected = 0;
        IERC20(_token).safeTransfer(msg.sender, fees);
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

    function sendMessage() external payable nonReentrant onlyMaintainer {
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
        // update mapping of money to be redeemed
    }

    /*//////////////////////////////////////////////////////////////
                                MESON
    //////////////////////////////////////////////////////////////*/

    function isAuthorized(address _addr) external view returns (bool) {
        return maintainer == _addr;
    }

    /*//////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function withdraw(address _token, uint256 _amount) external nonReentrant {
        if (isInvalidAddress(_token)) revert invalidAddress();
        if (_amount <= 0) revert invalidAmount();
        uint256 fees = calculateVaultFees(_amount);
        IERC20(_token).safeTransfer(msg.sender, _amount - fees);
    }
}
