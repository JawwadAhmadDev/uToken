// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface IuTokenForEth {
    event DepositedEth(address depositor, uint256 amount);
    event Withdrawl(address withdrawer, uint256 amount);

    function depositEth() external payable;
    function withdrawEth(uint256 _amount) external;
    function currency() external view returns (string memory);
}
