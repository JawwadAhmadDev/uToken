// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IFeeManager.sol";

contract FeeManager is IFeeManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    AggregatorV3Interface public priceFeed; // Chainlink ETH/USD Price Feed

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

    function handleFeeETH(uint256 _depositFee) external override {
        _handleFeeETH(_depositFee);
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

    function changeProtectionFee(
        uint256 _feeInUSD
    ) external override onlyOwner {
        protectionFeeInUSD = _feeInUSD;
        emit ProtectionFeeChanged(_feeInUSD);
    }

    function changeQuantumActivationFee(
        uint256 _feeInUSD
    ) external override onlyOwner {
        quantumActivationFee = _feeInUSD;
        emit QuantumActivationFeeChanged(_feeInUSD);
    }
}
