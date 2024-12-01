// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const uxTokenFactoryModule = buildModule("uxTokenFactoryModule", (m) => {
  // Define constructor parameters with default values
  const appName = m.getParameter("appName", "QuantumResistantApp"); // Replace "MyApp" with your default app name
  const allowedTokens = m.getParameter("allowedTokens", [
    "0x80366C8502326eDE6B4DCB46fcE7Cc88378Eda07",
    "0xc6c3131A37398e1FE41047Adb5fAC4DB35d9862F",
    "0xa288F22F28100459C2202Ef6d3ddA6233f5A8621",
  ]); // Replace with actual token addresses
  const whiteListAddresses = m.getParameter("whiteListAddresses", [
    "0x088941f96C77405D946AC8452F56907520fD7Df8",
    "0x319f731efAfab1F5bD5dBb146Bc19836998b3436",
  ]); // Replace with actual whitelisted addresses
  const priceFeedAddress = m.getParameter(
    "priceFeedAddress",
    "0x694AA1769357215DE4FAC081bf1f309aDC325306"
  ); // Replace with actual price feed address

  // Deploy the contract with constructor arguments
  const yourContract = m.contract("uxTokenFactoryContract", [
    appName,
    allowedTokens,
    whiteListAddresses,
    priceFeedAddress,
  ]);

  return { yourContract };
});

export default uxTokenFactoryModule;
