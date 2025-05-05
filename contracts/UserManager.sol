// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PasswordManager.sol";

contract UserManager is PasswordManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private allDepositors;
    mapping(address => uint256) private nativeCurrencyDepositedBy;
    mapping(address => EnumerableSet.AddressSet) private depositedurTokensOf;
    mapping(address => mapping(uint256 => EnumerableSet.AddressSet))
        private depositedurTokensOfUserForPeriod;
    mapping(address => mapping(address => uint256))
        private depositedAmountOfUserAgainsturToken;
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private depositedAmountOfUserAgainsturTokenForPeriod;

    mapping(address => bool) private _isQuantumProtected;
    mapping(address => bool) private _isSignKeySetOf;
    mapping(address => bytes32) private _masterKeyOf;
    mapping(address => bool) private _isMasterKeySetOf;

    error SignKeySet();
    error SignKeyNotSet();
    error QuantumNotSet();
    error SignKeyIncorrect();
    error MasterKeyIncorrect();
    error AlreadyQuantomProtected();
    error UserNotRegistered();

    constructor(string memory _appName) PasswordManager(_appName) {}

    function addDepositor(address _depositor) internal {
        if (!allDepositors.contains(_depositor)) {
            allDepositors.add(_depositor);
        }
    }

    function addDepositedurToken(
        address _depositor,
        address _urToken
    ) internal {
        if (!depositedurTokensOf[_depositor].contains(_urToken)) {
            depositedurTokensOf[_depositor].add(_urToken);
        }
    }

    function addDepositedurTokenForPeriod(
        address _depositor,
        uint256 _period,
        address _urToken
    ) internal {
        if (
            !depositedurTokensOfUserForPeriod[_depositor][_period].contains(
                _urToken
            )
        ) {
            depositedurTokensOfUserForPeriod[_depositor][_period].add(_urToken);
        }
    }

    function updateDepositedAmount(
        address _depositor,
        address _urToken,
        uint256 _amount
    ) internal {
        depositedAmountOfUserAgainsturToken[_depositor][_urToken] += _amount;
    }

    function updateDepositedAmountForPeriod(
        address _depositor,
        address _urToken,
        uint256 _period,
        uint256 _amount
    ) internal {
        depositedAmountOfUserAgainsturTokenForPeriod[_depositor][_urToken][
            _period
        ] += _amount;
    }

    function updateNativeCurrencyDeposited(
        address _depositor,
        uint256 _amount
    ) internal {
        nativeCurrencyDepositedBy[_depositor] += _amount;
    }

    function setMasterKey(address _user, string memory _masterKey) internal {
        _masterKeyOf[_user] = keccak256(bytes(_masterKey));
        _isMasterKeySetOf[_user] = true;
    }

    function setSignKey(address _user, bool _isQuantum) internal {
        _isSignKeySetOf[_user] = true;
        _isQuantumProtected[_user] = _isQuantum;
    }

    function getAllDepositorsInSystem() public view returns (address[] memory) {
        return allDepositors.values();
    }

    function getNativeCurrencyDepositedBy(
        address _depositor
    ) public view returns (uint256) {
        return nativeCurrencyDepositedBy[_depositor];
    }

    function getDepositedurTokensForUser(
        address _depositor
    ) public view returns (address[] memory) {
        return depositedurTokensOf[_depositor].values();
    }

    function getDepositedurTokensOfUserForPeriodFor369hours(
        address _depositor,
        uint256 _period
    ) public view returns (address[] memory) {
        return depositedurTokensOfUserForPeriod[_depositor][_period].values();
    }

    function getDepositedAmountOfUserAgainsturToken(
        address _depositor,
        address _urToken
    ) public view returns (uint256) {
        return depositedAmountOfUserAgainsturToken[_depositor][_urToken];
    }

    function getDepositedAmountOfUserAgainsturTokenForPeriodFor369hours(
        address _depositor,
        address _urToken,
        uint256 _period
    ) public view returns (uint256) {
        return
            depositedAmountOfUserAgainsturTokenForPeriod[_depositor][_urToken][
                _period
            ];
    }

    function isSignKeySet(address _user) public view returns (bool) {
        return _isSignKeySetOf[_user];
    }

    function isQuantumProtected(address _user) public view returns (bool) {
        return _isQuantumProtected[_user];
    }

    function isMasterKeySet(address _user) public view returns (bool) {
        return _isMasterKeySetOf[_user];
    }

    function isMasterKeyCorrect(
        address _user,
        string memory _masterKey
    ) public view returns (bool) {
        return _masterKeyOf[_user] == keccak256(bytes(_masterKey));
    }

    function isSignKeyCorrect(
        address _user,
        bytes32 _signkeyHash
    ) public view returns (bool) {
        return passwordDataOf[_user].keccakHash == _signkeyHash;
    }
}
