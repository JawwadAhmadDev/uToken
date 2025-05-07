// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFeeManager {
    // View functions
    function getLatestPrice() external view returns (int256);

    function quantumActivationFee() external view returns (uint256);

    function percentOfPublicGoodRecipientCandidateAndSocialGoodAddress()
        external
        view
        returns (uint256);

    function protectionFeeInUSD() external view returns (uint256);

    function calculateETHFee(
        uint256 _feeInStableCoin
    ) external view returns (uint256);

    function convertEthToUSD(
        uint256 ethAmountInWei
    ) external view returns (uint256);

    function isAllowedFeeToken(address _token) external view returns (bool);

    function getTokenPriceFeed(address _token) external view returns (address);

    function getAllowedFeeTokens() external view returns (address[] memory);

    function calculateTokenFee(
        uint256 _feeInUSD,
        address _token
    ) external view returns (uint256);

    // State changing functions
    function handleFeeETH(uint256 _depositFee) external;

    function handleFeeToken(
        address _paymentToken,
        uint256 _depositFee
    ) external;

    function addAllowedFeeToken(address _token, address _priceFeed) external;

    function removeAllowedFeeToken(address _token) external;

    function addAllowedFeeTokens(
        address[] calldata _tokens,
        address[] calldata _priceFeeds
    ) external;

    function removeAllowedFeeTokens(address[] calldata _tokens) external;

    function changeProtectionFee(uint256 _feeInUSD) external;

    function changeQuantumActivationFee(uint256 _feeInUSD) external;

    // Events
    event ProtectionFeeChanged(uint256 newFee);
    event QuantumActivationFeeChanged(uint256 newFee);
    event FeeTokenAdded(address token, address priceFeed);
    event FeeTokenRemoved(address token);
}
