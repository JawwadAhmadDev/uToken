// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract FeeManager is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    AggregatorV3Interface public priceFeed; // Chainlink ETH/USD Price Feed

    // Mapping to store price feed addresses for different tokens
    mapping(address => address) public tokenPriceFeeds;

    // Set to store allowed tokens (both stablecoins and other tokens)
    EnumerableSet.AddressSet private allowedFeeTokens;

    uint256 public protectionFeeInUSD = 3.69 * 1e18; // 3.69 $
    uint256 public quantumActivationFee = 3.69 * 1e18; // 3.69 $
    uint256 public percentOfPublicGoodRecipientCandidateAndSocialGoodAddress =
        30_000; // 30 * 1000 = 30000% of 0.369% of deposited amount
    uint256 public percentofDevsAddress = 10_000; // 40 * 1000 = 40000% of 0.369% of deposited amount

    address public ur369gift_30 = 0x70C819445c6Bb5a144954818DE138b4A713408dC;
    address public ur369impact_30 = 0x22357B3034DF4a65a00E5887aFB09e94Df17B7B9;
    address public ur369_30 = 0x4eb401801b42139737faC676C5da5e43F6A1A828;
    address public ur369devs_10 = 0xDB0ccF145A929c48277a4431004D633E9D84258a;

    error InvalidTokenAddress();
    error InvalidPrice();
    error InvalidPriceFeed();
    error InvalidAllowedToken();
    error LengthMismatch();
    error AlreadyAdded();
    error InvalidAmount();

    constructor(address _priceFeedAddress) Ownable(msg.sender) {
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

    // Add allowed token with its price feed
    function addAllowedFeeToken(
        address _token,
        address _priceFeed
    ) public onlyOwner {
        if (_token == address(0)) {
            revert InvalidTokenAddress();
        }
        if (_priceFeed == address(0)) {
            revert InvalidPriceFeed();
        }

        // Check if token is already allowed
        if (isAllowedFeeToken(_token)) {
            revert InvalidAllowedToken();
        }

        // Add token to allowed tokens set
        allowedFeeTokens.add(_token);

        // Set price feed for the token
        tokenPriceFeeds[_token] = _priceFeed;
    }

    // Remove allowed token
    function removeAllowedFeeToken(address _token) public onlyOwner {
        if (!isAllowedFeeToken(_token)) {
            revert InvalidAllowedToken();
        }

        // Remove token from allowed tokens set
        allowedFeeTokens.remove(_token);

        // Remove price feed mapping
        delete tokenPriceFeeds[_token];
    }

    // Add multiple allowed tokens with their price feeds
    function addAllowedFeeTokens(
        address[] calldata _tokens,
        address[] calldata _priceFeeds
    ) public onlyOwner {
        if (_tokens.length != _priceFeeds.length) {
            revert LengthMismatch();
        }

        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                revert InvalidTokenAddress();
            }
            if (_priceFeeds[i] == address(0)) {
                revert InvalidPriceFeed();
            }
            if (isAllowedFeeToken(_tokens[i])) {
                revert AlreadyAdded();
            }

            // Add token to allowed tokens set
            allowedFeeTokens.add(_tokens[i]);

            // Set price feed for the token
            tokenPriceFeeds[_tokens[i]] = _priceFeeds[i];
        }
    }

    // Remove multiple allowed tokens
    function removeAllowedFeeTokens(
        address[] calldata _tokens
    ) public onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (!isAllowedFeeToken(_tokens[i])) {
                revert InvalidAllowedToken();
            }

            // Remove token from allowed tokens set
            allowedFeeTokens.remove(_tokens[i]);

            // Remove price feed mapping
            delete tokenPriceFeeds[_tokens[i]];
        }
    }

    // Check if a token is allowed
    function isAllowedFeeToken(address _token) public view returns (bool) {
        return allowedFeeTokens.contains(_token);
    }

    // Get the price feed address for a token
    function getTokenPriceFeed(address _token) public view returns (address) {
        return tokenPriceFeeds[_token];
    }

    // Get all allowed tokens
    function getAllowedFeeTokens() public view returns (address[] memory) {
        return allowedFeeTokens.values();
    }

    // Calculate fee in a specific token
    function calculateTokenFee(
        uint256 _feeInUSD,
        address _token
    ) public view returns (uint256) {
        if (!isAllowedFeeToken(_token)) {
            revert InvalidAllowedToken();
        }

        // Get price feed for the token
        address priceFeedAddress = tokenPriceFeeds[_token];
        if (priceFeedAddress == address(0)) {
            revert InvalidPriceFeed();
        }

        // Get token price in USD
        AggregatorV3Interface _priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int price, , , ) = _priceFeed.latestRoundData();
        if (!(price > 0)) {
            revert InvalidPrice();
        }

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

    function _handleFeeETH(uint256 _depositFee) internal {
        uint256 thirtyPercentShare = (_depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
            100_000;
        uint256 tenPercentShare = (_depositFee * percentofDevsAddress) /
            100_000;

        payable(ur369gift_30).transfer(thirtyPercentShare);
        payable(ur369_30).transfer(thirtyPercentShare);
        payable(ur369impact_30).transfer(thirtyPercentShare);
        payable(ur369devs_10).transfer(tenPercentShare);
    }

    function _handleFeeToken(
        address _paymentToken,
        uint256 _depositFee
    ) internal {
        uint256 thirtyPercentShare = (_depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
            100_000;
        uint256 tenPercentShare = (_depositFee * percentofDevsAddress) /
            100_000;

        IERC20(_paymentToken).transferFrom(
            msg.sender,
            ur369gift_30,
            thirtyPercentShare
        );
        IERC20(_paymentToken).transferFrom(
            msg.sender,
            ur369_30,
            thirtyPercentShare
        );
        IERC20(_paymentToken).transferFrom(
            msg.sender,
            ur369impact_30,
            thirtyPercentShare
        );
        IERC20(_paymentToken).transferFrom(
            msg.sender,
            ur369devs_10,
            tenPercentShare
        );
    }

    function changeProtectionFee(uint256 _feeInUSD) external onlyOwner {
        protectionFeeInUSD = _feeInUSD;
    }

    function changeQuantumActivationFee(uint256 _feeInUSD) external onlyOwner {
        quantumActivationFee = _feeInUSD;
    }
}
