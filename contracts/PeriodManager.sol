// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PeriodManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public rewardTimeLimitFor369Hours = 129600; // 369 hours
    uint256 public rewardTimeLimitFor369Days = 31881600; // 369 days
    uint256 public deployTime;

    mapping(uint256 => EnumerableSet.AddressSet) private depositorsByPeriod;
    mapping(uint256 => EnumerableSet.AddressSet) private tokensByPeriod;
    mapping(uint256 => uint256) private ETHInPeriod;
    mapping(uint256 => mapping(address => uint256))
        private totalRewardAmountForTokenInPeriod;
    mapping(uint256 => bool) private hasRewardBeenCollectedForPeriod;
    mapping(uint256 => bool) private isDepositedInPeriod;

    constructor() {
        deployTime = block.timestamp;
    }

    function addDepositorToPeriod(
        uint256 _period,
        address _depositor
    ) internal {
        if (!depositorsByPeriod[_period].contains(_depositor)) {
            depositorsByPeriod[_period].add(_depositor);
        }
    }

    function addTokenToPeriod(uint256 _period, address _token) internal {
        if (!tokensByPeriod[_period].contains(_token)) {
            tokensByPeriod[_period].add(_token);
        }
    }

    function addETHToPeriod(uint256 _period, uint256 _amount) internal {
        ETHInPeriod[_period] += _amount;
    }

    function addTokenRewardToPeriod(
        uint256 _period,
        address _token,
        uint256 _amount
    ) internal {
        totalRewardAmountForTokenInPeriod[_period][_token] += _amount;
    }

    function markPeriodAsDeposited(uint256 _period) internal {
        isDepositedInPeriod[_period] = true;
    }

    function markPeriodAsCollected(uint256 _period) internal {
        hasRewardBeenCollectedForPeriod[_period] = true;
    }

    function getCurrentPeriodFor369hours() public view returns (uint256) {
        return
            ((block.timestamp - deployTime) / rewardTimeLimitFor369Hours) + 1;
    }

    function getCurrentPeriodFor369days() public view returns (uint256) {
        return ((block.timestamp - deployTime) / rewardTimeLimitFor369Days) + 1;
    }

    function getPreviousPeriodFor369Hours() public view returns (uint256) {
        return ((block.timestamp - deployTime) / rewardTimeLimitFor369Hours);
    }

    function getPreviousPeriodFor369days() public view returns (uint256) {
        return ((block.timestamp - deployTime) / rewardTimeLimitFor369Days);
    }

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

    function getDepositorsByPeriodFor369hours(
        uint256 _period
    ) public view returns (address[] memory) {
        return depositorsByPeriod[_period].values();
    }

    function getDepositorsByPeriodCountFor369hours(
        uint256 _period
    ) public view returns (uint256) {
        return depositorsByPeriod[_period].length();
    }

    function getTokensDepositedByPeriod(
        uint256 _period
    ) public view returns (address[] memory) {
        return tokensByPeriod[_period].values();
    }

    function getTokensDepositedByPeriodCount(
        uint256 _period
    ) public view returns (uint256) {
        return tokensByPeriod[_period].length();
    }

    function getETHInPeriod(uint256 _period) public view returns (uint256) {
        return ETHInPeriod[_period];
    }

    function getRewardAmountOfTokenInPeriod(
        uint256 _period,
        address _token
    ) public view returns (uint256) {
        return totalRewardAmountForTokenInPeriod[_period][_token];
    }

    function hasRewardBeenCollectedForPeriodFor369hours(
        uint256 _period
    ) public view returns (bool) {
        return hasRewardBeenCollectedForPeriod[_period];
    }

    function isDepositedInPeriodFor369hours(
        uint256 _period
    ) public view returns (bool) {
        return isDepositedInPeriod[_period];
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
    }
}
