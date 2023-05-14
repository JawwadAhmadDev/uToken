// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("MyToken", "MTN") {
        _mint(msg.sender, 100000 * 10 ** 18);
    }

}