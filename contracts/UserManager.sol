// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PasswordManager.sol";
import "./interfaces/IUserManager.sol";

contract UserManager is PasswordManager, IUserManager {
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

    function addDepositor(address _depositor) public override {
        if (!allDepositors.contains(_depositor)) {
            allDepositors.add(_depositor);
        }
    }

    function addDepositedurToken(
        address _depositor,
        address _urToken
    ) public override {
        if (!depositedurTokensOf[_depositor].contains(_urToken)) {
            depositedurTokensOf[_depositor].add(_urToken);
        }
    }

    function addDepositedurTokenForPeriod(
        address _depositor,
        uint256 _period,
        address _urToken
    ) public override {
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
    ) public override {
        depositedAmountOfUserAgainsturToken[_depositor][_urToken] += _amount;
    }

    function setDepositedAmount(
        address _depositor,
        address _urToken,
        uint256 _amount
    ) public override {
        depositedAmountOfUserAgainsturToken[_depositor][_urToken] = _amount;
    }

    function updateDepositedAmountForPeriod(
        address _depositor,
        address _urToken,
        uint256 _period,
        uint256 _amount
    ) public override {
        depositedAmountOfUserAgainsturTokenForPeriod[_depositor][_urToken][
            _period
        ] += _amount;
    }

    function setDepositedAmountForPeriod(
        address _depositor,
        address _urToken,
        uint256 _period,
        uint256 _amount
    ) public override {
        depositedAmountOfUserAgainsturTokenForPeriod[_depositor][_urToken][
            _period
        ] = _amount;
    }

    function updateNativeCurrencyDeposited(
        address _depositor,
        uint256 _amount
    ) public override {
        nativeCurrencyDepositedBy[_depositor] += _amount;
    }

    function setMasterKey(
        address _user,
        string memory _masterKey
    ) public override {
        _masterKeyOf[_user] = keccak256(bytes(_masterKey));
        _isMasterKeySetOf[_user] = true;
    }

    function setSignKey(address _user, bool _isQuantum) public override {
        _isSignKeySetOf[_user] = true;
        _isQuantumProtected[_user] = _isQuantum;
    }

    function getAllDepositorsInSystem()
        public
        view
        override
        returns (address[] memory)
    {
        return allDepositors.values();
    }

    function getNativeCurrencyDepositedBy(
        address _depositor
    ) public view override returns (uint256) {
        return nativeCurrencyDepositedBy[_depositor];
    }

    function getDepositedurTokensForUser(
        address _depositor
    ) public view override returns (address[] memory) {
        return depositedurTokensOf[_depositor].values();
    }

    function getDepositedurTokensOfUserForPeriodFor369hours(
        address _depositor,
        uint256 _period
    ) public view override returns (address[] memory) {
        return depositedurTokensOfUserForPeriod[_depositor][_period].values();
    }

    function getDepositedAmountOfUserAgainsturToken(
        address _depositor,
        address _urToken
    ) public view override returns (uint256) {
        return depositedAmountOfUserAgainsturToken[_depositor][_urToken];
    }

    function getDepositedAmountOfUserAgainsturTokenForPeriodFor369hours(
        address _depositor,
        address _urToken,
        uint256 _period
    ) public view override returns (uint256) {
        return
            depositedAmountOfUserAgainsturTokenForPeriod[_depositor][_urToken][
                _period
            ];
    }

    function isSignKeySet(address _user) public view override returns (bool) {
        return _isSignKeySetOf[_user];
    }

    function isQuantumProtected(
        address _user
    ) public view override returns (bool) {
        return _isQuantumProtected[_user];
    }

    function isMasterKeySet(address _user) public view override returns (bool) {
        return _isMasterKeySetOf[_user];
    }

    function isMasterKeyCorrect(
        address _user,
        string memory _masterKey
    ) public view override returns (bool) {
        return _masterKeyOf[_user] == keccak256(bytes(_masterKey));
    }

    function isSignKeyCorrect(
        address _user,
        bytes32 _signkeyHash
    ) public view override returns (bool) {
        return passwordDataOf[_user].keccakHash == _signkeyHash;
    }

    function getDepositDetailsForUser(
        address _depositor
    ) public view override returns (DepositsOfUser[] memory depositDetails) {
        address[] memory totalurTokens = getDepositedurTokensForUser(
            _depositor
        );
        uint256 tokensCount = totalurTokens.length;

        depositDetails = new DepositsOfUser[](tokensCount);
        if (tokensCount > 0) {
            for (uint256 i; i < tokensCount; i++) {
                depositDetails[i] = DepositsOfUser({
                    urTokenAddress: totalurTokens[i],
                    amount: getDepositedAmountOfUserAgainsturToken(
                        _depositor,
                        totalurTokens[i]
                    )
                });
            }
        }
    }

    /**
     * @dev Returns the details of deposits made by a specific depositor during a specific period.
     *
     * This function takes the address of an depositor and a period, and returns an array of `DepositsForPeriodOfUser`
     * structs that includes the urToken address and the amount deposited for each urToken during the specified period.
     *
     * @param _depositor The address of the depositor.
     * @param _period The period of deposits.
     *
     * @return depositDetails An array of `DepositsForPeriodOfUser` structs that contain the urToken address and the investment amount for each investment made by the investor during the specified period.
     */
    function getDepositDetailsOfUserForPeriodFor369hours(
        address _depositor,
        uint256 _period
    )
        public
        view
        override
        returns (DepositsForPeriodOfUser[] memory depositDetails)
    {
        address[]
            memory totalurTokens = getDepositedurTokensOfUserForPeriodFor369hours(
                _depositor,
                _period
            );
        uint256 tokensCount = totalurTokens.length;

        depositDetails = new DepositsForPeriodOfUser[](tokensCount);
        if (tokensCount > 0) {
            for (uint256 i; i < tokensCount; i++) {
                depositDetails[i] = DepositsForPeriodOfUser({
                    urTokenAddress: totalurTokens[i],
                    amount: getDepositedAmountOfUserAgainsturTokenForPeriodFor369hours(
                        _depositor,
                        totalurTokens[i],
                        _period
                    )
                });
            }
        }
    }
}
