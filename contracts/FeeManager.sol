// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FeeManager {
    AggregatorV3Interface public priceFeed; // Chainlink ETH/USD Price Feed

    error InvalidPrice();
    error InvalidAmount();

    constructor(address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress); // Chainlink ETH/USD price feed
    }

    // Get the latest price of ETH in USD (used to calculate equivalent ETH for stablecoin fee)
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    // Calculate the equivalent ETH for the subscription fee based on the current price
    // This is done by scaling the stablecoin fee by the current ETH price
    // @param _feeInStableCoin is the fee in stablecoin in wei
    function calculateETHFee(
        uint256 _feeInStableCoin
    ) public view returns (uint256) {
        int256 ethPriceInUSD = getLatestPrice();
        if (ethPriceInUSD <= 0) revert InvalidAmount();

        uint256 ethFee = (_feeInStableCoin * 1e8) / uint256(ethPriceInUSD);
        return ethFee;
    }

    function convertEthToUSD(
        uint256 ethAmountInWei
    ) public view returns (uint256 usdtAmount) {
        int ethPriceInUsdt = getLatestPrice(); // The price of 1 ETH in USDT, scaled by 10^8
        if (!(ethPriceInUsdt > 0)) {
            revert InvalidPrice();
        }

        // Convert wei to ETH
        uint256 ethAmountInEth = ethAmountInWei / 1e18;

        // Calculate the USDT amount (price feed has 8 decimals)
        uint256 usdtAmountInDecimals = ethAmountInEth * uint256(ethPriceInUsdt);

        // Normalize by 1e8 to adjust for price feed decimals
        return (usdtAmountInDecimals / 1e8) * 1e18;
    }
}
