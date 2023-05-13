// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "IERC20.sol";
import "uToken.sol";

contract uTokenFactory is Ownable{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => address) private deployedAddressOfToken;
    address public deployedAddressOfEth;

    uint256 private _salt;
    EnumerableSet.AddressSet private allowedTokens;


    event Deposit(address depositor, address token, uint256 amount);
    event Withdraw(address withdrawer, address token, uint256 amount);

    constructor (address[] memory _allowedTokens) {
        deployedAddressOfEth = _deployEth();
        _addAllowedTokens(_allowedTokens);
    }

    function _deployEth() public returns (address deployedEth) {
        bytes memory bytecode = type(uToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedEth := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IuToken(deployedEth).initialize("uEth", "uETH", "ETH");
    }

    function _deployToken(address _token) internal returns (address deployedToken) {
        IERC20 __token = IERC20(_token);
        string memory name = string.concat("u" ,__token.name());
        string memory symbol = string.concat("u", __token.symbol());
        string memory currency = __token.symbol();

        bytes memory bytecode = type(uToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IuToken(deployedToken).initialize(name, symbol, currency);
    }


    function _addAllowedTokens(address[] memory _allowedTokens) internal {
        for(uint i; i < _allowedTokens.length; i++) {
            address _token = _allowedTokens[i];
            require(_token.isContract(), "uTokenFactory: INVALID ALLOWED TOKEN ADDRESS");
            allowedTokens.add(_deployToken(_token));
        }
    }

    function addAllowedTokens(address[] memory _allowedTokens) external onlyOwner {
        _addAllowedTokens(_allowedTokens);
    }

    function deposit(address _deployedAddress, uint256 _amount) external payable {
        require(_amount > 0, "Factory: invalid amount");
        if(_deployedAddress == deployedAddressOfEth) {
            require(msg.value > 0, "Factory: invalid Ether");
        } else {
            require(IERC20(_deployedAddress).transferFrom(msg.sender, address(this), _amount), "Factory: TransferFrom failed");
        }

        require(IuToken(_deployedAddress).deposit(_amount), "Factory: deposit failed");

        emit Deposit(msg.sender, _deployedAddress, _amount);
    }

    function withdraw(address _deployedAddress, uint256 _amount) external {
        require(_amount > 0, "Factory: invalid amount");
        require(IuToken(_deployedAddress).balanceOf(msg.sender) >= _amount, "Factory: Not enought tokens");

        require(IuToken(_deployedAddress).withdraw(_amount), "Factory: withdraw failed");
        
        if(_deployedAddress == deployedAddressOfEth) {
            payable(msg.sender).transfer(_amount);
        } else {
            require(IuToken(_deployedAddress).transfer(msg.sender, _amount), "Factory: transfer failed");
        }

        emit Withdraw(msg.sender, _deployedAddress, _amount);
    }

    //--------------------Read Functions -------------------------------//
    //--------------------Allowed Tokens -------------------------------//
    function getAllowedTokens() external view returns (address[] memory){
        return allowedTokens.values();
    }

    function getAllowedTokensCount() external view returns (uint256) {
        return allowedTokens.length();
    }
}
