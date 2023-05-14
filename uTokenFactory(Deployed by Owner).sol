// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "IERC20.sol";
import "uToken.sol";

contract uTokenFactory is Ownable{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    // uToken -> Token Address (against which contract is deployed)
    mapping (address => address) private tokenAdressOf_uToken;
    mapping (address => EnumerableSet.AddressSet) internal investeduTokensOf;
    address public deployedAddressOfEth;

    EnumerableSet.AddressSet private allowedTokens;
    uint256 private _salt;


    event Deposit(address depositor, address token, uint256 amount);
    event Withdraw(address withdrawer, address token, uint256 amount);

    constructor (address[] memory _allowedTokens) {
        deployedAddressOfEth = _deployEth();
        _addAllowedTokens(_allowedTokens);
    }

    function _deployEth() internal returns (address deployedEth) {
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
            address _deployedAddress = _deployToken(_token);
            tokenAdressOf_uToken[_deployedAddress] = _token;
            allowedTokens.add(_deployedAddress);
        }
    }

    function addAllowedTokens(address[] memory _allowedTokens) external onlyOwner {
        _addAllowedTokens(_allowedTokens);
    }

    function deposit(address _uTokenAddress, uint256 _amount) external payable {
        require(_amount > 0, "Factory: invalid amount");
        
        if(_uTokenAddress == deployedAddressOfEth) {
            require(msg.value > 0, "Factory: invalid Ether");
        } else {
            require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transferFrom(msg.sender, address(this), _amount), "Factory: TransferFrom failed");
        }
        require(IuToken(_uTokenAddress).deposit(_amount), "Factory: deposit failed");
        if(!(investeduTokensOf[msg.sender].contains(_uTokenAddress))) investeduTokensOf[msg.sender].add(_uTokenAddress);

        emit Deposit(msg.sender, _uTokenAddress, _amount);
    }

    function withdraw(address _uTokenAddress, uint256 _amount) external {
        uint256 balance = IuToken(_uTokenAddress).balanceOf(msg.sender);
        require(_amount > 0, "Factory: invalid amount");
        require(balance >= _amount, "Factory: Not enought tokens");

        require(IuToken(_uTokenAddress).withdraw(_amount), "Factory: withdraw failed");
        
        if(_uTokenAddress == deployedAddressOfEth) {
            payable(msg.sender).transfer(_amount);
        } else {
            require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(msg.sender, _amount), "Factory: transfer failed");
        }

        if(balance.sub(_amount) == 0) investeduTokensOf[msg.sender].remove(_uTokenAddress);

        emit Withdraw(msg.sender, _uTokenAddress, _amount);
    }


    function transfer(address _uTokenAddress, address _to, uint256 _amount) external returns (bool) {
        require(_amount > 0, "Factory: Invalid amount");
        require(allowedTokens.contains(_uTokenAddress) || _uTokenAddress == deployedAddressOfEth, "Factory: Invalid uToken Address");

        require(IuToken(_uTokenAddress).transfer(_to, _amount), "Factory, transfer failed");
        investeduTokensOf[_to].add(_uTokenAddress);
        return true;
    }

    
    //--------------------Read Functions -------------------------------//
    //--------------------Allowed Tokens -------------------------------//
    function getAllowedTokens() external view returns (address[] memory){
        return allowedTokens.values();
    }

    function getAllowedTokensCount() external view returns (uint256) {
        return allowedTokens.length();
    }

    function getTokenAddressOfuToken(address _uToken) external view returns (address) {
        return tokenAdressOf_uToken[_uToken];
    }


    function getInvested_uTokensOf(address _investor) external view returns (address[] memory investeduTokens) {
        investeduTokens = investeduTokensOf[_investor].values();
    }

}
