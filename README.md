# uToken

## Functionalities

- Whitelist

### Whitelist Functionality

**Definition:** Whitelist users dosn't need to enter password or to perform a transaction from UI for transferring funds.

**Implementation Guide:**
Implementation can be usderstand in two ways.

1. Sender is EOA:
   We will not implement that one as for any/all EOA user will have to input their password and as you said >> In the first case, all addresses will be required to enter password. ✅

2. Sender is Uniswap or AAVE:
   In the second case, we will check if the sender is a contract address, and then we will allow it to transfer uTokens without any password. ✅

**Strategy to Implement Whitelist Functinality:**
There are two ways to check that caller is a contract address or not:

- if(msg.sender == tx.origin): in case of true, caller is EOA otherwise caller is a contract.
- if(msg.sender.code.length == 0): in case of true, caller is an EOA otherwise caller is a contract.
- **_Note:_**
  1. Any of above can be used to check whether caller is an EOA or a contract.
  2. isContract() function of Address Library is deprecated due to security reasons.
