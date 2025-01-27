// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const urTokenFactoryModule = buildModule("urTokenFactoryModule", (m) => {
  // Define constructor parameters with default values
  const appName = m.getParameter("appName", "QuantumResistantApp"); // Replace "MyApp" with your default app name
  const allowedTokens = m.getParameter("allowedTokens", [
    "0x80366C8502326eDE6B4DCB46fcE7Cc88378Eda07",
    "0xc6c3131A37398e1FE41047Adb5fAC4DB35d9862F",
    "0xa288F22F28100459C2202Ef6d3ddA6233f5A8621",
    "0x182272CF384b4BF46efFfdE61c75101664CdEE8A",
  ]); // Replace with actual token addresses
  const whiteListAddresses = m.getParameter("whiteListAddresses", [
    "0xE8c3300B3b4A62e649a7CC3aC313845E3D25A1Af",
    "0x0ad26d5CC37964E6620E090e3293506cF848F41e",
  ]); // Replace with actual whitelisted addresses
  const priceFeedAddress = m.getParameter(
    "priceFeedAddress",
    "0x694AA1769357215DE4FAC081bf1f309aDC325306"
  ); // Replace with actual price feed address

  // Deploy the contract with constructor arguments
  const yourContract = m.contract(
    "urTokenFactoryContract",
    [appName, allowedTokens, whiteListAddresses, priceFeedAddress],
    {
      gasLimit: 6000000000, // Adjust based on estimation
    }
  );

  return { yourContract };
});

export default urTokenFactoryModule;
