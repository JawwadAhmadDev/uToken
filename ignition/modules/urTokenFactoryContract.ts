// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const urTokenFactoryModule = buildModule("urTokenFactoryModule", (m) => {
  // Define constructor parameters with default values
  const appName = m.getParameter("appName", "QuantumResistantApp");
  const allowedTokens = m.getParameter("allowedTokens", [
    "0x80366C8502326eDE6B4DCB46fcE7Cc88378Eda07",
    "0x89b4653F6AAADf86498840d11D05908f0c43ea97",
    "0xE59dc311e56333589137705d91902C336faAe594",
    "0x0E786082fbE524Eb4C9f18A87638FD53Be278519",
    "0xfC147C5B308b716861aDf1348b311ea4bE1f920f",
    "0x1c5f29089E3f6E1f2ab90d710F97E4696a03c0b4",
  ]);
  const whiteListAddresses = m.getParameter("whiteListAddresses", [
    "0x8aEB630F27f9c58B369818f615fB08B175FeB8fa",
    "0x0ad26d5CC37964E6620E090e3293506cF848F41e",
  ]);
  const priceFeedAddress = m.getParameter(
    "priceFeedAddress",
    "0x694AA1769357215DE4FAC081bf1f309aDC325306" // sepolia
  );

  // Deploy TokenManager first
  const tokenManager = m.contract("TokenManager", [
    whiteListAddresses,
    allowedTokens,
  ]);

  // Deploy FeeManager
  const feeManager = m.contract("FeeManager", [priceFeedAddress]);

  // Deploy PeriodManager
  const periodManager = m.contract("PeriodManager", []);

  // Deploy UserManager (which includes PasswordManager)
  const userManager = m.contract("UserManager", [appName]);

  // Deploy PasswordManager
  const passwordManager = m.contract("PasswordManager", [appName]);

  // Finally deploy the main urTokenFactoryContract with all dependencies
  const urTokenFactory = m.contract("urTokenFactoryContract", [
    tokenManager,
    feeManager,
    periodManager,
    userManager,
    passwordManager,
  ]);

  return {
    tokenManager,
    feeManager,
    periodManager,
    userManager,
    passwordManager,
    urTokenFactory,
  };
});

export default urTokenFactoryModule;
