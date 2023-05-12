// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract uTokenFactory is Ownable{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => address) private deployedAddressOfToken;

    EnumerableSet.AddressSet private allowedTokens;
    constructor (address[] memory _allowedTokens) {
        _addAllowedTokens(_allowedTokens);
    }

    function _addAllowedTokens(address[] memory _allowedTokens) internal {
        for(uint i; i < _allowedTokens.length; i++) {
            address _token = _allowedTokens[i];
            require(_token.isContract(), "uTokenFactory: INVALID ALLOWED TOKEN ADDRESS");
            allowedTokens.add(_token);
        }
    }

    function addAllowedTokens(address[] memory _allowedTokens) external onlyOwner {
        _addAllowedTokens(_allowedTokens);
    }



    function getAllowedTokens() external view returns (address[] memory){
        return allowedTokens.values();
    }

    function getAllowedTokensCount() external view returns (uint256) {
        return allowedTokens.length();
    }
}
