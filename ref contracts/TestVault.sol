// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract YTestVault is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public investmentToken;

    constructor(IERC20 investmentToken) ERC20("TestUSDC", "TUSDC") {
        investmentToken = investmentToken;
    }

    function decimals() public view override returns (uint8) {
        return 0;
    }

    function deposit(IERC20 token, uint256 amount) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }
}
