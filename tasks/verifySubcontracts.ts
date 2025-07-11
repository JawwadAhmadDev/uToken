// tasks/verifySubcontracts.ts
import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import * as fs from "fs";
import * as path from "path";

task("verify:subcontracts", "Verifies all subcontracts deployed by the factory")
  .addParam("factory", "The factory contract address")
  .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
    const { factory } = taskArgs;

    console.log(`\nStarting verification process...`);
    console.log(`Factory address: ${factory}\n`);

    try {
      // Get the factory contract
      const factoryContract = await hre.ethers.getContractAt(
        "urTokenFactoryContract",
        factory
      );

      // Get all urTokens
      const urTokens = await factoryContract.allurTokensOfAllowedTokens();
      console.log(`Found ${urTokens.length} urTokens to verify\n`);

      const urTokenOfETH = await factoryContract.urTokenAddressOfETH();
      if (urTokenOfETH) {
        console.log(`Found urToken for ETH: ${urTokenOfETH}`);
        // Verify the urTokenAddress for ETH
        console.log(`Verifying urToken for ETH at ${urTokenOfETH}...`);
        await hre.run("verify:verify", {
          address: urTokenOfETH,
          contract: "contracts/urTokenContract.sol:urTokenContract",
          constructorArguments: [], // No constructor arguments as we use initialize
        });
      } else {
        console.log(`No urToken found for ETH`);
      }

      // Get the flattened source code
      const flattenedSource = await getFlattenedSource();

      // Verify each contract
      for (const urTokenAddress of urTokens) {
        try {
          console.log(`\n=== Verifying urToken at ${urTokenAddress} ===`);

          // Get token details
          const tokenAddress = await factoryContract.getTokenAddressForurToken(
            urTokenAddress
          );
          const currency = await factoryContract.getCurrencyOfurToken(
            urTokenAddress
          );
          console.log(`Token details:`);
          console.log(`- Address: ${tokenAddress}`);
          console.log(`- Currency: ${currency}`);

          // Get initialization parameters
          const urToken = await hre.ethers.getContractAt(
            "urTokenContract",
            urTokenAddress
          );
          const name = await urToken.name();
          const symbol = await urToken.symbol();
          const decimals = await urToken.decimals();

          console.log(`\nInitialization parameters:`);
          console.log(`- Name: ${name}`);
          console.log(`- Symbol: ${symbol}`);
          console.log(`- Decimals: ${decimals}`);

          // Verify the contract
          await hre.run("verify:verify", {
            address: urTokenAddress,
            contract: "contracts/urTokenContract.sol:urTokenContract",
            constructorArguments: [], // No constructor arguments as we use initialize
          });

          console.log(`\n✅ Successfully verified ${urTokenAddress}`);
        } catch (error) {
          console.error(`\n❌ Failed to verify ${urTokenAddress}:`);
          console.error(error.message);
        }
      }
    } catch (error) {
      console.error("\n❌ Fatal error during verification process:");
      console.error(error);
      process.exit(1);
    }
  });

// Helper function to get flattened source code
async function getFlattenedSource(): Promise<string> {
  const sourcePath = path.join(__dirname, "../contracts/urTokenContract.sol");
  const source = fs.readFileSync(sourcePath, "utf8");

  // Get all imports
  const importRegex = /import\s+["'](.+?)["']/g;
  const imports: string[] = [];
  let match;

  while ((match = importRegex.exec(source)) !== null) {
    imports.push(match[1]);
  }

  // Read and include all imported files
  let flattenedSource = source;
  for (const imp of imports) {
    const importPath = path.join(__dirname, "../node_modules", imp);
    if (fs.existsSync(importPath)) {
      const importSource = fs.readFileSync(importPath, "utf8");
      flattenedSource = flattenedSource.replace(
        `import "${imp}";`,
        importSource
      );
    }
  }

  return flattenedSource;
}


// command to verify all subcontracts
// npx hardhat verify:subcontracts --factory <FACTORY_ADDRESS> --network <network>
