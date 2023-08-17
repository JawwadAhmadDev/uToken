// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "IERC20.sol";
import "uToken.sol";

pragma solidity ^0.8.18;

contract uTokenFactory is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // uToken -> Token Address (against which contract is deployed)
    mapping(address => address) private tokenAdressOf_uToken;
    mapping(address => string) private currencyOf_uToken;
    // token -> uToken
    mapping(address => address) private uTokenAddressOf_token;

    // Investment details of specific user.
    // investorAddress -> All uTokens addresses invested in
    mapping(address => EnumerableSet.AddressSet) private investeduTokensOf;
    // investorAddress -> period -> All uTokens addresses
    mapping(address => mapping(uint256 => EnumerableSet.AddressSet))
        private investeduTokens_OfUser_ForPeriod;
    // investor -> uTokenaddress -> period -> totalInvestment
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private investedAmount_OfUser_AgainstuTokens_ForPeriod;

    // (period count i.e. how much 15 days passed) => depositors addresses.
    mapping(uint256 => EnumerableSet.AddressSet) private depositorsInPeriod;
    // (period count i.e. how much 15 days passed) => depositedTokens address
    mapping(uint256 => EnumerableSet.AddressSet) private tokensInPeriod;
    // (period count i.e. how much 15 days passed) => deposited Ethers in the this period
    mapping(uint256 => uint256) private ethInPeriod;
    // (period count) => tokenAddress => totalInvestedAmount
    mapping(uint256 => mapping(address => uint))
        private rewardAmountOfTokenForPeriod;
    // (period count) => boolean
    mapping(uint256 => bool) private isRewardCollectedOfPeriod;
    // period count => boolean (to check that in which period some investment is made.
    mapping(uint256 => bool) private isDepositedInPeriod;

    // mappings to store password and randomly generated phrase against user.
    mapping(address => bytes32) private _passwordOf;
    mapping(address => bool) private _isPasswordSet;
    mapping(address => bytes32) private _recoveryNumberOf;
    mapping(address => bool) private _isRecoveryNumberSet;

    // tokens addresses.
    address public deployedAddressOfEth;
    EnumerableSet.AddressSet private allowedTokens; // total allowed ERC20 tokens
    EnumerableSet.AddressSet private uTokensOfAllowedTokens; // uTokens addresses of allowed ERC20 Tokens
    address[] private whiteListAddresses; // whitelist addresss set only once and will be send to all the deployed tokens.

    // salt for create2 opcode.
    uint256 private _salt; // to handle create2 opcode.

    // previous fee
    uint256 public pendingFee;

    // fee detial
    uint256 public depositFeePercent = 369; // 0.369 * 1000 = 369% of total deposited amount.
    uint256 public percentOfCharityWinnerAndFundAddress = 30_000; // 30 * 1000 = 30000% of 0.369% of deposited amount
    uint256 public percentOfForthAddress = 10_000; // 40 * 1000 = 40000% of 0.369% of deposited amount

    // time periods for reward
    uint256 public timeLimitForReward = 20;
    uint256 public timeLimitForRewardCollection = 10;
    uint256 public deployTime;

    // zoom to handle percentage in the decimals
    uint256 public constant ZOOM = 1_000_00; // actually 100. this is divider to calculate percentage

    // fee receiver addresses.
    address public fundAddress = 0x4B7C3C9b2D4aC50969f9A7c1b3BbA490F9088fE7; // address which will receive all fees
    address public charityAddress = 0x9317Dc1623d472a588DE7d1f471a79720600019d; // address which will receive share of charity.
    address public forthAddress = 0x7f450426ac73B2978393d31959Fe2f4d093DC646;
    address public rewardDistributer =
        0x7f450426ac73B2978393d31959Fe2f4d093DC646;

    event Deposit(
        address depositor,
        address token,
        uint256 period,
        uint256 amount
    );
    event Withdraw(address withdrawer, address token, uint256 amount);
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

    constructor(
        address[] memory _allowedTokens,
        address[] memory _whiteListAddressess
    ) {
        deployTime = block.timestamp;
        whiteListAddresses = _whiteListAddressess;

        deployedAddressOfEth = _deployEth();
        _addAllowedTokens(_allowedTokens);

        // setting whitelist addresses.
    }

    /**
     * @dev Function to deploy a new instance of uToken smart contract and initialize it.
     *
     * The function uses the Ethereum assembly language for optimized, low-level operations.
     * It uses the CREATE2 operation code (EVM opcode) to create a new smart contract on the blockchain, with a
     * predetermined address. The address depends on the sender, salt, and init code. The `create2` opcode provides
     * more control over the address of the newly created contract compared to the regular `create` (or CREATE1) opcode.
     *
     * `uToken.creationCode` is the bytecode used for deploying the uToken contract.
     *
     * Salt is a value used in the CREATE2 function to generate the new contract address. The salt in this function is
     * generated by hashing a continually incrementing number (_salt) using keccak256, which is the standard Ethereum hashing function.
     *
     * The deployed contract is then initialized by calling its `initialize` method. This sets the
     * name, symbol, underlying asset, and whitelist addresses of the token.
     *
     * @return deployedEth The address of the newly deployed uToken contract.
     */
    function _deployEth() internal returns (address deployedEth) {
        bytes memory bytecode = type(uToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedEth := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IuToken(deployedEth).initialize(
            "uMatic",
            "uMATIC",
            "Matic",
            whiteListAddresses
        );
    }

    /**
     * @dev Deploys a new instance of uToken for a given ERC20 token and initializes it.
     *
     * This function creates a new contract instance for any ERC20 token on the Ethereum blockchain,
     * with a name and symbol prefixed with 'u'. The address of the new contract is deterministic,
     * and depends on the sender, the salt, and the initialization code.
     *
     * @param _token The address of the ERC20 token for which the uToken needs to be deployed.
     *
     * @return deployedToken The address of the newly deployed uToken contract.
     *
     * Notes:
     *
     * 1) The `IERC20` interface is used to interact with the ERC20 token. It gets the name and symbol
     *    of the token, which are used to create a corresponding uToken with a prefixed name and symbol.
     *
     * 2) The salt is generated by hashing an incrementing number (_salt) using the keccak256 hashing function.
     *
     * 3) Ethereum's low-level assembly language is used for optimized operations.
     *    Specifically, the CREATE2 opcode is used to deploy the new uToken contract.
     *
     * 4) The `initialize` method of the new uToken contract is called to set its name, symbol,
     *    underlying asset symbol, and whitelist addresses.
     */
    function _deployToken(
        address _token
    ) internal returns (address deployedToken) {
        IERC20 __token = IERC20(_token);
        string memory name = string.concat("u", __token.name());
        string memory symbol = string.concat("u", __token.symbol());
        string memory currency = __token.symbol();

        bytes memory bytecode = type(uToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedToken := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        IuToken(deployedToken).initialize(
            name,
            symbol,
            currency,
            whiteListAddresses
        );
    }

    /**
     * @dev Adds an array of token addresses to the list of allowed tokens and deploys uToken for each.
     *
     * This function iterates through the array of input addresses, checks if each address corresponds to a contract,
     * checks if it's not already in the list of allowed tokens, deploys a uToken for it, and updates the corresponding
     * mappings and sets.
     *
     * @param _allowedTokens An array of addresses representing the ERC20 tokens to be allowed.
     *
     * NOTES:
     *
     * 1) The `isContract` function checks if a given address corresponds to a contract.
     *
     * 2) The `contains` function checks if the token is already in the `allowedTokens` set.
     *
     * 3) The `_deployToken` function deploys a new uToken contract for the given token.
     *
     * 4) `tokenAdressOf_uToken`, `uTokenAddressOf_token`, `currencyOf_uToken`, `allowedTokens`, and
     *    `uTokensOfAllowedTokens` are state variables (mappings or sets) that are updated for each token.
     *
     * require _token.isContract() Ensures the provided address corresponds to a contract.
     * require !(allowedTokens.contains(_token)) Ensures the token is not already in the allowedTokens set.
     */
    function _addAllowedTokens(address[] memory _allowedTokens) internal {
        for (uint i; i < _allowedTokens.length; i++) {
            address _token = _allowedTokens[i];
            require(
                _token.isContract(),
                "uTokenFactory: INVALID ALLOWED TOKEN ADDRESS"
            );
            require(
                !(allowedTokens.contains(_token)),
                "Factory: Already added"
            );
            address _deployedAddress = _deployToken(_token);
            tokenAdressOf_uToken[_deployedAddress] = _token;
            uTokenAddressOf_token[_token] = _deployedAddress;
            currencyOf_uToken[_deployedAddress] = IuToken(_deployedAddress)
                .currency();
            allowedTokens.add(_token);
            uTokensOfAllowedTokens.add(_deployedAddress);
        }
    }

    /**
     * @dev Adds an array of token addresses to the list of allowed tokens.
     *
     * This function is an external interface for `_addAllowedTokens` function and
     * can only be called by the contract owner, ensured by the `onlyOwner` modifier.
     *
     * @param _allowedTokens An array of addresses representing the ERC20 tokens to be allowed.
     *
     * require: Caller must be the contract's owner.
     */
    function addAllowedTokens(
        address[] memory _allowedTokens
    ) external onlyOwner {
        _addAllowedTokens(_allowedTokens);
    }

    /**
     * @dev Handles the depositing of tokens.
     *
     * This function allows the sender to deposit tokens into the contract. It verifies the password of the sender,
     * checks the deposited amount, verifies the token type, and then executes the deposit and divides up the deposit fee.
     *
     * @param _password The password of the depositor for verification.
     * @param _uTokenAddress The address of the token being deposited.
     * @param _amount The amount of the token being deposited.
     *
     * require: Caller's password must be set.
     * require: Caller's password must match the stored password.
     * require: Deposit amount must be greater than 0.
     * require: The token address must be valid.
     */
    function deposit(
        string memory _password,
        address _uTokenAddress,
        uint256 _amount
    ) external payable {
        address depositor = msg.sender;
        require(_isPasswordSet[depositor], "Factory: Password not set yet.");
        require(
            _passwordOf[depositor] == keccak256(bytes(_password)),
            "Factory: Password incorrect"
        );
        require(_amount > 0, "Factory: invalid amount");
        require(
            _uTokenAddress == deployedAddressOfEth ||
                uTokensOfAllowedTokens.contains(_uTokenAddress),
            "Factory: invalid uToken address"
        );
        uint256 _depositFee = _amount.mul(depositFeePercent).div(ZOOM);
        uint256 _remaining = _amount.sub(_depositFee);

        if (_uTokenAddress == deployedAddressOfEth) {
            require(msg.value > 0, "Factory: invalid Ether");
            // payable(fundAddress).transfer(_depositFee);
            _handleFeeEth(_depositFee);
        } else {
            require(
                IERC20(tokenAdressOf_uToken[_uTokenAddress]).transferFrom(
                    depositor,
                    address(this),
                    _amount
                ),
                "Factory: TransferFrom failed"
            );
            // require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(fundAddress, _depositFee), "Factory: transfer failed");
            _handleFeeTokens(tokenAdressOf_uToken[_uTokenAddress], _depositFee);
        }

        require(
            IuToken(_uTokenAddress).deposit(_remaining),
            "Factory: deposit failed"
        );
        if (!(investeduTokensOf[depositor].contains(_uTokenAddress)))
            investeduTokensOf[depositor].add(_uTokenAddress);

        uint256 _currentPeriod = get_CurrentPeriod();
        if (
            !(investeduTokens_OfUser_ForPeriod[depositor][_currentPeriod])
                .contains(_uTokenAddress)
        )
            investeduTokens_OfUser_ForPeriod[depositor][_currentPeriod].add(
                _uTokenAddress
            );
        investedAmount_OfUser_AgainstuTokens_ForPeriod[depositor][
            _uTokenAddress
        ][_currentPeriod] = investedAmount_OfUser_AgainstuTokens_ForPeriod[
            depositor
        ][_uTokenAddress][_currentPeriod].add(_remaining);
        emit Deposit(depositor, _uTokenAddress, _currentPeriod, _remaining);
    }

    /**
     * @dev Handles the deposit fee for Ethereum deposits.
     *
     * This function divides the deposit fee into the respective shares for the charity, winner, fund, and forth addresses.
     * It also checks and updates the depositors and deposited Ether amount for the current time period.
     *
     * @param _depositFee The amount of the deposit fee in Ether.
     */
    function _handleFeeEth(uint256 _depositFee) internal {
        uint256 thirtyPercentShare = _depositFee
            .mul(percentOfCharityWinnerAndFundAddress)
            .div(ZOOM);
        uint256 shareOfForthAddress = _depositFee
            .mul(percentOfForthAddress)
            .div(ZOOM);
        // uint256 shareOfWinnerAddress = thirtyPercentShare;
        // uint256 shareOfCharityAddress = thirtyPercentShare; // because winner and charity will receive same percentage.
        // uint256 shareOfFundAddress = thirtyPercentShare; // because winner and charity will receive same percentage.
        // uint256 shareOfForthAddress = _depositFee - (thirtyPercentShare * 3); // it will receive remaining 10% percent

        payable(rewardDistributer).transfer(thirtyPercentShare);
        payable(fundAddress).transfer(thirtyPercentShare);
        payable(charityAddress).transfer(thirtyPercentShare);
        payable(forthAddress).transfer(shareOfForthAddress);

        uint256 currentTimePeriodCount = ((block.timestamp - deployTime) /
            timeLimitForReward) + 1;
        if (!isDepositedInPeriod[currentTimePeriodCount])
            isDepositedInPeriod[currentTimePeriodCount] = true;

        if (
            !(depositorsInPeriod[currentTimePeriodCount].contains(msg.sender))
        ) {
            depositorsInPeriod[currentTimePeriodCount].add(msg.sender);
        }

        ethInPeriod[currentTimePeriodCount] = ethInPeriod[
            currentTimePeriodCount
        ].add(thirtyPercentShare);
    }

    /**
     * @dev Handles the deposit fee for token deposits.
     *
     * This function divides the deposit fee into the respective shares for the charity, winner, fund, and forth addresses.
     * It also checks and updates the depositors, deposited tokens, and reward amount for the current time period.
     *
     * @param _tokenAddress The address of the token being deposited.
     * @param _depositFee The amount of the deposit fee in tokens.
     */
    function _handleFeeTokens(
        address _tokenAddress,
        uint256 _depositFee
    ) internal {
        uint256 thirtyPercentShare = _depositFee
            .mul(percentOfCharityWinnerAndFundAddress)
            .div(ZOOM);
        uint256 shareOfForthAddress = _depositFee
            .mul(percentOfForthAddress)
            .div(ZOOM);
        // uint256 shareOfWinnerAddress = thirtyPercentShare;
        // uint256 shareOfCharityAddress = thirtyPercentShare; // because winner and charity will receive same percentage.
        // uint256 shareOfFundAddress = thirtyPercentShare; // because winner and charity will receive same percentage.
        // uint256 shareOfForthAddress = _depositFee - (thirtyPercentShare * 3); // it will receive remaining 10% percent

        IERC20(_tokenAddress).transfer(rewardDistributer, thirtyPercentShare);
        IERC20(_tokenAddress).transfer(fundAddress, thirtyPercentShare);
        IERC20(_tokenAddress).transfer(charityAddress, thirtyPercentShare);
        IERC20(_tokenAddress).transfer(forthAddress, shareOfForthAddress);

        uint256 currentTimePeriodCount = ((block.timestamp - deployTime) /
            timeLimitForReward) + 1;
        if (!isDepositedInPeriod[currentTimePeriodCount])
            isDepositedInPeriod[currentTimePeriodCount] = true;

        if (
            !(depositorsInPeriod[currentTimePeriodCount].contains(msg.sender))
        ) {
            depositorsInPeriod[currentTimePeriodCount].add(msg.sender);
        }
        if (!(tokensInPeriod[currentTimePeriodCount].contains(_tokenAddress))) {
            tokensInPeriod[currentTimePeriodCount].add(_tokenAddress);
        }
        rewardAmountOfTokenForPeriod[currentTimePeriodCount][
            _tokenAddress
        ] = rewardAmountOfTokenForPeriod[currentTimePeriodCount][_tokenAddress]
            .add(thirtyPercentShare);
    }

    /**
     * @dev Handles the withdrawal of tokens.
     *
     * This function allows the sender to withdraw tokens from the contract. It verifies the password of the sender,
     * checks the withdrawal amount, verifies the token type, and then executes the withdrawal.
     *
     * @param _password The password of the withdrawer for verification.
     * @param _uTokenAddress The address of the token being withdrawn.
     * @param _amount The amount of the token being withdrawn.
     *
     * require: Caller's password must be set.
     * require: Caller's password must match the stored password.
     * require: The token address must be valid.
     * require: Withdrawal amount must be greater than 0.
     * require: Caller's balance must be sufficient for the withdrawal.
     */
    function withdraw(
        string memory _password,
        address _uTokenAddress,
        uint256 _amount
    ) external {
        address withdrawer = msg.sender;
        require(_isPasswordSet[withdrawer], "Factory: Password not set yet.");
        require(
            _passwordOf[withdrawer] == keccak256(bytes(_password)),
            "Factory: Password incorrect"
        );
        require(
            _uTokenAddress == deployedAddressOfEth ||
                uTokensOfAllowedTokens.contains(_uTokenAddress),
            "Factory: invalid uToken address"
        );
        uint256 balance = IuToken(_uTokenAddress).balanceOf(withdrawer);
        require(_amount > 0, "Factory: invalid amount");
        require(balance >= _amount, "Factory: Not enought tokens");

        require(
            IuToken(_uTokenAddress).withdraw(_amount),
            "Factory: withdraw failed"
        );

        if (_uTokenAddress == deployedAddressOfEth) {
            payable(withdrawer).transfer(_amount);
        } else {
            require(
                IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(
                    withdrawer,
                    _amount
                ),
                "Factory: transfer failed"
            );
        }

        if (balance.sub(_amount) == 0) {
            investeduTokensOf[withdrawer].remove(_uTokenAddress);
            investeduTokens_OfUser_ForPeriod[withdrawer][get_CurrentPeriod()]
                .remove(_uTokenAddress);
        }

        emit Withdraw(withdrawer, _uTokenAddress, _amount);
    }

    /**
     * @dev Transfers tokens from the caller to the given address.
     *
     * This function allows the sender to transfer tokens to another address. It verifies the password of the sender,
     * checks the transfer amount, verifies the token type, and then executes the transfer. After successful transfer,
     * it adds the transferred token address to the receiver's list of tokens.
     *
     * @param _password The password of the sender for verification.
     * @param _uTokenAddress The address of the token being transferred.
     * @param _to The recipient's address.
     * @param _amount The amount of the token being transferred.
     *
     * @return true if the transfer is successful, throws an error otherwise.
     *
     * require: Caller's password must be set.
     * require: Caller's password must match the stored password.
     * require: The token address must be valid.
     * require: Transfer amount must be greater than 0.
     */
    function transfer(
        string memory _password,
        address _uTokenAddress,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        address caller = msg.sender;
        require(_isPasswordSet[caller], "Factory: Password not set yet.");
        require(
            _passwordOf[caller] == keccak256(bytes(_password)),
            "Factory: Password incorrect"
        );
        require(_amount > 0, "Factory: Invalid amount");
        require(
            _uTokenAddress == deployedAddressOfEth ||
                uTokensOfAllowedTokens.contains(_uTokenAddress),
            "Factory: invalid uToken address"
        );

        require(
            IuToken(_uTokenAddress).transfer(_to, _amount),
            "Factory, transfer failed"
        );
        investeduTokensOf[_to].add(_uTokenAddress);
        return true;
    }

    /**
     * @dev Allows a user to set their password and recovery number for the first time.
     *
     * This function sets the password and recovery number of the caller (msg.sender).
     * Both the password and recovery number are hashed for secure storage. The function
     * can only be called if neither the password nor the recovery number has been set before.
     *
     * @param _password The password provided by the user.
     * @param _recoveryNumber The recovery number provided by the user.
     *
     * require The password and recovery number for the caller should not have been set before.
     */
    function setPasswordAndRecoveryNumber(
        string memory _password,
        string memory _recoveryNumber
    ) external {
        address caller = msg.sender;
        require(
            (!(_isPasswordSet[caller]) && !(_isRecoveryNumberSet[caller])),
            "Factory: Already set"
        );
        _passwordOf[caller] = keccak256(bytes(_password));
        _recoveryNumberOf[caller] = keccak256(bytes(_recoveryNumber));
        _isPasswordSet[caller] = true;
        _isRecoveryNumberSet[caller] = true;
    }

    /**
     * @dev Allows a user to change their password using their recovery number.
     *
     * This function changes the password of the caller (msg.sender) after verifying their recovery number.
     * The new password is hashed for secure storage. This function can only be called if the user's recovery
     * number matches the one provided in the function argument.
     *
     * @param _recoveryNumber The recovery number provided by the user.
     * @param _password The new password provided by the user.
     *
     * require The recovery number provided should match the recovery number stored for the caller.
     */
    function changePassword(
        string memory _recoveryNumber,
        string memory _password
    ) external {
        address caller = msg.sender;
        require(
            _recoveryNumberOf[caller] == keccak256(bytes(_recoveryNumber)),
            "Factory: incorrect recovery number"
        );
        _passwordOf[caller] = keccak256(bytes(_password));
    }

    // function to change fund address. Only owner is authroized
    function changeFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }

    // function to change charity address. only owner is authroized.
    function changeCharityAddress(address _charityAddress) external onlyOwner {
        charityAddress = _charityAddress;
    }

    // function to change time limit for reward. only onwer is authorized.
    function changeTimeLimitForReward(uint256 _time) external onlyOwner {
        timeLimitForReward = _time;
    }

    // function to change time limit for reward collection. only owner is authorized.
    function changeTimeLimitForRewardCollection(
        uint256 _time
    ) external onlyOwner {
        timeLimitForRewardCollection = _time;
    }

    // function to withdrawReward for winner
    /**
     * @dev Allows the winner of the reward to withdraw it within a specific time limit.
     *
     * This function allows the winner to withdraw the reward in the form of Ether and tokens.
     * It iteratively checks the periods from current to the first one and withdraws the available
     * rewards if the winner hasn't already collected them. It keeps track of rewards collected for each period.
     * The function requires the caller to be the current winner and to withdraw within a specific time limit.
     *
     * @notice The function iterates over periods, thus the gas cost could increase with the number of periods.
     *
     * require: The caller of the function should be the current winner.
     * require: The function should be called within a specific time limit after the end of the period.
     *
     * emit: RewardOfETH An event emitted when Ether reward is collected for a specific period.
     * emit: RewardOfToken An event emitted when Token reward is collected for a specific period.
     */
    ////////////////////////////////////////////////////////////////
    // Commented out for now because reward is transferred to the
    // Fund Distributor account at the time of wrapping the tokens.
    ////////////////////////////////////////////////////////////////
    // function withdrawReward() external {
    //     require(get_currentWinner() == msg.sender, "You are not winner"); // check caller is winner or not

    //     // check whether user is coming within time limit
    //     uint256 endPointOfLimit = get_TimeLimitForWinnerForCurrentPeriod();
    //     uint256 startPointOfLimit = endPointOfLimit.sub(
    //         timeLimitForRewardCollection
    //     );
    //     require(
    //         block.timestamp > startPointOfLimit &&
    //             block.timestamp <= endPointOfLimit,
    //         "Time limit exceeded"
    //     );

    //     uint256 period = get_PreviousPeriod();
    //     while (!(isRewardCollectedOfPeriod[period])) {
    //         if (!isDepositedInPeriod[period]) {
    //             if (period == 1) break;
    //             period--;
    //             continue;
    //         }

    //         uint256 _ethInPeriod = get_ETHInPeriod(period);
    //         // uint256 _tokensCountInPeriod = get_TokensDepositedInPeriodCount(period);
    //         if (_ethInPeriod > 0) {
    //             payable(rewardDistributer).transfer(_ethInPeriod);
    //         }

    //         address[] memory _tokens = get_TokensDepositedInPeriod(period);
    //         uint256 _tokensCount = _tokens.length;
    //         if (_tokensCount > 0) {
    //             for (uint i; i < _tokensCount; i++) {
    //                 address _token = _tokens[i];
    //                 uint rewardAmountOfTokenInPeriod = get_rewardAmountOfTokenInPeriod(
    //                         period,
    //                         _token
    //                     );
    //                 IERC20(_token).transfer(
    //                     rewardDistributer,
    //                     rewardAmountOfTokenInPeriod
    //                 );
    //                 RewardOfToken(
    //                     rewardDistributer,
    //                     period,
    //                     _token,
    //                     rewardAmountOfTokenInPeriod
    //                 );
    //             }
    //         }

    //         isRewardCollectedOfPeriod[period] = true;
    //         emit RewardOfETH(rewardDistributer, period, _ethInPeriod);

    //         if (period == 1) break;
    //         period--;
    //     }
    // }

    //--------------------Read Functions -------------------------------//
    //--------------------Allowed Tokens -------------------------------//
    /**
     * @dev Returns the addresses of all allowed tokens.
     *
     * This function returns an array of the addresses of all tokens that are currently allowed.
     *
     * @return An array of addresses representing allowed tokens.
     */
    function all_AllowedTokens() public view returns (address[] memory) {
        return allowedTokens.values();
    }

    /**
     * @dev Returns the count of all allowed tokens.
     *
     * This function returns the total count of tokens that are currently allowed.
     *
     * @return A number representing the count of allowed tokens.
     */
    function all_AllowedTokensCount() public view returns (uint256) {
        return allowedTokens.length();
    }

    /**
     * @dev Returns the addresses of all uTokens of the allowed tokens.
     *
     * This function returns an array of the addresses of all uTokens that correspond to currently allowed tokens.
     *
     * @return An array of addresses representing uTokens of allowed tokens.
     */
    function all_uTokensOfAllowedTokens()
        public
        view
        returns (address[] memory)
    {
        return uTokensOfAllowedTokens.values();
    }

    /**
     * @dev Returns the count of all uTokens of the allowed tokens.
     *
     * This function returns the total count of uTokens that correspond to currently allowed tokens.
     *
     * @return A number representing the count of uTokens of allowed tokens.
     */
    function all_uTokensOfAllowedTokensCount() public view returns (uint256) {
        return uTokensOfAllowedTokens.length();
    }

    /**
     * @dev Returns the address of the token corresponding to the given uToken.
     *
     * This function takes the address of a uToken and returns the address of the corresponding token.
     *
     * @param _uToken The address of the uToken.
     *
     * @return The address of the token that corresponds to the given uToken.
     */
    function get_TokenAddressOfuToken(
        address _uToken
    ) public view returns (address) {
        return tokenAdressOf_uToken[_uToken];
    }

    /**
     * @dev Returns the address of the uToken corresponding to the given token.
     *
     * This function takes the address of a token and returns the address of the corresponding uToken.
     *
     * @param _token The address of the token.
     *
     * @return The address of the uToken that corresponds to the given token.
     */
    function get_uTokenAddressOfToken(
        address _token
    ) public view returns (address) {
        return uTokenAddressOf_token[_token];
    }

    /**
     * @dev Returns the addresses of all uTokens invested by a specific investor.
     *
     * This function takes the address of an investor and returns an array of addresses
     * representing all uTokens that the investor has invested in.
     *
     * @param _investor The address of the investor.
     *
     * @return investeduTokens An array of uToken addresses in which the investor has invested.
     */
    function getInvested_uTokensOfUser(
        address _investor
    ) public view returns (address[] memory investeduTokens) {
        investeduTokens = investeduTokensOf[_investor].values();
    }

    /**
     * @dev Returns the addresses of all uTokens invested by a specific investor during a specific period.
     *
     * This function takes the address of an investor and a period, and returns an array of addresses
     * representing all uTokens that the investor has invested in during the specified period.
     *
     * @param _investor The address of the investor.
     * @param _period The period of investment.
     *
     * @return investeduTokensForPeriod An array of uToken addresses in which the investor has invested during the specified period.
     */
    function getInvesteduTokens_OfUser_ForPeriod(
        address _investor,
        uint256 _period
    ) public view returns (address[] memory investeduTokensForPeriod) {
        investeduTokensForPeriod = investeduTokens_OfUser_ForPeriod[_investor][
            _period
        ].values();
    }

    /**
     * @dev Returns the amount invested by a specific investor in a specific uToken during a specific period.
     *
     * This function takes the address of an investor, a uToken, and a period, and returns the amount
     * that the investor has invested in the specified uToken during the specified period.
     *
     * @param _investor The address of the investor.
     * @param _uToken The address of the uToken.
     * @param _period The period of investment.
     *
     * @return investedAmount The amount invested by the investor in the specified uToken during the specified period.
     */
    function getInvestedAmount_OfUser_AgainstuToken_ForPeriod(
        address _investor,
        address _uToken,
        uint256 _period
    ) public view returns (uint256 investedAmount) {
        investedAmount = investedAmount_OfUser_AgainstuTokens_ForPeriod[
            _investor
        ][_uToken][_period];
    }

    /**
     * @dev A struct that holds details about a user's investment for a specific period.
     *
     * @param uTokenAddress The address of the uToken in which the investment was made.
     * @param amount The amount invested in the uToken.
     */
    struct InvestmentForPeriodOfUser {
        address uTokenAddress;
        uint256 amount;
    }

    /**
     * @dev Returns the details of investments made by a specific investor during a specific period.
     *
     * This function takes the address of an investor and a period, and returns an array of `InvestmentForPeriodOfUser`
     * structs that includes the uToken address and the amount invested for each uToken during the specified period.
     *
     * @param _investor The address of the investor.
     * @param _period The period of investment.
     *
     * @return investmentDetails An array of `InvestmentForPeriodOfUser` structs that contain the uToken address and the investment amount for each investment made by the investor during the specified period.
     */
    function getInvestmentDetails_OfUser_ForPeriod(
        address _investor,
        uint256 _period
    )
        public
        view
        returns (InvestmentForPeriodOfUser[] memory investmentDetails)
    {
        address[] memory totalTokens = investeduTokens_OfUser_ForPeriod[
            _investor
        ][_period].values();
        uint256 tokensCount = totalTokens.length;

        investmentDetails = new InvestmentForPeriodOfUser[](tokensCount);
        if (tokensCount > 0) {
            for (uint i; i < tokensCount; i++) {
                investmentDetails[i] = InvestmentForPeriodOfUser({
                    uTokenAddress: totalTokens[i],
                    amount: investedAmount_OfUser_AgainstuTokens_ForPeriod[
                        _investor
                    ][totalTokens[i]][_period]
                });
            }
        }
    }

    //  Retrieves the currency type associated with a uToken.
    function get_CurrencyOfuToken(
        address _uToken
    ) public view returns (string memory currency) {
        return currencyOf_uToken[_uToken];
    }

    // Checks whether the entered password matches the one associated with the user address.
    // The stored password is hashed for security reasons, so the entered password is hashed
    // and compared with the stored hashed password.
    function isPasswordCorrect(
        address _user,
        string memory _password
    ) public view returns (bool) {
        return (_passwordOf[_user] == keccak256(bytes(_password)));
    }

    // Similar to the password check function, this function checks whether the entered recovery number
    // matches the one associated with the user address.
    function isRecoveryNumberCorrect(
        address _user,
        string memory _recoveryNumber
    ) public view returns (bool) {
        return (_recoveryNumberOf[_user] == keccak256(bytes(_recoveryNumber)));
    }

    // Checks whether a password has been set for the user address.
    function isPasswordSet(address _user) public view returns (bool) {
        return _isPasswordSet[_user];
    }

    // Checks whether a recovery number has been set for the user address.
    // Returns a boolean value that is true if a recovery number is set, and false otherwise.
    function isRecoveryNumberSet(address _user) public view returns (bool) {
        return _isRecoveryNumberSet[_user];
    }

    // Checks whether a deposit has been made in a specific period.
    // Returns a boolean value that is true if a deposit was made in the period, and false otherwise.
    function IsDepositedInPeriod(uint256 _period) public view returns (bool) {
        return isDepositedInPeriod[_period];
    }

    // Retrieves an array of tokens that were deposited within the given period.
    // The return is an array of addresses, where each address represents a token contract.
    function get_TokensDepositedInPeriod(
        uint256 _period
    ) public view returns (address[] memory tokens) {
        return tokensInPeriod[_period].values();
    }

    // Retrieves the count of unique tokens that were deposited within the given period.
    // The return is an integer representing the number of unique token contracts.
    function get_TokensDepositedInPeriodCount(
        uint256 _period
    ) public view returns (uint256) {
        return tokensInPeriod[_period].length();
    }

    // Retrieves an array of addresses that made a deposit within the given period.
    // The return is an array of addresses, where each address represents a unique depositor.
    function get_DepositorsInPeriod(
        uint256 _period
    ) public view returns (address[] memory depositors) {
        return depositorsInPeriod[_period].values();
    }

    // Retrieves the count of unique depositors that made a deposit within the given period.
    // The return is an integer representing the number of unique depositors.
    function get_DepositorsInPeriodCount(
        uint256 _period
    ) public view returns (uint) {
        return depositorsInPeriod[_period].length();
    }

    // Retrieves the total amount of Ether that was deposited within the given period.
    // The return is an integer representing the amount of Ether in wei.
    function get_ETHInPeriod(uint256 _period) public view returns (uint256) {
        return ethInPeriod[_period];
    }

    // Retrieves the reward amount associated with a specific token during a given period.
    // The function returns an integer representing the reward amount for the specific token in the provided period.
    function get_rewardAmountOfTokenInPeriod(
        uint256 _period,
        address _token
    ) public view returns (uint256) {
        return rewardAmountOfTokenForPeriod[_period][_token];
    }

    // Calculates and returns the current period based on the timestamp of the block, the deploy time of the contract, and the time limit for a reward.
    // The function returns an integer representing the current period.
    function get_CurrentPeriod() public view returns (uint) {
        return ((block.timestamp - deployTime) / timeLimitForReward) + 1;
    }

    // Calculates and returns the previous period based on the timestamp of the block, the deploy time of the contract, and the time limit for a reward.
    // The function returns an integer representing the previous period.
    function get_PreviousPeriod() public view returns (uint) {
        return ((block.timestamp - deployTime) / timeLimitForReward);
    }

    // Calculates and returns the start and end times for the current period.
    // The function returns two timestamps: the start time and end time of the current period.
    // If the current period is the first one, the start time is the deployment time of the contract,
    // and the end time is the start time plus the duration of the reward period.
    // For all subsequent periods, the start time is calculated by adding the duration of the reward period multiplied by
    // (current period - 1) to the deployment time of the contract.
    // The end time is the duration of the reward period added to the start time.
    function get_CurrentPeriod_StartAndEndTime()
        public
        view
        returns (uint startTime, uint endTime)
    {
        uint currentTimePeriod = get_CurrentPeriod();

        if (currentTimePeriod == 1) {
            startTime = deployTime;
            endTime = deployTime + timeLimitForReward;
        } else {
            startTime =
                deployTime +
                (timeLimitForReward * (currentTimePeriod - 1));
            endTime = timeLimitForReward + startTime;
        }
    }

    // Retrieves the time limit for the winner to collect their reward for the current period.
    // The function returns a timestamp that represents the deadline for collecting the reward.
    // It is calculated by adding the time limit for reward collection to the start time of the current period.
    function get_TimeLimitForWinnerForCurrentPeriod()
        public
        view
        returns (uint256 rewardTimeLimit)
    {
        (uint startTime, ) = get_CurrentPeriod_StartAndEndTime();
        rewardTimeLimit = startTime + timeLimitForRewardCollection;
    }

    // Determines and returns the current winner.
    // The function calculates the previous time period based on the block timestamp, contract deployment time, and the reward time limit.
    // It then retrieves the list of depositors for the previous time period and the count of these depositors.
    // If there are no depositors in the list, it returns the zero address.
    // Otherwise, it generates a random number using the keccak256 hash function with inputs as the previous time period and deployment time.
    // The modulus operator (%) is used to ensure the random number falls within the range of indices of the depositors array.
    // Finally, it returns the depositor at the index corresponding to the random number, hence determining the current winner.
    function get_currentWinner() public view returns (address) {
        uint256 previousTimePeriod = ((block.timestamp - deployTime) /
            timeLimitForReward);

        address[] memory depositors = get_DepositorsInPeriod(
            previousTimePeriod
        );
        uint256 depositorsLength = get_DepositorsInPeriodCount(
            previousTimePeriod
        );

        if (depositorsLength == 0) return address(0);

        uint randomNumber = uint(
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
    function rewardHistoryForEth() public view returns (uint256 ethHistory) {
        uint256 period = get_PreviousPeriod();
        while (!isRewardCollectedOfPeriod[period]) {
            ethHistory += get_ETHInPeriod(period);
            if (period == 0) break;
            period--;
        }
    }

    // Checks if the reward for a specified period has been collected.
    // The function takes a period number as an input and checks the corresponding value in the `isRewardCollectedOfPeriod` mapping.
    // If the reward for that period has been collected, the function returns true; otherwise, it returns false.
    function IsRewardCollectedOfPeriod(
        uint256 _period
    ) public view returns (bool) {
        return isRewardCollectedOfPeriod[_period];
    }

    // Struct to represent reward against a specific token
    struct RewardAgainstToken {
        address token;
        uint amount;
    }

    /**
     * @notice Returns the reward history for tokens for a specific period.
     * @param _period The period for which to fetch the reward history.
     * @return record An array of `RewardAgainstToken` structs representing the reward history for each token for the given period.
     */
    function rewardHistoryForTokensForPeriod(
        uint256 _period
    ) public view returns (RewardAgainstToken[] memory record) {
        address[] memory _tokens = get_TokensDepositedInPeriod(_period);
        uint256 _tokensCount = _tokens.length;
        record = new RewardAgainstToken[](_tokensCount);
        if (_tokensCount > 0) {
            for (uint i; i < _tokensCount; i++) {
                record[i] = RewardAgainstToken({
                    token: _tokens[i],
                    amount: get_rewardAmountOfTokenInPeriod(_period, _tokens[i])
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
        returns (uint[] memory pendingPeriods)
    {
        uint256 period = get_PreviousPeriod();
        uint[] memory _pendingPeriods = new uint[](period);
        uint256 count;
        while (!isRewardCollectedOfPeriod[period]) {
            if (!isDepositedInPeriod[period]) {
                if (period == 0) break;
                period--;
                continue;
            }
            _pendingPeriods[count++] = period;
            if (period == 0) break;
            period--;
        }

        pendingPeriods = new uint[](count);
        uint _count;
        for (uint i; i < _pendingPeriods.length; i++) {
            if (_pendingPeriods[i] > 0) {
                pendingPeriods[_count++] = _pendingPeriods[i];
            }
        }
    }

    /**
     * @notice Returns a list of all whitelisted addresses.
     * @return _whiteListAddresses An array of all addresses that are whitelisted.
     */
    function get_allWhiteListAddresses()
        public
        view
        returns (address[] memory _whiteListAddresses)
    {
        uint _length = whiteListAddresses.length;
        _whiteListAddresses = new address[](_length);

        for (uint i; i < _length; i++) {
            _whiteListAddresses[i] = whiteListAddresses[i];
        }
    }
}
