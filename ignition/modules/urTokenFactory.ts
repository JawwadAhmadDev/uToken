// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const urTokenFactoryModule = buildModule("urTokenFactoryModule", (m) => {
  // Define constructor parameters with default values
  const appName = m.getParameter("appName", "QuantumResistantApp"); // Replace "MyApp" with your default app name
  const allowedTokens = m.getParameter("allowedTokens", [
    "0xc6c3131A37398e1FE41047Adb5fAC4DB35d9862F", // GHO
    "0xa288F22F28100459C2202Ef6d3ddA6233f5A8621", // AAVE
    "0x63B19E4180c3c3ae38c8e7112e47C5b690a92f11", // link
    // "0x80366C8502326eDE6B4DCB46fcE7Cc88378Eda07",
    // "0x182272CF384b4BF46efFfdE61c75101664CdEE8A",
    // mainnnet
    // "0x514910771af9ca656af840dff83e8264ecf986ca", // LINK
    // "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984", // UNI
    // "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", // AAVE
    // "0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f", // GHO
    // "0x66a1e37c9b0eaddca17d3662d6c05f4decf3e110", // USR
    // "0x18084fba666a33d37592fa2633fd49a74dd93a88", // tBTC
    // "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", // WBTC
    // "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // cbBTC
    // "0xdac17f958d2ee523a2206206994597c13d831ec7", // USDT,
    // "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // USDC,
    // "0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83", // EIGEN
    // "0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72", // ENS
    // "0xCa14007Eff0dB1f8135f4C25B34De49AB0d42766", // STARKNET
    // "0xdbdb4d16eda451d0503b854cf79d55697f90c8df", // ALCHEMIX
    // "0xae7ab96520de3a18e5e111b5eaab095312d7fe84", // STETH,
    // "0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0", // WSTETH
    // "0xf1C9acDc66974dFB6dEcB12aA385b9cD01190E38", // OsETH,
    // "0xe95a203b1a91a908f9b9ce46459d101078c2c3cb", // AnkrETH
    // "0xA35b1B31Ce002FBF2058D22F30f95D405200A15b", // ETHX
    // "0xD9A442856C234a39a81a089C06451EBAa4306a72", // PUFETH
    // "0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0", // FXS
    // "0xac3E018457B222d93114458476f3E3416Abbe38F", // SFRXETH
    // "0xae78736cd615f374d3085123a210448e74fc6393", // RETH
    // "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce", // SHIB
    // "0x6982508145454ce325ddbe47a25d4ec3d2311933", // PEPE
  ]); // Replace with actual token addresses
  const whiteListAddresses = m.getParameter("whiteListAddresses", [
    "0xe26841f7A8B476A9B3e45bCA7cB40Bb90c2919DE", // URLEGACY
    "0x05b7496528b94eee0dace329d5b7f67ee81bf23b", // URFRACTAL
    // mainnet
    // "0x66a9893cc07d91d95644aedd05d03f95e1dba8af", // UNIVERSAL ROUTER UNISWAP V4
    // "0x222b2a6AC9E10D0090DF08505cDD9ff75c0E4dfA", // urLegacy
    // "0xB928BF5a1D76dCee6994E4f7feb851426A1527C5", // urFractal
  ]); // Replace with actual whitelisted addresses
  const priceFeedAddress = m.getParameter(
    "priceFeedAddress",
    "0x694AA1769357215DE4FAC081bf1f309aDC325306" // sepolia
    // "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419" // mainnet
  ); // Replace with actual price feed address

  // Deploy the contract with constructor arguments
  const yourContract = m.contract(
    "urTokenFactoryContract",
    [
      appName,
      allowedTokens,
      whiteListAddresses,
      "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    ]
    // {
    //   gasLimit: 6000000000, // Adjust based on estimation
    // }
  );

  return { yourContract };
});

export default urTokenFactoryModule;
