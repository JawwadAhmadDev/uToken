const fs = require('fs');
const path = require('path');

// Read your contract files
const urTokenContractContent = fs.readFileSync(
  path.join(__dirname, '../contracts/urTokenContract.sol'),
  'utf8'
);

// Add any imported files
const ierc20Content = fs.readFileSync(
  path.join(__dirname, '../contracts/IERC20.sol'),
  'utf8'
);

// Create the Standard JSON Input structure
const standardJsonInput = {
  language: 'Solidity',
  sources: {
    'urTokenContract.sol': {
      content: urTokenContractContent
    },
    'IERC20.sol': {
      content: ierc20Content
    },
    // Add any other imported files here
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 1
    },
    viaIR: true,
    outputSelection: {
      '*': {
        '*': ['*']
      }
    }
  }
};

fs.writeFileSync(
  path.join(__dirname, '../standard-json-input.json'),
  JSON.stringify(standardJsonInput, null, 2)
);

console.log('Standard JSON Input file generated successfully!');