// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "./urTokenContract.sol";
import "./TokenManager.sol";
import "./FeeManager.sol";
import "./PeriodManager.sol";
import "./UserManager.sol";

contract urTokenFactoryContract is
    TokenManager,
    FeeManager,
    PeriodManager,
    UserManager
{
    using Address for address;

    event Protect(
        address depositor,
        address token,
        uint256 period,
        uint256 amount
    );
    event BurnAndUnprotect(address withdrawer, address token, uint256 amount);
    event RewardOfETH(
        address rewardCollector,
        uint256 period,
        uint256 ethAmount
    );
    event RewardOfToken(
        address rewardCollector,
        uint256 period,
        address token,
        uint256 tokenAmount
    );

    event SignKeyChanged(
        address indexed userAddress,
        uint256 timestamp,
        bool isQuantumProtected
    );
    error InvalidurToken();
    error WithdrawFailed();
    error Failed();

    constructor(
        string memory _appName,
        address[] memory _allowedTokens,
        address[] memory _whiteListAddresses,
        address _priceFeedAddress
    )
        TokenManager(_whiteListAddresses, _allowedTokens)
        FeeManager(_priceFeedAddress)
        PeriodManager()
        UserManager(_appName)
    {}

    function protect(
        address _urTokenAddress,
        uint256 _amount,
        bool _quantumVerified,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature,
        address _paymentToken
    ) external payable {
        address depositor = msg.sender;
        bool payInETH = _paymentToken == address(0);

        if (!isSignKeySet(depositor)) revert SignKeyNotSet();
        if (_quantumVerified && !isQuantumProtected(depositor))
            revert QuantumNotSet();
        if (
            !verifyLogin(
                depositor,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            )
        ) revert SignKeyIncorrect();
        if (!(_amount > 0)) revert InvalidAmount();
        if (!isAllowedurToken(_urTokenAddress)) revert InvalidurToken();

        uint256 currentTimePeriodCount = getCurrentPeriodFor369hours();
        uint256 requiredETHFee;

        if (payInETH) {
            requiredETHFee = calculateETHFee(protectionFeeInUSD);
            uint256 _totalETHAmount;
            if (_urTokenAddress == urTokenAddressOfETH) {
                _totalETHAmount = requiredETHFee + _amount;
            } else {
                _totalETHAmount = requiredETHFee;
            }

            if (!(msg.value >= _totalETHAmount)) revert InvalidAmount();

            if (msg.value > _totalETHAmount) {
                payable(depositor).transfer(msg.value - _totalETHAmount);
            }

            uint256 thirtyPercentShare = (requiredETHFee *
                percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
                100_000;
            addETHToPeriod(currentTimePeriodCount, thirtyPercentShare);
            _handleFeeETH(requiredETHFee);
        } else {
            if (!isAllowedToken(_paymentToken)) revert InvalidAllowedToken();

            uint256 requiredTokenAmount = calculateTokenFee(
                protectionFeeInUSD,
                _paymentToken
            );
            uint256 thirtyPercentShare = (requiredTokenAmount *
                percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
                100_000;

            addTokenToPeriod(currentTimePeriodCount, _paymentToken);
            addTokenRewardToPeriod(
                currentTimePeriodCount,
                _paymentToken,
                thirtyPercentShare
            );
            _handleFeeToken(_paymentToken, requiredTokenAmount);
        }

        IurToken(_urTokenAddress).protect(depositor, _amount);

        if (_urTokenAddress != urTokenAddressOfETH) {
            IERC20(getTokenAddressForurToken(_urTokenAddress)).transferFrom(
                depositor,
                address(this),
                _amount
            );
        }

        addDepositor(depositor);
        addDepositedurToken(depositor, _urTokenAddress);
        addDepositedurTokenForPeriod(
            depositor,
            currentTimePeriodCount,
            _urTokenAddress
        );
        updateDepositedAmount(depositor, _urTokenAddress, _amount);
        updateDepositedAmountForPeriod(
            depositor,
            _urTokenAddress,
            currentTimePeriodCount,
            _amount
        );

        if (_urTokenAddress == urTokenAddressOfETH) {
            updateNativeCurrencyDeposited(depositor, _amount);
        }

        markPeriodAsDeposited(currentTimePeriodCount);
        addDepositorToPeriod(currentTimePeriodCount, depositor);

        emit Protect(
            depositor,
            _urTokenAddress,
            currentTimePeriodCount,
            _amount
        );
    }

    function burnAndUnprotect(
        address _urTokenAddress,
        uint256 _amount,
        bool _quantumVerified,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) external {
        address withdrawer = msg.sender;

        if (!isSignKeySet(withdrawer)) revert SignKeyNotSet();
        if (_quantumVerified && !isQuantumProtected(withdrawer))
            revert QuantumNotSet();
        if (
            !verifyLogin(
                withdrawer,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            )
        ) revert SignKeyIncorrect();
        if (!isAllowedurToken(_urTokenAddress)) revert InvalidurToken();

        uint256 balance = IurToken(_urTokenAddress).balanceOf(withdrawer);
        if (!(_amount > 0)) revert InvalidAmount();
        if (!(balance >= _amount)) revert InvalidAmount();

        if (!IurToken(_urTokenAddress).burnAndUnprotect(withdrawer, _amount))
            revert WithdrawFailed();

        if (_urTokenAddress == urTokenAddressOfETH) {
            payable(withdrawer).transfer(_amount);
        } else {
            IERC20(getTokenAddressForurToken(_urTokenAddress)).transfer(
                withdrawer,
                _amount
            );
        }

        emit BurnAndUnprotect(withdrawer, _urTokenAddress, _amount);
    }

    function transfer(
        address _urTokenAddress,
        address _to,
        uint256 _amount,
        bool _quantumVerified,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) external returns (bool) {
        address caller = msg.sender;

        if (!isSignKeySet(caller)) revert SignKeyNotSet();
        if (_quantumVerified && !isQuantumProtected(caller))
            revert QuantumNotSet();
        if (
            !verifyLogin(
                caller,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            )
        ) revert SignKeyIncorrect();
        if (!(_amount > 0)) revert InvalidAmount();
        if (!isAllowedurToken(_urTokenAddress)) revert InvalidurToken();

        IurToken(_urTokenAddress).transfer(_to, _amount);
        return true;
    }

    function setMasterKeyAndSignKey(
        string memory _masterKey,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) external {
        address caller = msg.sender;
        if (isSignKeySet(caller) && isMasterKeySet(caller)) revert SignKeySet();

        setMasterKey(caller, _masterKey);
        register(
            caller,
            false,
            false,
            _customMessage,
            _signKeyHash,
            _deadline,
            _ethSignature,
            "",
            ""
        );
        setSignKey(caller, false);
    }

    function setMasterKeyAndQuantumResistantSignKey(
        string memory _masterKey,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature,
        bytes memory _quantumSignature,
        bytes memory _quamtumPublicKey
    ) external payable {
        address caller = msg.sender;
        uint256 fee = msg.value;
        uint256 requiredETHFee = calculateETHFee(quantumActivationFee);
        if (!(msg.value >= requiredETHFee)) revert InvalidAmount();

        uint256 thirtyPercentShare = (fee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
            100_000;
        payable(ur369gift_30).transfer(thirtyPercentShare);
        payable(ur369_30).transfer(thirtyPercentShare);
        payable(ur369impact_30).transfer(thirtyPercentShare);
        payable(ur369devs_10).transfer(fee - (thirtyPercentShare * 3));

        if (isSignKeySet(caller) && isMasterKeySet(caller)) revert SignKeySet();

        setMasterKey(caller, _masterKey);
        register(
            caller,
            true,
            false,
            _customMessage,
            _signKeyHash,
            _deadline,
            _ethSignature,
            _quantumSignature,
            _quamtumPublicKey
        );
        setSignKey(caller, true);
    }

    function enableQuantumKey(
        string memory _masterKey,
        string memory _customMessage,
        bytes32 _newSignKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature,
        bytes memory _quantumSignature,
        bytes memory _quamtumPublicKey
    ) external payable {
        address caller = msg.sender;
        if (!(isSignKeySet(caller) && isMasterKeySet(caller)))
            revert UserNotRegistered();
        if (!isMasterKeyCorrect(caller, _masterKey))
            revert MasterKeyIncorrect();

        if (isQuantumProtected(caller)) {
            register(
                caller,
                true,
                false,
                _customMessage,
                _newSignKeyHash,
                _deadline,
                _ethSignature,
                _quantumSignature,
                _quamtumPublicKey
            );
            emit SignKeyChanged(caller, block.timestamp, true);
        } else {
            register(
                caller,
                false,
                false,
                _customMessage,
                _newSignKeyHash,
                _deadline,
                _ethSignature,
                "",
                ""
            );
            emit SignKeyChanged(caller, block.timestamp, false);
        }
    }

    function changeSignKeyType(
        string memory _masterKey,
        string memory _customMessage,
        bytes32 _newSignKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature,
        bytes memory _quantumSignature,
        bytes memory _quamtumPublicKey
    ) external payable {
        address caller = msg.sender;
        if (isQuantumProtected(caller)) revert AlreadyQuantomProtected();
        if (!(isSignKeySet(caller) && isMasterKeySet(caller)))
            revert UserNotRegistered();
        if (!isMasterKeyCorrect(caller, _masterKey))
            revert MasterKeyIncorrect();

        uint256 fee = msg.value;
        uint256 requiredETHFee = calculateETHFee(quantumActivationFee);
        if (!(msg.value >= requiredETHFee)) revert InvalidAmount();

        uint256 thirtyPercentShare = (fee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
            100_000;
        payable(ur369gift_30).transfer(thirtyPercentShare);
        payable(ur369_30).transfer(thirtyPercentShare);
        payable(ur369impact_30).transfer(thirtyPercentShare);
        payable(ur369devs_10).transfer(fee - (thirtyPercentShare * 3));

        register(
            caller,
            true,
            true,
            _customMessage,
            _newSignKeyHash,
            _deadline,
            _ethSignature,
            _quantumSignature,
            _quamtumPublicKey
        );
        emit SignKeyChanged(caller, block.timestamp, true);
        setSignKey(caller, true);
    }

    //--------------------Read Functions -------------------------------//

    struct DepositsOfUser {
        address urTokenAddress;
        uint256 amount;
    }

    function getDepositDetailsForUser(
        address _depositor
    ) public view returns (DepositsOfUser[] memory depositDetails) {
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

    function getCurrentRecipientCandidateFor369Days()
        public
        view
        returns (address)
    {
        uint256 previousTimePeriod = ((block.timestamp - deployTime) /
            rewardTimeLimitFor369Days);

        if (previousTimePeriod == 0) return address(0);

        address[] memory depositors = getAllDepositorsInSystem();
        uint256 depositorsLength = depositors.length;

        if (depositorsLength == 0) return address(0);

        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(previousTimePeriod, deployTime))
        ) % depositorsLength;

        return depositors[randomNumber];
    }

    /**
     * @dev A struct that holds details about a user's deposit details for a specific period.
     *
     * @param urTokenAddress The address of the urToken in which the deposit was made.
     * @param amount The amount deposited in the urToken.
     */
    struct DepositsForPeriodOfUser {
        address urTokenAddress;
        uint256 amount;
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
    ) public view returns (DepositsForPeriodOfUser[] memory depositDetails) {
        address[]
            memory totalurTokens = getDepositedurTokensOfUserForPeriodFor369hours(
                _depositor
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

    // Checks whether the entered signKey matches the one associated with the user address.
    // The stored signKey is hashed for security reasons, so the entered signKey is hashed
    // and compared with the stored hashed signKey.

    function isSignKeyCorrect(
        address _user,
        bytes32 _signkeyHash
    ) public view returns (bool) {
        return passwordDataOf[_user].keccakHash == _signkeyHash;
    }

    // Similar to the signKey check function, this function checks whether the entered masterKey matches the one associated with the user address.
    function isMasterKeyCorrect(
        address _user,
        string memory _masterKey
    ) public view returns (bool) {
        return (_masterKeyOf[_user] == keccak256(bytes(_masterKey)));
    }

    // Checks whether a signKey has been set for the user address.
    function isSignKeySet(address _user) public view returns (bool) {
        return _isSignKeySetOf[_user];
    }

    // check whether a user is quantum protected or not
    function isQuantumProtected(address _user) public view returns (bool) {
        return _isQuantumProtected[_user];
    }

    // Checks whether a masterKey has been set for the user address.
    // Returns a boolean value that is true if a masterKey is set, and false otherwise.
    function isMasterKeySet(address _user) public view returns (bool) {
        return _isMasterKeySetOf[_user];
    }

    // Checks whether a deposit has been made in a specific period.
    // Returns a boolean value that is true if a deposit was made in the period, and false otherwise.
    function IsDepositedInPeriod(uint256 _period) public view returns (bool) {
        return isDepositedInPeriod[_period];
    }

    // Retrieves an array of tokens that were deposited within the given period.
    // The return is an array of addresses, where each address represents a token contract.
    function getTokensDepositedByPeriod(
        uint256 _period
    ) public view returns (address[] memory tokens) {
        return tokensByPeriod[_period].values();
    }

    // Retrieves the count of unique tokens that were deposited within the given period.
    // The return is an integer representing the number of unique token contracts.
    function getTokensDepositedByPeriodCount(
        uint256 _period
    ) public view returns (uint256) {
        return tokensByPeriod[_period].length();
    }

    // Retrieves an array of addresses that made a deposit within the given period.
    // The return is an array of addresses, where each address represents a unique depositor.
    function getDepositorsByPeriodFor369hours(
        uint256 _period
    ) public view returns (address[] memory depositors) {
        return depositorsByPeriod[_period].values();
    }

    // Retrieves the count of unique depositors that made a deposit within the given period.
    // The return is an integer representing the number of unique depositors.
    function getDepositorsByPeriodCountFor369hours(
        uint256 _period
    ) public view returns (uint256) {
        return depositorsByPeriod[_period].length();
    }

    // Retrieves the total amount of Ether that was deposited within the given period.
    // The return is an integer representing the amount of Ether in wei.
    function getETHInPeriod(uint256 _period) public view returns (uint256) {
        return ETHInPeriod[_period];
    }

    // Retrieves the reward amount associated with a specific token during a given period.
    // The function returns an integer representing the reward amount for the specific token in the provided period.
    function getRewardAmountOfTokenInPeriod(
        uint256 _period,
        address _token
    ) public view returns (uint256) {
        return totalRewardAmountForTokenInPeriod[_period][_token];
    }

    // Calculates and returns the current period based on the timestamp of the block, the deploy time of the contract, and the time limit for a reward.
    // The function returns an integer representing the current period for 369 hours.
    function getCurrentPeriodFor369hours() public view returns (uint256) {
        return
            ((block.timestamp - deployTime) / rewardTimeLimitFor369Hours) + 1;
    }

    // The function returns an integer representing the current period for 369 days.
    function getCurrentPeriodFor369days() public view returns (uint256) {
        return ((block.timestamp - deployTime) / rewardTimeLimitFor369Days) + 1;
    }

    // Calculates and returns the previous period based on the timestamp of the block, the deploy time of the contract, and the time limit for a reward.
    // The function returns an integer representing the previous period for 369 hours.
    function getPreviousPeriodFor369Hours() public view returns (uint256) {
        return ((block.timestamp - deployTime) / rewardTimeLimitFor369Hours);
    }

    function getPreviousPeriodFor369days() public view returns (uint256) {
        return ((block.timestamp - deployTime) / rewardTimeLimitFor369Days);
    }

    // Calculates and returns the start and end times for the current period.
    // The function returns two timestamps: the start time and end time of the current period.
    // If the current period is the first one, the start time is the deployment time of the contract,
    // and the end time is the start time plus the duration of the reward period.
    // For all subsequent periods, the start time is calculated by adding the duration of the reward period multiplied by
    // (current period - 1) to the deployment time of the contract.
    // The end time is the duration of the reward period added to the start time.
    function getCurrentPeriodStartAndEndTimeFor369hours()
        public
        view
        returns (uint256 startTime, uint256 endTime)
    {
        uint256 currentTimePeriod_for369hours = getCurrentPeriodFor369hours();

        if (currentTimePeriod_for369hours == 1) {
            startTime = deployTime;
            endTime = deployTime + rewardTimeLimitFor369Hours;
        } else {
            startTime =
                deployTime +
                (rewardTimeLimitFor369Hours *
                    (currentTimePeriod_for369hours - 1));
            endTime = rewardTimeLimitFor369Hours + startTime;
        }
    }

    function getCurrentPeriodStartAndEndTimeFor369days()
        public
        view
        returns (uint256 startTime, uint256 endTime)
    {
        uint256 currentTimePeriod_for369days = getCurrentPeriodFor369days();

        if (currentTimePeriod_for369days == 1) {
            startTime = deployTime;
            endTime = deployTime + rewardTimeLimitFor369Days;
        } else {
            startTime =
                deployTime +
                (rewardTimeLimitFor369Days *
                    (currentTimePeriod_for369days - 1));
            endTime = rewardTimeLimitFor369Days + startTime;
        }
    }

    // Determines and returns the current recipient candidate.
    // The function calculates the previous time period based on the block timestamp, contract deployment time, and the reward time limit.
    // It then retrieves the list of depositors for the previous time period and the count of these depositors.
    // If there are no depositors in the list, it returns the zero address.
    // Otherwise, it generates a random number using the keccak256 hash function with inputs as the previous time period and deployment time.
    // The modulus operator (%) is used to ensure the random number falls within the range of indices of the depositors array.
    // Finally, it returns the depositor at the index corresponding to the random number, hence determining the current winner.
    function getCurrentRecipientCandidateFor369Hours()
        public
        view
        returns (address)
    {
        uint256 previousTimePeriod = ((block.timestamp - deployTime) /
            rewardTimeLimitFor369Hours);

        address[] memory depositors = getDepositorsByPeriodFor369hours(
            previousTimePeriod
        );
        uint256 depositorsLength = getDepositorsByPeriodCountFor369hours(
            previousTimePeriod
        );

        if (depositorsLength == 0) return address(0);

        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(previousTimePeriod, deployTime))
        ) % depositorsLength;

        return depositors[randomNumber];
    }

    // Retrieves the cumulative reward history for Ether.
    // The function gets the previous period and then checks if the reward for that period has been collected.
    // If not, it adds the Ether amount of the period to the `ethHistory` variable.
    // This process continues for all previous periods until it reaches a period where the reward has been collected or period 0,
    // effectively summing up all uncollected Ether rewards.
    // The function returns the cumulative Ether reward history as a single integer value.
    function rewardHistoryForETHFor369Hours()
        public
        view
        returns (uint256 ethHistory)
    {
        uint256 period = getPreviousPeriodFor369Hours();
        while (!hasRewardBeenCollectedForPeriod[period]) {
            ethHistory += getETHInPeriod(period);
            if (period == 0) break;
            period--;
        }
    }

    // Checks if the reward for a specified period has been collected.
    // The function takes a period number as an input and checks the corresponding value in the `hasRewardBeenCollectedForPeriod` mapping.
    // If the reward for that period has been collected, the function returns true; otherwise, it returns false.
    function hasRewardBeenCollectedForPeriodFor369hours(
        uint256 _period
    ) public view returns (bool) {
        return hasRewardBeenCollectedForPeriod[_period];
    }

    // Struct to represent reward against a specific token
    struct RewardAgainstToken {
        address token;
        uint256 amount;
    }

    /**
     * @notice Returns the reward history for tokens for a specific period.
     * @param _period The period for which to fetch the reward history.
     * @return record An array of `RewardAgainstToken` structs representing the reward history for each token for the given period.
     */
    function rewardHistoryForTokensForPeriod(
        uint256 _period
    ) public view returns (RewardAgainstToken[] memory record) {
        address[] memory _tokens = getTokensDepositedByPeriod(_period);
        uint256 _tokensCount = _tokens.length;
        record = new RewardAgainstToken[](_tokensCount);
        if (_tokensCount > 0) {
            for (uint256 i; i < _tokensCount; i++) {
                record[i] = RewardAgainstToken({
                    token: _tokens[i],
                    amount: getRewardAmountOfTokenInPeriod(_period, _tokens[i])
                });
            }
        }
    }

    /**
     * @notice Returns a list of periods for which the rewards are pending.
     * @return pendingPeriods An array of periods where rewards are yet to be collected.
     */
    function pendingPeriodsForReward()
        public
        view
        returns (uint256[] memory pendingPeriods)
    {
        uint256 period = getPreviousPeriodFor369Hours();
        uint256[] memory _pendingPeriods = new uint256[](period);
        uint256 count;
        while (!hasRewardBeenCollectedForPeriodFor369hours(period)) {
            if (!isDepositedInPeriod[period]) {
                if (period == 0) break;
                period--;
                continue;
            }
            _pendingPeriods[count++] = period;
            if (period == 0) break;
            period--;
        }

        pendingPeriods = new uint256[](count);
        uint256 _count;
        for (uint256 i; i < _pendingPeriods.length; i++) {
            if (_pendingPeriods[i] > 0) {
                pendingPeriods[_count++] = _pendingPeriods[i];
            }
        }
        // checking
    }

    /**
     * @notice Returns a list of all whitelisted addresses.
     * @return _whiteListAddresses An array of all addresses that are whitelisted.
     */
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
