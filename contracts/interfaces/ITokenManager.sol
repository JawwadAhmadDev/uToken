// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenManager {
    // View functions
    function allAllowedTokens() external view returns (address[] memory);

    function allAllowedTokensCount() external view returns (uint256);

    function allurTokensOfAllowedTokens()
        external
        view
        returns (address[] memory);

    function allurTokensOfAllowedTokensCount() external view returns (uint256);

    function getTokenAddressForurToken(
        address _urToken
    ) external view returns (address);

    function geturTokenAddressForToken(
        address _token
    ) external view returns (address);

    function getCurrencyOfurToken(
        address _urToken
    ) external view returns (string memory);

    function isAllowedToken(address _token) external view returns (bool);

    function isAllowedurToken(address _urToken) external view returns (bool);

    function getAllWhiteListAddresses()
        external
        view
        returns (address[] memory);

    // State changing functions
    function addAllowedTokens(address[] memory _allowedTokens) external;

    function removeAllowedTokens(address[] memory _allowedTokens) external;

    // Events
    event TokenDeployed(address indexed tokenAddress, string name);
    event TokenAdded(
        address indexed tokenAddress,
        address indexed deployedAddress
    );
    event TokenRemoved(address indexed tokenAddress);

    // Errors
    error TokenAlreadyAdded();
    error TokenNotAdded();
    error InvalidToken();
}
