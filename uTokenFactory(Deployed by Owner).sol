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
    mapping (address => string) private currencyOf_uToken;
    // token -> uToken
    mapping (address => address) private uTokenAddressOf_token;
    // investorAddress -> All uTokens addresses invested in
    mapping (address => EnumerableSet.AddressSet) private investeduTokensOf;

    // mappings to store password and randomly generated phrase against user.
    mapping (address => bytes32) private _passwordOf;
    mapping (address => bool) private _isPasswordSet;
    mapping (address => bytes32) private _recoveryNumberOf;
    mapping (address => bool) private _isRecoveryNumberSet;


    // tokens addresses.
    address public deployedAddressOfEth;
    EnumerableSet.AddressSet private allowedTokens; // total allowed ERC20 tokens
    EnumerableSet.AddressSet private uTokensOfAllowedTokens; // uTokens addresses of allowed ERC20 Tokens

    // salt for create2 opcode.
    uint256 private _salt; // to handle create2 opcode.

    // fee detial
    uint256 public depositFeePercent = 369; // 0.369 * 1000 = 369% of total deposited amount.
    uint256 public percentOfFundAddresses = 32_000; // 32 * 1000 = 32000% of 0.369% of the deposited amount. This will be used for both (fund and charity addresses)
    uint256 public percentOfCharityAddress = 36_000; // 36 * 1000 = 36000% of 0.369% of the deposited amount.
    
    // time periods for reward
    uint256 public timeLimitForReward = 15 days;
    uint256 public timeLimitForRewardCollection = 3 days;

    
    // zoom to handle percentage in the decimals
    uint256 public constant ZOOM = 1_000_00;  // actually 100. this is divider to calculate percentage

    // fee receiver addresses.
    address public fundAddress = 0x30bE52275C572188903C45ecDD3Ed68784aDe067; // address which will receive all fees
    address public charityAddress = 0x9317Dc1623d472a588DE7d1f471a79720600019d; // address which will receive share of charity.


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
            require(!(allowedTokens.contains(_token)), "Factory: Already added");
            address _deployedAddress = _deployToken(_token);
            tokenAdressOf_uToken[_deployedAddress] = _token;
            uTokenAddressOf_token[_token] = _deployedAddress;
            currencyOf_uToken[_deployedAddress] = IuToken(_deployedAddress).currency();
            allowedTokens.add(_token);
            uTokensOfAllowedTokens.add(_deployedAddress);
        }
    }

    function addAllowedTokens(address[] memory _allowedTokens) external onlyOwner {
        _addAllowedTokens(_allowedTokens);
    }

    function deposit(string memory _password, address _uTokenAddress, uint256 _amount) external payable {
        address depositor = msg.sender;
        require(_isPasswordSet[depositor], "Factory: Password not set yet.");
        require(_passwordOf[depositor] == keccak256(bytes(_password)), "Factory: Password incorrect");
        require(_amount > 0, "Factory: invalid amount");
        require(_uTokenAddress == deployedAddressOfEth || uTokensOfAllowedTokens.contains(_uTokenAddress), "Factory: invalid uToken address");
        uint256 _depositFee = _amount.mul(depositFeePercent).div(ZOOM);
        uint256 _remaining = _amount.sub(_depositFee);

        if(_uTokenAddress == deployedAddressOfEth) {
            require(msg.value > 0, "Factory: invalid Ether");
            // payable(fundAddress).transfer(_depositFee);
            _handleFeeEth(_depositFee);
        } else {
            require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transferFrom(depositor, address(this), _amount), "Factory: TransferFrom failed");
            // require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(fundAddress, _depositFee), "Factory: transfer failed");
            _handleFeeTokens(IERC20(tokenAdressOf_uToken[_uTokenAddress]), _depositFee);
        }
        
        require(IuToken(_uTokenAddress).deposit(_remaining), "Factory: deposit failed");
        if(!(investeduTokensOf[depositor].contains(_uTokenAddress))) investeduTokensOf[depositor].add(_uTokenAddress);

        emit Deposit(depositor, _uTokenAddress, _remaining);
    }

    function _handleFeeEth(uint256 _depositFee) internal {
        uint256 _feeOfFundAddresses = _depositFee.mul(percentOfFundAddresses).div(ZOOM);
        uint256 _feeOfCharityAddress = _depositFee.mul(percentOfCharityAddress).div(ZOOM);

        payable(fundAddress).transfer(_feeOfFundAddresses);
        payable(charityAddress).transfer(_feeOfCharityAddress);
        // remaining 32% of deposited fee will be in the contract address for reward.
    }
    function _handleFeeTokens(IERC20 _tokenAddress, uint256 _depositFee) internal {
        uint256 _feeOfFundAddresses = _depositFee.mul(percentOfFundAddresses).div(ZOOM);
        uint256 _feeOfCharityAddress = _depositFee.mul(percentOfCharityAddress).div(ZOOM);

        _tokenAddress.transfer(fundAddress, _feeOfFundAddresses);
        _tokenAddress.transfer(charityAddress, _feeOfCharityAddress);
        // remaining 32% of deposited fee will be in the contract address reward.
    }


    function withdraw(string memory _password, address _uTokenAddress, uint256 _amount) external {
        address withdrawer = msg.sender;
        require(_isPasswordSet[withdrawer], "Factory: Password not set yet.");
        require(_passwordOf[withdrawer] == keccak256(bytes(_password)), "Factory: Password incorrect");
        require(_uTokenAddress == deployedAddressOfEth || uTokensOfAllowedTokens.contains(_uTokenAddress), "Factory: invalid uToken address");
        uint256 balance = IuToken(_uTokenAddress).balanceOf(withdrawer);
        require(_amount > 0, "Factory: invalid amount");
        require(balance >= _amount, "Factory: Not enought tokens");

        require(IuToken(_uTokenAddress).withdraw(_amount), "Factory: withdraw failed");
        
        if(_uTokenAddress == deployedAddressOfEth) {
            payable(withdrawer).transfer(_amount);
        } else {
            require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(withdrawer, _amount), "Factory: transfer failed");
        }

        if(balance.sub(_amount) == 0) investeduTokensOf[withdrawer].remove(_uTokenAddress);

        emit Withdraw(withdrawer, _uTokenAddress, _amount);
    }


    function transfer(string memory _password, address _uTokenAddress, address _to, uint256 _amount) external returns (bool) {
        address caller = msg.sender;
        require(_isPasswordSet[caller], "Factory: Password not set yet.");
        require(_passwordOf[caller] == keccak256(bytes(_password)), "Factory: Password incorrect");
        require(_amount > 0, "Factory: Invalid amount");
        require(_uTokenAddress == deployedAddressOfEth || uTokensOfAllowedTokens.contains(_uTokenAddress), "Factory: invalid uToken address");

        require(IuToken(_uTokenAddress).transfer(_to, _amount), "Factory, transfer failed");
        investeduTokensOf[_to].add(_uTokenAddress);
        return true;
    }


    function setPasswordAndRecoveryNumber(string memory _password, string memory _recoveryNumber) external {
        address caller = msg.sender;
        require((!(_isPasswordSet[caller]) && !(_isRecoveryNumberSet[caller])), "Factory: Already set");
        _passwordOf[caller] = keccak256(bytes(_password));
        _recoveryNumberOf[caller] = keccak256(bytes(_recoveryNumber));
        _isPasswordSet[caller] = true;
        _isRecoveryNumberSet[caller] = true;
    }


    function changePassword(string memory _recoveryNumber, string memory _password) external {
        address caller = msg.sender;
        require(_recoveryNumberOf[caller] == keccak256(bytes(_recoveryNumber)), "Factory: incorrect recovery number");
        _passwordOf[caller] = keccak256(bytes(_password));
    }
    
    
    //--------------------Read Functions -------------------------------//
    //--------------------Allowed Tokens -------------------------------//
    function all_AllowedTokens() external view returns (address[] memory){
        return allowedTokens.values();
    }

    function all_AllowedTokensCount() external view returns (uint256) {
        return allowedTokens.length();
    }

    function all_uTokensOfAllowedTokens() external view returns (address[] memory){
        return uTokensOfAllowedTokens.values();
    }

    function all_uTokensOfAllowedTokensCount() external view returns (uint256) {
        return uTokensOfAllowedTokens.length();
    }

    function get_TokenAddressOfuToken(address _uToken) external view returns (address) {
        return tokenAdressOf_uToken[_uToken];
    }

    function get_uTokenAddressOfToken(address _token) external view returns (address) {
        return uTokenAddressOf_token[_token];
    }

    function getInvested_uTokensOfUser(address _investor) external view returns (address[] memory investeduTokens) {
        investeduTokens = investeduTokensOf[_investor].values();
    }

    function get_CurrencyOfuToken(address _uToken) external view returns (string memory currency) {
        return currencyOf_uToken[_uToken];
    }

    function isPasswordCorrect(address _user, string memory _password) external view returns (bool) {
        return (_passwordOf[_user] == keccak256(bytes(_password)));
    }

    function isRecoveryNumberCorrect(address _user, string memory _recoveryNumber) external view returns (bool) {
        return (_recoveryNumberOf[_user] == keccak256(bytes(_recoveryNumber)));
    }

    function isPasswordSet(address _user) external view returns (bool) {
        return _isPasswordSet[_user];
    }

    function isRecoveryNumberSet(address _user) external view returns (bool) {
        return _isRecoveryNumberSet[_user];
    }
}