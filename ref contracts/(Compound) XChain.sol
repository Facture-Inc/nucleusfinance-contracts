// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "../import contracts/ERC20.sol";
import {SafeTransferLib} from "../import contracts//SafeTransferLib.sol";
import {FixedPointMathLib} from "../import contracts//FixedPointMathLib.sol";
import "../import contracts/LazerZero/lzApp/NonblockingLzApp.sol";

contract XChain is ERC20, NonblockingLzApp {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    uint256 public data = 0;
    bytes public constant PAYLOAD = "test";
    uint16 destChainId;

    /*//////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;
    uint256 public totalVaultAssets = 0;
    uint256 public totalVaultAssetsToDeposit = 0;
    uint256 public totalVaultAssetsToWithdraw = 0;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _lzEndpoint
    ) ERC20(_name, _symbol, _asset.decimals()) NonblockingLzApp(_lzEndpoint) {
        asset = _asset;
        if (_lzEndpoint == 0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706)
            destChainId = 10112;
        //Fuji -> Fantom
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual returns (uint256 shares) {
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        totalVaultAssetsToDeposit = totalVaultAssetsToDeposit + assets;
    }

    function withdraw(
        uint256 shares,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");
        _burn(owner, shares);
        asset.safeTransfer(owner, assets);
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
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(
        uint256 assets
    ) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(
        uint256 assets
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(
        uint256 shares
    ) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                            LAYER0
    //////////////////////////////////////////////////////////////*/

    function trustAddress(address _otherContract) public onlyOwner {
        trustedRemoteLookup[destChainId] = abi.encodePacked(
            _otherContract,
            address(this)
        );
    }

    function estimateFee(
        uint16 _dstChainId,
        bool _useZro,
        bytes calldata _adapterParams
    ) public view returns (uint nativeFee, uint zroFee) {
        return
            lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                PAYLOAD,
                _useZro,
                _adapterParams
            );
    }

    function send() public payable {
        bytes memory payload = abi.encode(totalVaultAssetsToDeposit);
        _lzSend(
            destChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            bytes(""),
            msg.value
        );
        totalVaultAssetsToDeposit = 0;
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        totalVaultAssets = abi.decode(_payload, (uint256));
    }
}
