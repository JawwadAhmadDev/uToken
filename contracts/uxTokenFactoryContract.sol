// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IERC20.sol";
// import "./SafeMath.sol";
import "./uxTokenContract.sol";

contract uxTokenFactoryContract is Ownable {
    // using SafeMath for uint256;b
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private allDepositors; // all investors of the system

    // overall investment of a depostitor
    // mapping(address => EnumerableSet.AddressSet) private depositedTokensOf; // mapping: depositor => tokens
    mapping(address => uint256) private nativeCurrencyDepositedBy; // mapping: depositor => amount of deposited native currency
    // mapping(address => mapping(address => uint256))
    //     private depositedAmountOfUserForToken; // mapping: depositor => token => amount

    mapping(address => address) private tokenAdressForUxToken; // uxToken -> Token Address (against which contract is deployed)
    mapping(address => string) private currencyOfUxToken;
    mapping(address => address) private uxTokenAddressForToken; // token -> uxToken

    // Deposit details of specific user.
    mapping(address => EnumerableSet.AddressSet) private depositedUxTokensOf; // depositorAddress -> All uxTokens addresses deposited in
    mapping(address => mapping(uint256 => EnumerableSet.AddressSet))
        private depositedUxTokensOfUserForPeriod; // depositorAddress -> period -> All uTokens addresses
    mapping(address => mapping(address => uint256))
        private depositedAmountOfUserAgainstUxToken; // depositor -> uxTokenAddress -> amount
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private depositedAmountOfUserAgainstUxTokenForPeriod; // depositor -> uxTokenAddress -> period -> totalDeposits

    mapping(uint256 => EnumerableSet.AddressSet) private depositorsByPeriod; // (period count i.e. how much 365 hours passed) => depositors addresses.
    mapping(uint256 => EnumerableSet.AddressSet) private tokensByPeriod; // (period count i.e. how much 365 hours passed) => depositedTokens address
    mapping(uint256 => uint256) private ETHInPeriod; // (period count i.e. how much 365 hours passed) => deposited Ethers in the this period
    mapping(uint256 => mapping(address => uint))
        private totalRewardAmountForTokenInPeriod; // (period count) => tokenAddress => totalInvestedAmount
    mapping(uint256 => bool) private hasRewardBeenCollectedForPeriod; // (period count) => boolean
    mapping(uint256 => bool) private isDepositedInPeriod; // period count => boolean (to check that in which period some investment is made.

    // mappings to store Sign Key and randomly generated Master key against user.
    mapping(address => bytes32) private _signKeyOf;
    mapping(address => bool) private _isSignKeySetOf;
    mapping(address => bytes32) private _masterKeyOf;
    mapping(address => bool) private _isMasterKeySetOf;

    // tokens addresses.
    address public uxTokenAddressOfETH;
    EnumerableSet.AddressSet private allowedTokens; // total allowed ERC20 tokens
    EnumerableSet.AddressSet private uxTokensOfAllowedTokens; // uxTokens addresses of allowed ERC20 Tokens
    address[] private whiteListAddresses; // whitelist addresss set only once and will be send to all the deployed tokens.

    // salt for create2 opcode.
    uint256 private _salt;

    // fee detial
    uint256 public benefactionFeePercent = 369; // 0.369 * 1000 = 369% of total deposited amount.
    uint256 public percentOfPublicGoodRecipientCandidateAndSocialGoodAddress =
        30_000; // 30 * 1000 = 30000% of 0.369% of deposited amount
    uint256 public percentofDevsAddress = 10_000; // 40 * 1000 = 40000% of 0.369% of deposited amount

    // time periods for reward
    uint256 public rewardTimeLimitFor369Hours = 129600; // 369 hours
    uint256 public rewardTimeLimitFor369Days = 31881600; // 369 days
    uint256 public deployTime;

    // zoom to handle percentage in the decimals
    uint256 public constant ZOOM = 1_000_00; // actually 100. this is divider to calculate percentage

    // fee receiver addresses.
    address public ux369gift_30 = 0x4651Ea80a87c8E9C0F8495943Ad2490a02777281;
    address public ux369impact_30 = 0xbEF1B7Fb208D6107B90D9C39C484B095c9Db6684;
    address public ux369_30 = 0xEBAf9a2eBCcc903D09392C62482c72221bBb5DDE;
    address public ux369devs_10 = 0x6bD8C72d0f3F5738d4Be740B19bdb406Ae42eb2F;

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

    event TokenDeployed(address indexed tokenAddress, string name);
    event TokenAdded(
        address indexed tokenAddress,
        address indexed deployedAddress
    );

    constructor(
        address[] memory _allowedTokens,
        address[] memory _whiteListAddresses // Fixed typo
    ) Ownable(msg.sender) {
        require(_allowedTokens.length < 256, "Too many allowed tokens"); // Optional: limit on number of tokens
        require(
            _whiteListAddresses.length < 256,
            "Too many whitelist addresses"
        ); // Optional: limit on number of addresses

        deployTime = block.timestamp;

        // Set the whitelist addresses
        whiteListAddresses = _whiteListAddresses;

        // Deploy ETH token and add allowed tokens if any
        uxTokenAddressOfETH = _deployETH();
        if (_allowedTokens.length > 0) {
            _addAllowedTokens(_allowedTokens);
        }
    }

    /**
     * @dev Function to deploy a new instance of uxToken smart contract and initialize it.
     *
     * The function uses the Ethereum assembly language for optimized, low-level operations.
     * It uses the CREATE2 operation code (EVM opcode) to create a new smart contract on the blockchain, with a
     * predetermined address. The address depends on the sender, salt, and init code. The `create2` opcode provides
     * more control over the address of the newly created contract compared to the regular `create` (or CREATE1) opcode.
     *
     * `uxToken.creationCode` is the bytecode used for deploying the uxToken contract.
     *
     * Salt is a value used in the CREATE2 function to generate the new contract address. The salt in this function is
     * generated by hashing a continually incrementing number (_salt) using keccak256, which is the standard Ethereum hashing function.
     *
     * The deployed contract is then initialized by calling its `initialize` method. This sets the
     * name, symbol, underlying asset, and whitelist addresses of the token.
     *
     * @return deployedEth The address of the newly deployed uxToken contract.
     */
    function _deployETH() internal returns (address deployedEth) {
        bytes memory bytecode = type(uxTokenContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedEth := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IuxToken(deployedEth).initialize(
            "uxETH",
            "uxETH",
            "ETHER",
            18,
            whiteListAddresses
        );

        emit TokenDeployed(deployedEth, "uxETH");
    }

    /**
     * @dev Deploys a new instance of uxToken for a given ERC20 token and initializes it.
     *
     * This function creates a new contract instance for any ERC20 token on the Ethereum blockchain,
     * with a name and symbol prefixed with 'ux'. The address of the new contract is deterministic,
     * and depends on the sender, the salt, and the initialization code.
     *
     * @param _token The address of the ERC20 token for which the uxToken needs to be deployed.
     *
     * @return deployedToken The address of the newly deployed uxToken contract.
     *
     * Notes:
     *
     * 1) The `IERC20` interface is used to interact with the ERC20 token. It gets the name and symbol
     *    of the token, which are used to create a corresponding uxToken with a prefixed name and symbol.
     *
     * 2) The salt is generated by hashing an incrementing number (_salt) using the keccak256 hashing function.
     *
     * 3) Ethereum's low-level assembly language is used for optimized operations.
     *    Specifically, the CREATE2 opcode is used to deploy the new uxToken contract.
     *
     * 4) The `initialize` method of the new uxToken contract is called to set its name, symbol,
     *    underlying asset symbol, and whitelist addresses.
     */
    function _deployToken(
        address _token
    ) internal returns (address deployedToken) {
        IERC20 tokenContract = IERC20(_token);
        string memory name = string(
            abi.encodePacked("ux", tokenContract.name())
        );
        string memory symbol = string(
            abi.encodePacked("ux", tokenContract.symbol())
        );
        string memory currency = tokenContract.symbol();
        uint8 decimals = tokenContract.decimals();

        bytes memory bytecode = type(uxTokenContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedToken := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        IuxToken(deployedToken).initialize(
            name,
            symbol,
            currency,
            decimals,
            whiteListAddresses
        );

        emit TokenDeployed(deployedToken, name);
    }

    /**
     * @dev Adds an array of token addresses to the list of allowed tokens and deploys uxToken for each.
     *
     * This function iterates through the array of input addresses, checks if each address corresponds to a contract,
     * checks if it's not already in the list of allowed tokens, deploys a uxToken for it, and updates the corresponding
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
     * 3) The `_deployToken` function deploys a new uxToken contract for the given token.
     *
     * 4) `tokenAdressForUxToken`, `uxTokenAddressForToken`, `currencyOfUxToken`, `allowedTokens`, and
     *    `uxTokensOfAllowedTokens` are state variables (mappings or sets) that are updated for each token.
     *
     * require _token.isContract() Ensures the provided address corresponds to a contract.
     * require !(allowedTokens.contains(_token)) Ensures the token is not already in the allowedTokens set.
     */
    function _addAllowedTokens(address[] memory _allowedTokens) internal {
        uint256 length = _allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = _allowedTokens[i]; // Store in a local variable

            require(
                tokenAddress.code.length > 0,
                "uxTokenFactory: INVALID ALLOWED TOKEN ADDRESS"
            );
            require(
                !allowedTokens.contains(tokenAddress),
                "Factory: Already added"
            );

            address deployedAddress = _deployToken(tokenAddress); // Deploy token directly
            tokenAdressForUxToken[deployedAddress] = tokenAddress;
            uxTokenAddressForToken[tokenAddress] = deployedAddress;
            currencyOfUxToken[deployedAddress] = IuxToken(deployedAddress)
                .currency();

            allowedTokens.add(tokenAddress);
            uxTokensOfAllowedTokens.add(deployedAddress);

            emit TokenAdded(tokenAddress, deployedAddress);
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

    function removeAllowedTokens(address[] memory _allowedTokens) external onlyOwner {
        uint256 length = _allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = _allowedTokens[i]; // Store in a local variable

            
            require(
                allowedTokens.contains(tokenAddress),
                "Factory: Not Added"
            );

            allowedTokens.remove(tokenAddress);
            uxTokensOfAllowedTokens.remove(uxTokenAddressForToken[tokenAddress]);

            emit TokenAdded(tokenAddress, deployedAddress);
    }

    /**
     * @dev Handles the depositing of tokens.
     *
     * This function allows the sender to deposit tokens into the contract. It verifies the sign key of the sender,
     * checks the deposited amount, verifies the token type, and then executes the deposit and divides up the deposit fee.
     *
     * @param _signKey The sign key of the depositor for verification.
     * @param _uxTokenAddress The address of the token being deposited.
     * @param _amount The amount of the token being deposited.
     *
     * require: Caller's password must be set.
     * require: Caller's password must match the stored password.
     * require: Deposit amount must be greater than 0.
     * require: The token address must be valid.
     */
    function protect(
        string memory _signKey,
        address _uxTokenAddress,
        uint256 _amount
    ) external payable {
        address depositor = msg.sender;

        // Validate sign key
        require(_isSignKeySetOf[depositor], "Factory: SignKey not set yet.");
        require(
            _signKeyOf[depositor] == keccak256(bytes(_signKey)),
            "Factory: SignKey incorrect"
        );
        require(_amount > 0, "Factory: invalid amount");
        require(
            _uxTokenAddress == uxTokenAddressOfETH ||
                uxTokensOfAllowedTokens.contains(_uxTokenAddress),
            "Factory: invalid uxToken address"
        );

        // Calculate deposit fee and remaining amount
        uint256 depositFee = (_amount * benefactionFeePercent) / ZOOM;
        uint256 remaining = _amount - depositFee;

        // Call protect method on uxToken contract
        require(
            IuxToken(_uxTokenAddress).protect(depositor, remaining),
            "Factory: deposit failed"
        );

        // Handle fees and deposits
        if (_uxTokenAddress == uxTokenAddressOfETH) {
            require(msg.value > 0, "Factory: invalid Ether");
            _handleFeeETH(depositFee);
        } else {
            require(
                IERC20(tokenAdressForUxToken[_uxTokenAddress]).transferFrom(
                    depositor,
                    address(this),
                    _amount
                ),
                "Factory: TransferFrom failed"
            );
            _handleFeeTokens(
                tokenAdressForUxToken[_uxTokenAddress],
                depositFee
            );
        }

        // Add depositor to the list if it's the first deposit
        if (!allDepositors.contains(depositor)) {
            allDepositors.add(depositor);
        }

        // Update deposit details for 369 days mappings
        if (_uxTokenAddress == uxTokenAddressOfETH) {
            nativeCurrencyDepositedBy[depositor] += msg.value;
        }

        if (!depositedUxTokensOf[depositor].contains(_uxTokenAddress)) {
            depositedUxTokensOf[depositor].add(_uxTokenAddress);
        }

        uint256 currentPeriod = getCurrentPeriodFor369hours(); // Use memory variable for efficiency
        if (
            !depositedUxTokensOfUserForPeriod[depositor][currentPeriod]
                .contains(_uxTokenAddress)
        ) {
            depositedUxTokensOfUserForPeriod[depositor][currentPeriod].add(
                _uxTokenAddress
            );
        }
        depositedAmountOfUserAgainstUxToken[depositor][
            _uxTokenAddress
        ] += remaining;
        depositedAmountOfUserAgainstUxTokenForPeriod[depositor][
            _uxTokenAddress
        ][currentPeriod] += remaining;

        emit Protect(depositor, _uxTokenAddress, currentPeriod, remaining);
    }

    /**
     * @dev Handles the deposit fee for Ethereum deposits.
     *
     * This function divides the deposit fee into the respective shares for the publicGoodAndCommunity, RecipientCandidate, SocialGood and DevFund addresses.
     * It also checks and updates the depositors and deposited Ether amount for the current time period.
     *
     * @param _depositFee The amount of the deposit fee in Ether.
     */
    function _handleFeeETH(uint256 _depositFee) internal {
        uint256 thirtyPercentShare = (_depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
        uint256 shareOfDevFundAddress = (_depositFee * percentofDevsAddress) /
            ZOOM;

        // Transfer fees
        payable(ux369gift_30).transfer(thirtyPercentShare);
        payable(ux369_30).transfer(thirtyPercentShare);
        payable(ux369impact_30).transfer(thirtyPercentShare);
        payable(ux369devs_10).transfer(shareOfDevFundAddress);

        // Calculate current time period
        uint256 currentTimePeriodCount = getCurrentPeriodFor369hours();

        // Update period deposits and depositors
        if (!isDepositedInPeriod[currentTimePeriodCount]) {
            isDepositedInPeriod[currentTimePeriodCount] = true;
        }

        if (!depositorsByPeriod[currentTimePeriodCount].contains(msg.sender)) {
            depositorsByPeriod[currentTimePeriodCount].add(msg.sender);
        }

        ETHInPeriod[currentTimePeriodCount] += thirtyPercentShare; // Combine operations to minimize storage writes
    }

    /**
     * @dev Handles the deposit fee for token deposits.
     *
     * This function divides the deposit fee into the respective shares for the publicGoodAndCommunity, RecipientCandidate, SocialGood and DevFund addresses.
     * It also checks and updates the depositors, deposited tokens, and reward amount for the current time period.
     *
     * @param _tokenAddress The address of the token being deposited.
     * @param _depositFee The amount of the deposit fee in tokens.
     */
    function _handleFeeTokens(
        address _tokenAddress,
        uint256 _depositFee
    ) internal {
        uint256 thirtyPercentShare = (_depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
        uint256 tenPercentShare = (_depositFee * percentofDevsAddress) / ZOOM;

        // Transfer fees and require success
        require(
            IERC20(_tokenAddress).transfer(ux369gift_30, thirtyPercentShare),
            "Transfer to ux369gift_30 failed"
        );
        require(
            IERC20(_tokenAddress).transfer(ux369_30, thirtyPercentShare),
            "Transfer to ux369_30 failed"
        );
        require(
            IERC20(_tokenAddress).transfer(ux369impact_30, thirtyPercentShare),
            "Transfer to ux369impact_30 failed"
        );
        require(
            IERC20(_tokenAddress).transfer(ux369devs_10, tenPercentShare),
            "Transfer to ux369devs_10 failed"
        );

        // Calculate current time period
        uint256 currentTimePeriodCount = getCurrentPeriodFor369hours();

        // Update period deposits and depositors
        if (!isDepositedInPeriod[currentTimePeriodCount]) {
            isDepositedInPeriod[currentTimePeriodCount] = true;
        }

        if (!depositorsByPeriod[currentTimePeriodCount].contains(msg.sender)) {
            depositorsByPeriod[currentTimePeriodCount].add(msg.sender);
        }

        if (!tokensByPeriod[currentTimePeriodCount].contains(_tokenAddress)) {
            tokensByPeriod[currentTimePeriodCount].add(_tokenAddress);
        }

        totalRewardAmountForTokenInPeriod[currentTimePeriodCount][
            _tokenAddress
        ] += thirtyPercentShare; // Combine operations
    }

    /**
     * @dev Handles the withdrawal of tokens.
     *
     * This function allows the sender to withdraw tokens from the contract. It verifies the signKey of the sender,
     * checks the withdrawal amount, verifies the token type, and then executes the withdrawal.
     *
     * @param _signKey The sign key of the withdrawer for verification.
     * @param _uxTokenAddress The address of the token being withdrawn.
     * @param _amount The amount of the token being withdrawn.
     *
     * require: Caller's signKey must be set.
     * require: Caller's signKey must match the stored signKey.
     * require: The token address must be valid.
     * require: Withdrawal amount must be greater than 0.
     * require: Caller's balance must be sufficient for the withdrawal.
     */
    function burnAndUnprotect(
        string memory _signKey,
        address _uxTokenAddress,
        uint256 _amount
    ) external {
        address withdrawer = msg.sender;

        require(_isSignKeySetOf[withdrawer], "Factory: SignKey not set yet.");
        require(
            _signKeyOf[withdrawer] == keccak256(bytes(_signKey)),
            "Factory: SignKey incorrect"
        );
        require(
            _uxTokenAddress == uxTokenAddressOfETH ||
                uxTokensOfAllowedTokens.contains(_uxTokenAddress),
            "Factory: invalid uxToken address"
        );

        uint256 balance = IuxToken(_uxTokenAddress).balanceOf(withdrawer);
        require(_amount > 0, "Factory: invalid amount");
        require(balance >= _amount, "Factory: Not enough tokens");

        require(
            IuxToken(_uxTokenAddress).burnAndUnprotect(withdrawer, _amount),
            "Factory: withdraw failed"
        );

        // Transfer the amount based on the token type
        if (_uxTokenAddress == uxTokenAddressOfETH) {
            payable(withdrawer).transfer(_amount);
        } else {
            require(
                IERC20(tokenAdressForUxToken[_uxTokenAddress]).transfer(
                    withdrawer,
                    _amount
                ),
                "Factory: transfer failed"
            );
        }

        // Update the deposited amounts
        uint256 previousAmount = depositedAmountOfUserAgainstUxToken[
            withdrawer
        ][_uxTokenAddress];
        depositedAmountOfUserAgainstUxToken[withdrawer][_uxTokenAddress] =
            previousAmount -
            _amount;

        // Update the current period deposits
        uint256 currentPeriod = getCurrentPeriodFor369hours();
        if (
            depositedAmountOfUserAgainstUxToken[withdrawer][_uxTokenAddress] <
            depositedAmountOfUserAgainstUxTokenForPeriod[withdrawer][
                _uxTokenAddress
            ][currentPeriod]
        ) {
            depositedAmountOfUserAgainstUxTokenForPeriod[withdrawer][
                _uxTokenAddress
            ][currentPeriod] = depositedAmountOfUserAgainstUxToken[withdrawer][
                _uxTokenAddress
            ];
        }

        emit BurnAndUnprotect(withdrawer, _uxTokenAddress, _amount);
    }

    /**
     * @dev Transfers tokens from the caller to the given address.
     *
     * This function allows the sender to transfer tokens to another address. It verifies the password of the sender,
     * checks the transfer amount, verifies the token type, and then executes the transfer. After successful transfer,
     * it adds the transferred token address to the receiver's list of tokens.
     *
     * @param _signKey The signKey of the sender for verification.
     * @param _uxTokenAddress The address of the token being transferred.
     * @param _to The recipient's address.
     * @param _amount The amount of the token being transferred.
     *
     * @return true if the transfer is successful, throws an error otherwise.
     *
     * require: Caller's signKey must be set.
     * require: Caller's signKey must match the stored signKey.
     * require: The token address must be valid.
     * require: Transfer amount must be greater than 0.
     */
    function transfer(
        string memory _signKey,
        address _uxTokenAddress,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        address caller = msg.sender;

        require(_isSignKeySetOf[caller], "Factory: SignKey not set yet.");
        require(
            _signKeyOf[caller] == keccak256(bytes(_signKey)),
            "Factory: SignKey incorrect"
        );
        require(_amount > 0, "Factory: Invalid amount");
        require(
            _uxTokenAddress == uxTokenAddressOfETH ||
                uxTokensOfAllowedTokens.contains(_uxTokenAddress),
            "Factory: invalid uxToken address"
        );

        // Transfer the tokens
        require(
            IuxToken(_uxTokenAddress).transfer(_to, _amount),
            "Factory: transfer failed"
        );

        return true;
    }

    /**
     * @dev Allows a user to set their SignKey and MasterKey for the first time.
     *
     * This function sets the SignKey and MasterKey of the caller (msg.sender).
     * Both the SignKey and MasterKey are hashed for secure storage. The function
     * can only be called if neither the SignKey nor the MasterKey has been set before.
     *
     * @param _signKey The SignKey provided by the user.
     * @param _masterKey The MasterKey provided by the user.
     *
     * require The SignKey and MasterKey for the caller should not have been set before.
     */
    function setMasterKeyAndSignKey(
        string memory _signKey,
        string memory _masterKey
    ) external {
        address caller = msg.sender;
        require(
            (!(_isSignKeySetOf[caller]) && !(_isMasterKeySetOf[caller])),
            "Factory: SignKey already set"
        );
        _signKeyOf[caller] = keccak256(bytes(_signKey));
        _masterKeyOf[caller] = keccak256(bytes(_masterKey));
        _isSignKeySetOf[caller] = true;
        _isMasterKeySetOf[caller] = true;
    }

    /**
     * @dev Allows a user to change their SignKey using their MaskterKey.
     *
     * This function changes the SignKey of the caller (msg.sender) after verifying their MaskterKey.
     * The new SignKey is hashed for secure storage. This function can only be called if the user's recovery
     * number matches the one provided in the function argument.
     *
     * @param _masterKey The MaskterKey provided by the user.
     * @param _signKey The new SignKey provided by the user.
     *
     * require The MaskterKey provided should match the MaskterKey stored for the caller.
     */
    function changeSignKey(
        string memory _masterKey,
        string memory _signKey
    ) external {
        address caller = msg.sender;
        require(
            _masterKeyOf[caller] == keccak256(bytes(_masterKey)),
            "Factory: incorrect recovery number"
        );
        _signKeyOf[caller] = keccak256(bytes(_signKey));
    }

    // function to change time limit for reward of 369 hours. only onwer is authorized.
    function changeRewardTimeLimitFor369Hours(
        uint256 _time
    ) external onlyOwner {
        rewardTimeLimitFor369Hours = _time;
    }

    // function to change the time limit for reward of 369 days. only owner is authorized
    function changeRewardTimeLimitFor369Days(uint256 _time) external onlyOwner {
        rewardTimeLimitFor369Days = _time;
    }

    //--------------------Read Functions -------------------------------//
    //--------------------Allowed Tokens -------------------------------//
    /**
     * @dev Returns the addresses of all allowed tokens.
     *
     * This function returns an array of the addresses of all tokens that are currently allowed.
     *
     * @return An array of addresses representing allowed tokens.
     */
    function allAllowedTokens() public view returns (address[] memory) {
        return allowedTokens.values();
    }

    /**
     * @dev Returns the count of all allowed tokens.
     *
     * This function returns the total count of tokens that are currently allowed.
     *
     * @return A number representing the count of allowed tokens.
     */
    function allAllowedTokensCount() public view returns (uint256) {
        return allowedTokens.length();
    }

    /**
     * @dev Returns the addresses of all uxTokens of the allowed tokens.
     *
     * This function returns an array of the addresses of all uxTokens that correspond to currently allowed tokens.
     *
     * @return An array of addresses representing uTokens of allowed tokens.
     */
    function allUxTokensOfAllowedTokens()
        public
        view
        returns (address[] memory)
    {
        return uxTokensOfAllowedTokens.values();
    }

    /**
     * @dev Returns the count of all uxTokens of the allowed tokens.
     *
     * This function returns the total count of uxTokens that correspond to currently allowed tokens.
     *
     * @return A number representing the count of uxTokens of allowed tokens.
     */
    function allUxTokensOfAllowedTokensCount() public view returns (uint256) {
        return uxTokensOfAllowedTokens.length();
    }

    /**
     * @dev Returns the address of the token corresponding to the given uxToken.
     *
     * This function takes the address of a uxToken and returns the address of the corresponding token.
     *
     * @param _uxToken The address of the uToken.
     *
     * @return The address of the token that corresponds to the given uxToken.
     */
    function getTokenAddressForUxToken(
        address _uxToken
    ) public view returns (address) {
        return tokenAdressForUxToken[_uxToken];
    }

    /**
     * @dev Returns the address of the uxToken corresponding to the given token.
     *
     * This function takes the address of a token and returns the address of the corresponding uxToken.
     *
     * @param _token The address of the token.
     *
     * @return The address of the uxToken that corresponds to the given token.
     */
    function getUxTokenAddressForToken(
        address _token
    ) public view returns (address) {
        return uxTokenAddressForToken[_token];
    }

    //-------------------- Deposit Details for 369 days -------------------------------//
    function getAllDepositorsInSystem()
        public
        view
        returns (address[] memory _allDepositors)
    {
        _allDepositors = allDepositors.values();
    }

    function getNativeCurrencyDepositedBy(
        address _depositor
    ) public view returns (uint256 _depositedNativeCurrency) {
        _depositedNativeCurrency = nativeCurrencyDepositedBy[_depositor];
    }

    struct DepositsOfUser {
        address uxTokenAddress;
        uint256 amount;
    }

    function getDepositDetailsForUser(
        address _depositor
    ) public view returns (DepositsOfUser[] memory depositDetails) {
        address[] memory totaluxTokens = depositedUxTokensOf[_depositor]
            .values();
        uint256 tokensCount = totaluxTokens.length;

        depositDetails = new DepositsOfUser[](tokensCount);
        if (tokensCount > 0) {
            for (uint i; i < tokensCount; i++) {
                depositDetails[i] = DepositsOfUser({
                    uxTokenAddress: totaluxTokens[i],
                    amount: depositedAmountOfUserAgainstUxToken[_depositor][
                        totaluxTokens[i]
                    ]
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

        uint randomNumber = uint(
            keccak256(abi.encodePacked(previousTimePeriod, deployTime))
        ) % depositorsLength;

        return depositors[randomNumber];
    }

    /**
     * @dev Returns the addresses of all uxTokens deposited by a specific depositor.
     *
     * This function takes the address of an depositor and returns an array of addresses
     * representing all uxTokens that the depositor has deposited in.
     *
     * @param _depositor The address of the depositor.
     *
     * @return depositeduxTokens An array of uxToken addresses in which the depositor has deposited.
     */
    function getDepositedUxTokensForUser(
        address _depositor
    ) public view returns (address[] memory depositeduxTokens) {
        depositeduxTokens = depositedUxTokensOf[_depositor].values();
    }

    /**
     * @dev Returns the addresses of all uxTokens deposited by a specific depositor during a specific period.
     *
     * This function takes the address of an depositor and a period, and returns an array of addresses
     * representing all uxTokens that the depositor has deposited in during the specified period.
     *
     * @param _depositor The address of the depositor.
     * @param _period The period of investment.
     *
     * @return depositeduxTokensForPeriod An array of uxToken addresses in which the depositor has deposited during the specified period.
     */
    function getDepositedUxTokensOfUserForPeriodFor369hours(
        address _depositor,
        uint256 _period
    ) public view returns (address[] memory depositeduxTokensForPeriod) {
        depositeduxTokensForPeriod = depositedUxTokensOfUserForPeriod[
            _depositor
        ][_period].values();
    }

    /**
     * @dev Returns the amount deposited by a specific depositor in a specific uxToken during a specific period.
     *
     * This function takes the address of an depositor, a uxToken, and a period, and returns the amount
     * that the depositor has deposited in the specified uxToken during the specified period.
     *
     * @param _depositor The address of the depositor.
     * @param _uxToken The address of the uxToken.
     * @param _period The period of deposit.
     *
     * @return depositedAmount The amount deposited by the depositor in the specified uxToken during the specified period.
     */
    function getDepositedAmountOfUserAgainstUxTokenForPeriodFor369hours(
        address _depositor,
        address _uxToken,
        uint256 _period
    ) public view returns (uint256 depositedAmount) {
        depositedAmount = depositedAmountOfUserAgainstUxTokenForPeriod[
            _depositor
        ][_uxToken][_period];
    }

    /**
     * @dev A struct that holds details about a user's deposit details for a specific period.
     *
     * @param uxTokenAddress The address of the uxToken in which the deposit was made.
     * @param amount The amount deposited in the uxToken.
     */
    struct DepositsForPeriodOfUser {
        address uxTokenAddress;
        uint256 amount;
    }

    /**
     * @dev Returns the details of deposits made by a specific depositor during a specific period.
     *
     * This function takes the address of an depositor and a period, and returns an array of `DepositsForPeriodOfUser`
     * structs that includes the uxToken address and the amount deposited for each uxToken during the specified period.
     *
     * @param _depositor The address of the depositor.
     * @param _period The period of deposits.
     *
     * @return depositDetails An array of `DepositsForPeriodOfUser` structs that contain the uToken address and the investment amount for each investment made by the investor during the specified period.
     */
    function getDepositDetailsOfUserForPeriodFor369hours(
        address _depositor,
        uint256 _period
    ) public view returns (DepositsForPeriodOfUser[] memory depositDetails) {
        address[] memory totaluxTokens = depositedUxTokensOfUserForPeriod[
            _depositor
        ][_period].values();
        uint256 tokensCount = totaluxTokens.length;

        depositDetails = new DepositsForPeriodOfUser[](tokensCount);
        if (tokensCount > 0) {
            for (uint i; i < tokensCount; i++) {
                depositDetails[i] = DepositsForPeriodOfUser({
                    uxTokenAddress: totaluxTokens[i],
                    amount: depositedAmountOfUserAgainstUxTokenForPeriod[
                        _depositor
                    ][totaluxTokens[i]][_period]
                });
            }
        }
    }

    //  Retrieves the currency type associated with a uxToken.
    function getCurrencyOfUxToken(
        address _uxToken
    ) public view returns (string memory currency) {
        return currencyOfUxToken[_uxToken];
    }

    // Checks whether the entered signKey matches the one associated with the user address.
    // The stored signKey is hashed for security reasons, so the entered signKey is hashed
    // and compared with the stored hashed signKey.
    function isSignKeyCorrect(
        address _user,
        string memory _signKey
    ) public view returns (bool) {
        return (_signKeyOf[_user] == keccak256(bytes(_signKey)));
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
    ) public view returns (uint) {
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
    function getCurrentPeriodFor369hours() public view returns (uint) {
        return
            ((block.timestamp - deployTime) / rewardTimeLimitFor369Hours) + 1;
    }

    // The function returns an integer representing the current period for 369 days.
    function getCurrentPeriodFor369days() public view returns (uint) {
        return ((block.timestamp - deployTime) / rewardTimeLimitFor369Days) + 1;
    }

    // Calculates and returns the previous period based on the timestamp of the block, the deploy time of the contract, and the time limit for a reward.
    // The function returns an integer representing the previous period for 369 hours.
    function getPreviousPeriodFor369Hours() public view returns (uint) {
        return ((block.timestamp - deployTime) / rewardTimeLimitFor369Hours);
    }

    function getPreviousPeriodFor369days() public view returns (uint) {
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
        returns (uint startTime, uint endTime)
    {
        uint currentTimePeriod_for369hours = getCurrentPeriodFor369hours();

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
        returns (uint startTime, uint endTime)
    {
        uint currentTimePeriod_for369days = getCurrentPeriodFor369days();

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
        address[] memory _tokens = getTokensDepositedByPeriod(_period);
        uint256 _tokensCount = _tokens.length;
        record = new RewardAgainstToken[](_tokensCount);
        if (_tokensCount > 0) {
            for (uint i; i < _tokensCount; i++) {
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
        returns (uint[] memory pendingPeriods)
    {
        uint256 period = getPreviousPeriodFor369Hours();
        uint[] memory _pendingPeriods = new uint[](period);
        uint256 count;
        while (!hasRewardBeenCollectedForPeriod[period]) {
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
        uint _length = whiteListAddresses.length;
        _whiteListAddresses = new address[](_length);

        for (uint i; i < _length; i++) {
            _whiteListAddresses[i] = whiteListAddresses[i];
        }
    }
}
