//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract RewardDistributor {
    address public owner;

    address public immutable u369Address_30 = 0x7c81e517C256666A57424969038b6E91238e798D;        // 30%
    address public immutable u369gifthAddress_30 = 0x908640438eE0cBc982E62355f119DCf86F9C7752;   // 30%
    address public immutable u369impactAddress_30 = 0x2568C2F2E66cB20D8392bdBad7B93A02Afe3E803;  // 30%
    address public immutable u369devsncomAddress_10 = 0xCC18F97a8f88Ae469F4729DC414EF51Cac7550F0;// 10%


    constructor() {
        owner = msg.sender; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function distributeEth() external payable onlyOwner {
        uint256 nativeCurrency = msg.value;

        if (nativeCurrency > 0) {
            uint256 thirtyPercent = nativeCurrency * 30 / 100;
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
        require(tokenAddresses.length == amounts.length, "RewardDistributor: Amount for each token in not entered");
        for(uint i = 0; i < tokenAddresses.length; i++){
            uint256 amountToDistribute = amounts[i];
            address tokenAddress = tokenAddresses[i];
            
            require(amountToDistribute > 0, "RewardDistributor: Invalid amount");

            uint256 thirtyPercent = amountToDistribute * 30 / 100;
            uint256 remaining = amountToDistribute - (thirtyPercent * 3);

            require(IERC20(tokenAddress).transferFrom(sender, u369gifthAddress_30, thirtyPercent), "RewardDistributor: TransferFrom Failed.");  // 30%
            require(IERC20(tokenAddress).transferFrom(sender, u369impactAddress_30, thirtyPercent), "RewardDistributor: TransferFrom Failed.");   // 30%
            require(IERC20(tokenAddress).transferFrom(sender, u369Address_30, thirtyPercent), "RewardDistributor: TransferFrom Failed.");            // remaining
            require(IERC20(tokenAddress).transferFrom(sender, u369devsncomAddress_10, remaining), "RewardDistributor: TransferFrom Failed.");    // 10%
        }    
    }

    function donate(address tokenAddress, uint256 _amount) external {
        require(_amount != 0, "RewardDistributor: Invalid Amount");
        address sender = msg.sender;

        uint256 thirtyPercent = _amount * 30 / 100;
        uint256 remaining = _amount - (thirtyPercent * 3);

        require(IERC20(tokenAddress).transferFrom(sender, u369gifthAddress_30, thirtyPercent), "RewardDistributor: TransferFrom Failed.");  // 30%
        require(IERC20(tokenAddress).transferFrom(sender, u369impactAddress_30, thirtyPercent), "RewardDistributor: TransferFrom Failed.");   // 30%
        require(IERC20(tokenAddress).transferFrom(sender, u369Address_30, thirtyPercent), "RewardDistributor: TransferFrom Failed.");            // remaining
        require(IERC20(tokenAddress).transferFrom(sender, u369devsncomAddress_10, remaining), "RewardDistributor: TransferFrom Failed.");    // 10%
    }
}