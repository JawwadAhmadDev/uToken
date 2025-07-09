//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ur369Fractal is Ownable {
    address public immutable u369gifthAddress_30 =
        0xBe9ECB5353A3Db50DE7d50d7B85986D8c3A845A1; // 30%
    address public immutable u369impactAddress_30 =
        0x822dbBB741B82d9f8c6F22Cb414b735817cd42EA; // 30%
    address public immutable u369Address_30 =
        0xcE14e3556FF59C83F849D0a4082258000FA23D30; // 30%
    address public immutable u369devsncomAddress_10 =
        0x29817e172E0d798dCc052f87a486fEd529c015C3; // 10%

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
