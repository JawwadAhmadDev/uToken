// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./urTokenContract.sol";

contract TokenManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private allowedTokens;
    EnumerableSet.AddressSet private urTokensOfAllowedTokens;
    address public urTokenAddressOfETH;
    address[] private whiteListAddresses;

    mapping(address => address) private tokenAdressForurToken;
    mapping(address => string) private currencyOfurToken;
    mapping(address => address) private urTokenAddressForToken;

    uint256 private _salt;

    event TokenDeployed(address indexed tokenAddress, string name);
    event TokenAdded(
        address indexed tokenAddress,
        address indexed deployedAddress
    );
    event TokenRemoved(address indexed tokenAddress);

    error TokenAlreadyAdded();
    error TokenNotAdded();
    error InvalidAllowedToken();

    constructor(
        address[] memory _whiteListAddresses,
        address[] memory _allowedTokens
    ) {
        whiteListAddresses = _whiteListAddresses;
        urTokenAddressOfETH = _deployETH();

        if (_allowedTokens.length > 0) {
            addAllowedTokens(_allowedTokens);
        }
    }

    function _deployETH() internal returns (address deployedEth) {
        bytes memory bytecode = type(urTokenContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedEth := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IurToken(deployedEth).initialize(
            "urETH",
            "urETH",
            "ETHER",
            18,
            whiteListAddresses
        );

        emit TokenDeployed(deployedEth, "urETH");
    }

    function _deployToken(
        address _token
    ) internal returns (address deployedToken) {
        IERC20Metadata tokenContract = IERC20Metadata(_token);
        string memory name = string(
            abi.encodePacked("ur", tokenContract.name())
        );
        string memory symbol = string(
            abi.encodePacked("ur", tokenContract.symbol())
        );
        string memory currency = tokenContract.symbol();
        uint8 decimals = tokenContract.decimals();

        bytes memory bytecode = type(urTokenContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedToken := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        IurToken(deployedToken).initialize(
            name,
            symbol,
            currency,
            decimals,
            whiteListAddresses
        );

        emit TokenDeployed(deployedToken, name);
    }

    function addAllowedTokens(address[] memory _allowedTokens) public {
        uint256 length = _allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = _allowedTokens[i];

            if (!(tokenAddress.code.length > 0)) revert InvalidAllowedToken();
            if (allowedTokens.contains(tokenAddress))
                revert TokenAlreadyAdded();

            address deployedAddress = _deployToken(tokenAddress);
            tokenAdressForurToken[deployedAddress] = tokenAddress;
            urTokenAddressForToken[tokenAddress] = deployedAddress;
            currencyOfurToken[deployedAddress] = IurToken(deployedAddress)
                .currency();

            allowedTokens.add(tokenAddress);
            urTokensOfAllowedTokens.add(deployedAddress);

            emit TokenAdded(tokenAddress, deployedAddress);
        }
    }

    function removeAllowedTokens(address[] memory _allowedTokens) external {
        uint256 length = _allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = _allowedTokens[i];

            if (!allowedTokens.contains(tokenAddress)) revert TokenNotAdded();

            allowedTokens.remove(tokenAddress);
            urTokensOfAllowedTokens.remove(
                urTokenAddressForToken[tokenAddress]
            );

            emit TokenRemoved(tokenAddress);
        }
    }

    // View functions
    function allAllowedTokens() public view returns (address[] memory) {
        return allowedTokens.values();
    }

    function allAllowedTokensCount() public view returns (uint256) {
        return allowedTokens.length();
    }

    function allurTokensOfAllowedTokens()
        public
        view
        returns (address[] memory)
    {
        return urTokensOfAllowedTokens.values();
    }

    function allurTokensOfAllowedTokensCount() public view returns (uint256) {
        return urTokensOfAllowedTokens.length();
    }

    function getTokenAddressForurToken(
        address _urToken
    ) public view returns (address) {
        return tokenAdressForurToken[_urToken];
    }

    function geturTokenAddressForToken(
        address _token
    ) public view returns (address) {
        return urTokenAddressForToken[_token];
    }

    function getCurrencyOfurToken(
        address _urToken
    ) public view returns (string memory) {
        return currencyOfurToken[_urToken];
    }

    function isAllowedToken(address _token) public view returns (bool) {
        return allowedTokens.contains(_token);
    }

    function isAllowedurToken(address _urToken) public view returns (bool) {
        return
            _urToken == urTokenAddressOfETH ||
            urTokensOfAllowedTokens.contains(_urToken);
    }

    function getAllWhiteListAddresses()
        public
        view
        returns (address[] memory _whiteListAddresses)
    {
        uint256 _length = whiteListAddresses.length;
        _whiteListAddresses = new address[](_length);

        for (uint256 i; i < _length; i++) {
            _whiteListAddresses[i] = whiteListAddresses[i];
        }
    }
}
