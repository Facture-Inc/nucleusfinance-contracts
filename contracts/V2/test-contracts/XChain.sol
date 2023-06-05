// SPDX-License-Identifier: GPL 3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";

/**
 * @custom:todo update lz endpoint, destChainId & meson contract add
 * @custom:todo update token name constructor
 * @custom:todo update check decimals
 */
contract XChain is NonblockingLzApp, AccessControl, Pausable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    uint16 public feePercentageBIPS;
    address public maintainer;
    uint16 internal destChainId;
    uint256 public data;

    constructor(
        address _lzEndpoint,
        uint16 _dstChainId,
        address _maintainer
    ) NonblockingLzApp(_lzEndpoint) {
        maintainer = _maintainer;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTAINER_ROLE, _maintainer);
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

    function withdraw() external nonReentrant {
        
        }
}
