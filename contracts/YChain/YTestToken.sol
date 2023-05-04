// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YTestToken is ERC20 {
    constructor() ERC20("TestUSDC", "TUSDC") {
        //decimals is 18 here
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
    
}
