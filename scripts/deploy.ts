import { ethers } from "hardhat";

async function main() {
  console.log("Deploying contract...");

  // Replace 'YourContract' with your actual contract name
  const Contract = await ethers.getContractFactory("urTokenFactoryContract");

  // Example: Pass multiple constructor arguments
  //   const arg1 = [
  //     "0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f",
  //     "0x6B175474E89094C44Da98b954EedeAC495271d0F",
  //     "0xdAC17F958D2ee523a2206206994597C13D831ec7",
  //     "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  //   ];
  const arg1 = "QuantumResistantApp";

  const arg3 = [
    "0x66a9893cc07d91d95644aedd05d03f95e1dba8af", // UNIVERSAL ROUTER UNISWAP V4
    "0xB09c706356c60eBDc3a09d20C74dFa6135e54693", // urLegacy
    "0x661aE8Ab07242BeDcd19C8c189287EBEb96093C4",
  ];
  const arg4 = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";

  // Deploy contract with constructor arguments
  const contract = await Contract.deploy(arg1, [], arg3, arg4, {
    gasLimit: 8000000, // Adjust this value as needed
  });

  await contract.waitForDeployment();

  console.log("Contract deployed at:", await contract.getAddress());

  // Verify the contract
  //   console.log("Verifying contract...");
  //   await hre.run("verify:verify", {
  //     address: await contract.getAddress(),
  //     constructorArguments: [arg2],
  //   });

  // console.log("Contract verified on Etherscan.");
}

main().catch((error) => {
  console.error("Deployment failed:", error);
  process.exit(1);
});
