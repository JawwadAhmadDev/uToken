// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const uxTokenFactoryModule = buildModule("uxTokenFactoryModule", (m) => {
  // Define constructor parameters with default values
  const appName = m.getParameter("appName", "QuantumResistantApp"); // Replace "MyApp" with your default app name
  const allowedTokens = m.getParameter("allowedTokens", []); // Replace with actual token addresses
  const whiteListAddresses = m.getParameter("whiteListAddresses", [
    "0x088941f96C77405D946AC8452F56907520fD7Df8",
    "0xFAfD6C7E1b5017C46d09a2df39D0c7b0F6d83be8",
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
