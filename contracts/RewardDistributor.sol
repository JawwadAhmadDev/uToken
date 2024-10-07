//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardDistributor is Ownable {
    address public immutable u369Address_30 =
        0x4B7C3C9b2D4aC50969f9A7c1b3BbA490F9088fE7; // 30%
    address public immutable u369gifthAddress_30 =
        0x7B95e28d8B4Dd51663b221Cd911d38694F90D196; // 30%
    address public immutable u369impactAddress_30 =
        0x4A058b1848d01455daedA203aCFaA11D2B133206; // 30%
    address public immutable u369devsncomAddress_10 =
        0xBeB63FCd4f767985eb535Cd5276103e538729E47; // 10%

    constructor() Ownable(msg.sender) {}

    function distributeEth() external payable onlyOwner {
        uint256 nativeCurrency = msg.value;

        if (nativeCurrency > 0) {
            uint256 thirtyPercent = (nativeCurrency * 30) / 100;
            uint256 remaining = nativeCurrency - (thirtyPercent * 3);

            payable(u369gifthAddress_30).transfer(thirtyPercent); // 30%
            payable(u369impactAddress_30).transfer(thirtyPercent); // 30%
            payable(u369Address_30).transfer(thirtyPercent); // 30%
            payable(u369devsncomAddress_10).transfer(remaining); // 10%
        }
    }

    function distributeERC20(
        address[] memory tokenAddresses,
        uint256[] memory amounts
    ) external onlyOwner {
        address sender = msg.sender;
        // Distribute ERC20 tokens
        require(
            tokenAddresses.length == amounts.length,
            "RewardDistributor: Amount for each token in not entered"
        );
        for (uint i = 0; i < tokenAddresses.length; i++) {
            uint256 amountToDistribute = amounts[i];
            address tokenAddress = tokenAddresses[i];

            require(
                amountToDistribute > 0,
                "RewardDistributor: Invalid amount"
            );

            uint256 thirtyPercent = (amountToDistribute * 30) / 100;
            uint256 remaining = amountToDistribute - (thirtyPercent * 3);

            require(
                IERC20(tokenAddress).transferFrom(
                    sender,
                    u369gifthAddress_30,
                    thirtyPercent
                ),
                "RewardDistributor: TransferFrom Failed."
            ); // 30%
            require(
                IERC20(tokenAddress).transferFrom(
                    sender,
                    u369impactAddress_30,
                    thirtyPercent
                ),
                "RewardDistributor: TransferFrom Failed."
            ); // 30%
            require(
                IERC20(tokenAddress).transferFrom(
                    sender,
                    u369Address_30,
                    thirtyPercent
                ),
                "RewardDistributor: TransferFrom Failed."
            ); // remaining
            require(
                IERC20(tokenAddress).transferFrom(
                    sender,
                    u369devsncomAddress_10,
                    remaining
                ),
                "RewardDistributor: TransferFrom Failed."
            ); // 10%
        }
    }

    function donateAndDistribute() external payable {
        uint256 nativeCurrency = msg.value;

        if (nativeCurrency > 0) {
            uint256 thirtyPercent = (nativeCurrency * 30) / 100;
            uint256 remaining = nativeCurrency - (thirtyPercent * 3);

            payable(u369gifthAddress_30).transfer(thirtyPercent); // 30%
            payable(u369impactAddress_30).transfer(thirtyPercent); // 30%
            payable(u369Address_30).transfer(thirtyPercent); // 30%
            payable(u369devsncomAddress_10).transfer(remaining); // 10%
        }
    }

    function donateAndDistributeERC20(
        address tokenAddress,
        uint256 _amount
    ) external {
        require(_amount != 0, "RewardDistributor: Invalid Amount");
        address sender = msg.sender;

        uint256 thirtyPercent = (_amount * 30) / 100;
        uint256 remaining = _amount - (thirtyPercent * 3);

        require(
            IERC20(tokenAddress).transferFrom(
                sender,
                u369gifthAddress_30,
                thirtyPercent
            ),
            "RewardDistributor: TransferFrom Failed."
        ); // 30%
        require(
            IERC20(tokenAddress).transferFrom(
                sender,
                u369impactAddress_30,
                thirtyPercent
            ),
            "RewardDistributor: TransferFrom Failed."
        ); // 30%
        require(
            IERC20(tokenAddress).transferFrom(
                sender,
                u369Address_30,
                thirtyPercent
            ),
            "RewardDistributor: TransferFrom Failed."
        ); // remaining
        require(
            IERC20(tokenAddress).transferFrom(
                sender,
                u369devsncomAddress_10,
                remaining
            ),
            "RewardDistributor: TransferFrom Failed."
        ); // 10%
    }
}
