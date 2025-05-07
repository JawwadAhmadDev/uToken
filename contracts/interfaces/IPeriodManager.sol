// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPeriodManager {
    struct RewardAgainstToken {
        address token;
        uint256 amount;
    }

    // View functions
    function getCurrentPeriodFor369hours() external view returns (uint256);

    function getCurrentPeriodFor369days() external view returns (uint256);

    function getPreviousPeriodFor369Hours() external view returns (uint256);

    function getPreviousPeriodFor369days() external view returns (uint256);

    function getCurrentPeriodStartAndEndTimeFor369hours()
        external
        view
        returns (uint256 startTime, uint256 endTime);

    function getCurrentPeriodStartAndEndTimeFor369days()
        external
        view
        returns (uint256 startTime, uint256 endTime);

    function getCurrentRecipientCandidateFor369Hours()
        external
        view
        returns (address);

    function getDepositorsByPeriodFor369hours(
        uint256 _period
    ) external view returns (address[] memory);

    function getDepositorsByPeriodCountFor369hours(
        uint256 _period
    ) external view returns (uint256);

    function getTokensDepositedByPeriod(
        uint256 _period
    ) external view returns (address[] memory);

    function getTokensDepositedByPeriodCount(
        uint256 _period
    ) external view returns (uint256);

    function getETHInPeriod(uint256 _period) external view returns (uint256);

    function getRewardAmountOfTokenInPeriod(
        uint256 _period,
        address _token
    ) external view returns (uint256);

    function hasRewardBeenCollectedForPeriodFor369hours(
        uint256 _period
    ) external view returns (bool);

    function isDepositedInPeriodFor369hours(
        uint256 _period
    ) external view returns (bool);

    function rewardHistoryForETHFor369Hours() external view returns (uint256);

    function rewardHistoryForTokensForPeriod(
        uint256 _period
    ) external view returns (RewardAgainstToken[] memory);

    function pendingPeriodsForReward() external view returns (uint256[] memory);

    // Internal functions (these will be implemented in the contract but not exposed in the interface)
    function addDepositorToPeriod(uint256 _period, address _depositor) external;

    function addTokenToPeriod(uint256 _period, address _token) external;

    function addETHToPeriod(uint256 _period, uint256 _amount) external;

    function addTokenRewardToPeriod(
        uint256 _period,
        address _token,
        uint256 _amount
    ) external;

    function markPeriodAsDeposited(uint256 _period) external;

    function markPeriodAsCollected(uint256 _period) external;
}
