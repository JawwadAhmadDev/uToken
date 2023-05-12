// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
interface IuTokenForToken {
    event Deposited(address depositor, address token, uint256 amount);
    event Withdrawl(address withdrawer, address token, uint256 amount);

    function initialize(address _currencyToken) external;
    function depositToken(uint256 _amount) external;
    function withdrawToken(uint256 _amount) external;
    function currency() external view returns (string memory);
}
