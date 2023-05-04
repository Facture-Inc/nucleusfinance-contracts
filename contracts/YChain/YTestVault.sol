// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {SERC20} from "../imports/SERC20.sol";
import {SafeTransferLib} from "../imports//SafeTransferLib.sol";
import {FixedPointMathLib} from "../imports//FixedPointMathLib.sol";

contract YTestVault is SERC20 {
    using SafeTransferLib for SERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    SERC20 public immutable asset;
    uint256 public totalVaultAssets = 0;

    constructor(
        SERC20 _asset,
        string memory _name,
        string memory _symbol
    ) SERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
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
        totalVaultAssets = totalVaultAssets + assets;
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
        totalVaultAssets = totalVaultAssets - assets;
    }

    function addrewards(uint256 assets) public virtual {
        asset.safeTransferFrom(msg.sender, address(this), assets);
        totalVaultAssets = totalVaultAssets + assets;
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
}
