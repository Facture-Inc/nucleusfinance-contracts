// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../imports/LazerZero/lzApp/NonblockingLzApp.sol";

interface testVault {
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function withdraw(uint256 shares, address owner) external returns (uint256);

    function convertToShares(uint256 assets) external returns (uint256);
}

interface testToken {
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

contract YChainTest is Ownable, NonblockingLzApp {
    testVault public testvault;
    testToken public testtoken;
    uint256[2] public data;
    uint256 public totalVaultAssets = 0;
    uint16 destChainId;
    bytes public constant PAYLOAD = "test";

    constructor(
        address _testtoken,
        address _testvault,
        address _lzEndpoint
    )
        //IERC20 _investmentToken
        NonblockingLzApp(_lzEndpoint)
    {
        testvault = testVault(_testvault);
        testtoken = testToken(_testtoken);
        //investmentToken = _investmentToken;
        if (_lzEndpoint == 0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf)
            destChainId = 10106;
        //Fantom -> Fuji.
    }

    function invest() public {
        testvault.deposit(data[0], address(this));
        data[0] = 0;
    }

    function withdrawfromVault() public {
        uint256 shares = testvault.convertToShares(data[1]);
        testvault.withdraw(shares, address(this));
        data[1] = 0;
    }

    function myincreaseAllowance(address spender, uint256 increment) external {
        testtoken.increaseAllowance(spender, increment);
    }

    function mycheckAllowance() external view returns (uint256) {
        return testtoken.allowance(address(this), address(testvault));
    }

    function updateAssetsToDeposit(uint _num) public {
        data[0] = _num;
    }

    function mybalanceOf() public view virtual returns (uint256) {
        return testvault.balanceOf(address(this));
    }

    function mypreviewRedeem() public view virtual returns (uint256) {
        uint256 balance = mybalanceOf();
        return testvault.previewRedeem(balance);
    }

    function myCustompreviewRedeem(
        uint256 _balance
    ) public view virtual returns (uint256) {
        return testvault.previewRedeem(_balance);
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
        uint16 _dstChainId, // Fuji - 10106
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
        totalVaultAssets = mypreviewRedeem();
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
}
