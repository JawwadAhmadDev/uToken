# uToken

## Functionalities

- Whitelist

### Whitelist Functionality

**Definition:** Whitelist users dosn't need to enter password or to perform a transaction from UI for transferring funds.

**Implementation Guide:**
Implementation can be usderstand in two ways.

1. Sender is EOA
   We will not implement that one as for any/all EOA user will have to input their password and as you said >> In the first case, all addresses will be required to enter password. ✅

2. Sender is Uniswap or AAVE:
   In the second case, we will check if the sender is a contract address, and then we will allow it to transfer uTokens without any password. ✅
