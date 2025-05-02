// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FeeManager {
    AggregatorV3Interface public priceFeed; // Chainlink ETH/USD Price Feed

    // Mapping to store price feed addresses for different tokens
    mapping(address => address) public tokenPriceFeeds;

    // Set to store allowed tokens (both stablecoins and other tokens)
    EnumerableSet.AddressSet private allowedTokens;
}

// Get the latest price of ETH in USD (used to calculate equivalent ETH for stablecoin fee)
function getLatestPrice() public view returns (int) {
    (, int price, , , ) = priceFeed.latestRoundData();
    return price;
}

// Calculate the equivalent ETH for the subscription fee based on the current price
// This is done by scaling the stablecoin fee by the current ETH price
// @param _feeInStableCoin is the fee in stablecoin in wei
function calculateETHFee(uint256 _feeInStableCoin) public view returns (uint) {
    int ethPriceInUSD = getLatestPrice(); // Price of 1 ETH in USD (with 8 decimals)
    require(ethPriceInUSD > 0, "Invalid price from oracle");

    uint ethFee = (_feeInStableCoin * 1e8) / uint(ethPriceInUSD); // Conversion to ETH amount
    return ethFee;
}

function convertEthToUSD(
    uint256 ethAmountInWei
) public view returns (uint256 usdtAmount) {
    int ethPriceInUsdt = getLatestPrice(); // The price of 1 ETH in USDT, scaled by 10^8
    require(ethPriceInUsdt > 0, "Invalid ETH price");

    // Convert wei to ETH
    uint256 ethAmountInEth = ethAmountInWei / 1e18;

    // Calculate the USDT amount (price feed has 8 decimals)
    uint256 usdtAmountInDecimals = ethAmountInEth * uint256(ethPriceInUsdt);

    // Normalize by 1e8 to adjust for price feed decimals
    return (usdtAmountInDecimals / 1e8) * 1e18;
}

// Add allowed token with its price feed
function addAllowedFeeToken(address _token, address _priceFeed) public onlyOwner {
    require(_token != address(0), "Invalid token address");
    require(_priceFeed != address(0), "Invalid price feed address");

    // Check if token is already allowed
    require(!isAllowedToken(_token), "Token already allowed");

    // Add token to allowed tokens set
    allowedTokens.add(_token);

    // Set price feed for the token
    tokenPriceFeeds[_token] = _priceFeed;
}

// Remove allowed token
function removeAllowedFeeToken(address _token) public onlyOwner {
    require(isAllowedToken(_token), "Token not allowed");

    // Remove token from allowed tokens set
    allowedTokens.remove(_token);

    // Remove price feed mapping
    delete tokenPriceFeeds[_token];
}

// Add multiple allowed tokens with their price feeds
function addAllowedFeeTokens(
    address[] calldata _tokens,
    address[] calldata _priceFeeds
) public onlyOwner {
    require(_tokens.length == _priceFeeds.length, "Arrays length mismatch");

    for (uint256 i = 0; i < _tokens.length; i++) {
        require(_tokens[i] != address(0), "Invalid token address");
        require(_priceFeeds[i] != address(0), "Invalid price feed address");
        require(!isAllowedToken(_tokens[i]), "Token already allowed");

        // Add token to allowed tokens set
        allowedTokens.add(_tokens[i]);

        // Set price feed for the token
        tokenPriceFeeds[_tokens[i]] = _priceFeeds[i];
    }
}

// Remove multiple allowed tokens
function removeAllowedFeeTokens(address[] calldata _tokens) public onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
        require(isAllowedToken(_tokens[i]), "Token not allowed");

        // Remove token from allowed tokens set
        allowedTokens.remove(_tokens[i]);

        // Remove price feed mapping
        delete tokenPriceFeeds[_tokens[i]];
    }
}

// Check if a token is allowed
function isAllowedFeeToken(address _token) public view returns (bool) {
    return allowedTokens.contains(_token);
}

// Get the price feed address for a token
function getTokenPriceFeed(address _token) public view returns (address) {
    return tokenPriceFeeds[_token];
}

// Get all allowed tokens
function getAllowedFeeTokens() public view returns (address[] memory) {
    return allowedTokens.values();
}

// Calculate fee in a specific token
function calculateTokenFee(
    uint256 _feeInUSD,
    address _token
) public view returns (uint256) {
    require(isAllowedToken(_token), "Token not allowed");

    // Get price feed for the token
    address priceFeedAddress = tokenPriceFeeds[_token];
    require(priceFeedAddress != address(0), "Price feed not set for token");

    // Get token price in USD
    AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
    (, int price, , , ) = priceFeed.latestRoundData();
    require(price > 0, "Invalid price from oracle");

    // Get token decimals
    uint8 decimals = IERC20Metadata(_token).decimals();

    // Calculate token amount needed
    // _feeInUSD is in 1e18 (USD with 18 decimals)
    // price is in 1e8 (USD with 8 decimals)
    // We need to adjust for both the price feed decimals and token decimals
    uint256 tokenAmount = (_feeInUSD * 1e8) / uint256(price);

    // Adjust for token decimals
    if (decimals < 18) {
        tokenAmount = tokenAmount / (10 ** (18 - decimals));
    } else if (decimals > 18) {
        tokenAmount = tokenAmount * (10 ** (decimals - 18));
    }

    return tokenAmount;
}
