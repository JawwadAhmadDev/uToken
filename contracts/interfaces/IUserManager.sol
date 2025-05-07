// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUserManager {
    // Structs
    struct DepositsOfUser {
        address urTokenAddress;
        uint256 amount;
    }

    struct DepositsForPeriodOfUser {
        address urTokenAddress;
        uint256 amount;
    }

    // View functions

    function addDepositor(address _depositor) external;

    function addDepositedurToken(address _depositor, address _urToken) external;

    function addDepositedurTokenForPeriod(
        address _depositor,
        uint256 _period,
        address _urToken
    ) external;

    function updateDepositedAmount(
        address _depositor,
        address _urToken,
        uint256 _amount
    ) external;

    function setDepositedAmount(
        address _depositor,
        address _urToken,
        uint256 _amount
    ) external;

    function setDepositedAmountForPeriod(
        address _depositor,
        address _urToken,
        uint256 _period,
        uint256 _amount
    ) external;

    function setMasterKey(address _user, string memory _masterKey) external;

    function setSignKey(address _user, bool _isQuantum) external;

    function updateDepositedAmountForPeriod(
        address _depositor,
        address _urToken,
        uint256 _period,
        uint256 _amount
    ) external;

    function updateNativeCurrencyDeposited(
        address _depositor,
        uint256 _amount
    ) external;

    function getAllDepositorsInSystem()
        external
        view
        returns (address[] memory);

    function getNativeCurrencyDepositedBy(
        address _depositor
    ) external view returns (uint256);

    function getDepositedurTokensForUser(
        address _depositor
    ) external view returns (address[] memory);

    function getDepositedurTokensOfUserForPeriodFor369hours(
        address _depositor,
        uint256 _period
    ) external view returns (address[] memory);

    function getDepositedAmountOfUserAgainsturToken(
        address _depositor,
        address _urToken
    ) external view returns (uint256);

    function getDepositedAmountOfUserAgainsturTokenForPeriodFor369hours(
        address _depositor,
        address _urToken,
        uint256 _period
    ) external view returns (uint256);

    function isSignKeySet(address _user) external view returns (bool);

    function isQuantumProtected(address _user) external view returns (bool);

    function isMasterKeySet(address _user) external view returns (bool);

    function isMasterKeyCorrect(
        address _user,
        string memory _masterKey
    ) external view returns (bool);

    function isSignKeyCorrect(
        address _user,
        bytes32 _signkeyHash
    ) external view returns (bool);

    function getDepositDetailsForUser(
        address _depositor
    ) external view returns (DepositsOfUser[] memory);

    function getDepositDetailsOfUserForPeriodFor369hours(
        address _depositor,
        uint256 _period
    ) external view returns (DepositsForPeriodOfUser[] memory);

    // Errors
    error SignKeySet();
    error SignKeyNotSet();
    error QuantumNotSet();
    error SignKeyIncorrect();
    error MasterKeyIncorrect();
    error AlreadyQuantomProtected();
    error UserNotRegistered();
}
