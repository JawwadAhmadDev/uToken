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
}
