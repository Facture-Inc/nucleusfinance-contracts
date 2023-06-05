// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SERC20} from "../imports/SERC20.sol";
import {SafeTransferLib} from "../imports//SafeTransferLib.sol";
import {FixedPointMathLib} from "../imports//FixedPointMathLib.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";

contract XChainTest is SERC20, NonblockingLzApp {
    using SafeTransferLib for SERC20;
    using FixedPointMathLib for uint256;

    bytes public constant PAYLOAD = "test";
    uint16 destChainId;

    /*//////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    SERC20 public immutable asset;
    uint256[2] public data;
    uint256 public actSupply = 0;
    uint256 public supplytoAdd = 0;
    uint256 public supplytoDeduct = 0;
    uint256 public totalVaultAssets = 0;
    uint256 public totalVaultAssetsToDeposit = 0;
    uint256 public totalVaultAssetsToWithdraw = 0;
    mapping(address => uint256) public withdrawlRequests;

    constructor(
        SERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _lzEndpoint
    ) SERC20(_name, _symbol, _asset.decimals()) NonblockingLzApp(_lzEndpoint) {
        asset = _asset;
        if (_lzEndpoint == 0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706)
            destChainId = 10112;
        //Fuji -> Fantom
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets) public virtual returns (uint256 shares) {
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(msg.sender, shares);
        supplytoAdd = supplytoAdd + shares;
        data[0] = data[0] + assets;
    }

    function requestWithdrawal(
        uint256 shares
    ) public virtual returns (uint256 assets) {
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");
        _burn(msg.sender, shares);
        withdrawlRequests[msg.sender] = withdrawlRequests[msg.sender] + assets;
        supplytoDeduct = supplytoDeduct + shares;
        data[1] = data[1] + assets;
    }

    function redeem(uint256 amount) public virtual {
        withdrawlRequests[msg.sender] = withdrawlRequests[msg.sender] - amount;
        asset.safeTransfer(msg.sender, amount);
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
        // uint256 supply = totalSupply;
        uint256 supply = actSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return
            totalAssets() == 0
                ? assets
                : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256) {
        // uint256 supply = totalSupply;
        uint256 supply = actSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(
        uint256 assets
    ) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        // uint256 supply = totalSupply;
        uint256 supply = actSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(
        uint256 assets
    ) public view virtual returns (uint256) {
        // uint256 supply = totalSupply;
        uint256 supply = actSupply; // Saves an extra SLOAD if totalSupply is non-zero.

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
        if (data[0] > data[1]) {
            data[0] = data[0] - data[1];
            data[1] = 0;
        } else if (data[1] > data[0]) {
            data[1] = data[1] - data[0];
            data[0] = 0;
        } else {
            revert();
        }
        bytes memory payload = abi.encode(data);
        _lzSend(
            destChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            bytes(""),
            msg.value
        );
        actSupply = (actSupply + supplytoAdd) - supplytoDeduct;
        supplytoAdd = 0;
        supplytoDeduct = 0;
        data[0] = 0;
        data[1] = 0;
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
