// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./IERC20.sol";
import "./urTokenContract.sol";
import "./PasswordManager.sol";

contract urTokenFactoryContract is Ownable, PasswordManager {
    // using SafeMath for uint256;b
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private allDepositors; // all investors of the system

    // overall investment of a depostitor
    // mapping(address => EnumerableSet.AddressSet) private depositedTokensOf; // mapping: depositor => tokens
    mapping(address => uint256) private nativeCurrencyDepositedBy; // mapping: depositor => amount of deposited native currency
    // mapping(address => mapping(address => uint256))
    //     private depositedAmountOfUserForToken; // mapping: depositor => token => amount

    mapping(address => address) private tokenAdressForurToken; // urToken -> Token Address (against which contract is deployed)
    mapping(address => string) private currencyOfurToken;
    mapping(address => address) private urTokenAddressForToken; // token -> urToken

    // Deposit details of specific user.
    mapping(address => EnumerableSet.AddressSet) private depositedurTokensOf; // depositorAddress -> All urTokens addresses deposited in
    mapping(address => mapping(uint256 => EnumerableSet.AddressSet))
        private depositedurTokensOfUserForPeriod; // depositorAddress -> period -> All urTokens addresses
    mapping(address => mapping(address => uint256))
        private depositedAmountOfUserAgainsturToken; // depositor -> urTokenAddress -> amount
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private depositedAmountOfUserAgainsturTokenForPeriod; // depositor -> urTokenAddress -> period -> totalDeposits

    mapping(uint256 => EnumerableSet.AddressSet) private depositorsByPeriod; // (period count) => depositors addresses.
    mapping(uint256 => EnumerableSet.AddressSet) private tokensByPeriod; // (period count) => depositedTokens address
    mapping(uint256 => uint256) private ETHInPeriod; // (period count) => deposited Ethers in the this period
    mapping(uint256 => mapping(address => uint256))
        private totalRewardAmountForTokenInPeriod; // (period count) => tokenAddress => totalInvestedAmount
    mapping(uint256 => bool) private hasRewardBeenCollectedForPeriod; // (period count) => boolean
    mapping(uint256 => bool) private isDepositedInPeriod; // period count => boolean (to check that in which period some protection is made).

    // mappings to store Sign Key and randomly generated Master key against user.
    mapping(address => bool) private _isQuantumProtected;
    mapping(address => bool) private _isSignKeySetOf;
    mapping(address => bytes32) private _masterKeyOf;
    mapping(address => bool) private _isMasterKeySetOf;

    AggregatorV3Interface public priceFeed; // Chainlink ETH/USD Price Feed

    // tokens addresses.
    address public urTokenAddressOfETH;
    EnumerableSet.AddressSet private allowedTokens; // total allowed ERC20 tokens
    EnumerableSet.AddressSet private urTokensOfAllowedTokens; // urTokens addresses of allowed ERC20 Tokens
    address[] private whiteListAddresses; // whitelist addresss set only once and will be send to all the deployed tokens.

    // salt for create2 opcode.
    uint256 private _salt;

    // fee detial
    uint256 public quantumActivationFee = 3.69 * 1e18; // 3.69 $
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
    address public ur369gift_30 = 0x70C819445c6Bb5a144954818DE138b4A713408dC;
    address public ur369impact_30 = 0x22357B3034DF4a65a00E5887aFB09e94Df17B7B9;
    address public ur369_30 = 0x4eb401801b42139737faC676C5da5e43F6A1A828;
    address public ur369devs_10 = 0xDB0ccF145A929c48277a4431004D633E9D84258a;

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
    event TokenRemoved(address indexed tokenAddress);
    event SignKeyChanged(
        address indexed userAddress,
        uint256 timestamp,
        bool isQuantumProtected
    );

    constructor(
        string memory _appName,
        address[] memory _allowedTokens,
        address[] memory _whiteListAddresses, // Fixed typo
        address _priceFeedAddress
    ) Ownable(msg.sender) PasswordManager(_appName) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress); // Chainlink ETH/USD price feed
        deployTime = block.timestamp;

        // Set the whitelist addresses
        whiteListAddresses = _whiteListAddresses;

        // Deploy ETH token and add allowed tokens if any
        urTokenAddressOfETH = _deployETH();
        if (_allowedTokens.length > 0) {
            _addAllowedTokens(_allowedTokens);
        }
    }

    function _deployETH() internal returns (address deployedEth) {
        bytes memory bytecode = type(urTokenContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedEth := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IurToken(deployedEth).initialize(
            "urETH",
            "urETH",
            "ETHER",
            18,
            whiteListAddresses
        );

        emit TokenDeployed(deployedEth, "urETH");
    }

    function _deployToken(
        address _token
    ) internal returns (address deployedToken) {
        IERC20 tokenContract = IERC20(_token);
        string memory name = string(
            abi.encodePacked("ur", tokenContract.name())
        );
        string memory symbol = string(
            abi.encodePacked("ur", tokenContract.symbol())
        );
        string memory currency = tokenContract.symbol();
        uint8 decimals = tokenContract.decimals();

        bytes memory bytecode = type(urTokenContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedToken := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        IurToken(deployedToken).initialize(
            name,
            symbol,
            currency,
            decimals,
            whiteListAddresses
        );

        emit TokenDeployed(deployedToken, name);
    }

    function _addAllowedTokens(address[] memory _allowedTokens) internal {
        uint256 length = _allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = _allowedTokens[i]; // Store in a local variable

            require(tokenAddress.code.length > 0, "INVALID ALLOWED");
            require(!allowedTokens.contains(tokenAddress), "added");

            address deployedAddress = _deployToken(tokenAddress); // Deploy token directly
            tokenAdressForurToken[deployedAddress] = tokenAddress;
            urTokenAddressForToken[tokenAddress] = deployedAddress;
            currencyOfurToken[deployedAddress] = IurToken(deployedAddress)
                .currency();

            allowedTokens.add(tokenAddress);
            urTokensOfAllowedTokens.add(deployedAddress);

            emit TokenAdded(tokenAddress, deployedAddress);
        }
    }

    function addAllowedTokens(
        address[] memory _allowedTokens
    ) external onlyOwner {
        _addAllowedTokens(_allowedTokens);
    }

    function removeAllowedTokens(
        address[] memory _allowedTokens
    ) external onlyOwner {
        uint256 length = _allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = _allowedTokens[i]; // Store in a local variable

            require(allowedTokens.contains(tokenAddress), "Not Added");

            allowedTokens.remove(tokenAddress);
            urTokensOfAllowedTokens.remove(
                urTokenAddressForToken[tokenAddress]
            );

            emit TokenRemoved(tokenAddress);
        }
    }

    function protect(
        address _urTokenAddress,
        uint256 _amount,
        bool _quantumVerified,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) external payable {
        address depositor = msg.sender;

        require(_isSignKeySetOf[msg.sender], "SignKey not set");
        if (_quantumVerified) {
            require(_isQuantumProtected[msg.sender], "Quantum not set");
        }
        require(
            verifyLogin(
                msg.sender,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            ),
            "SignKey incorrect"
        );
        require(_amount > 0, "invalid amount");
        require(
            _urTokenAddress == urTokenAddressOfETH ||
                urTokensOfAllowedTokens.contains(_urTokenAddress),
            "invalid urToken"
        );

        // Calculate deposit fee and remaining amount
        uint256 depositFee = (_amount * benefactionFeePercent) / ZOOM;
        uint256 remaining = _amount - depositFee;

        // Call protect method on urToken contract
        require(
            IurToken(_urTokenAddress).protect(msg.sender, remaining),
            "deposit failed"
        );

        uint256 currentTimePeriodCount = getCurrentPeriodFor369hours();

        uint256 thirtyPercentShare = (depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
        // Handle fees and deposits
        if (_urTokenAddress == urTokenAddressOfETH) {
            require(msg.value > 0, "invalid Ether");

            ETHInPeriod[currentTimePeriodCount] += thirtyPercentShare;
        } else {
            IERC20(tokenAdressForurToken[_urTokenAddress]).transferFrom(
                depositor,
                address(this),
                _amount
            );

            if (
                !tokensByPeriod[currentTimePeriodCount].contains(
                    tokenAdressForurToken[_urTokenAddress]
                )
            ) {
                tokensByPeriod[currentTimePeriodCount].add(
                    tokenAdressForurToken[_urTokenAddress]
                );
            }

            totalRewardAmountForTokenInPeriod[currentTimePeriodCount][
                tokenAdressForurToken[_urTokenAddress]
            ] += thirtyPercentShare;
        }

        _handleFee(_urTokenAddress, depositFee, currentTimePeriodCount);

        // Add depositor to the list if it's the first deposit
        if (!allDepositors.contains(depositor)) {
            allDepositors.add(depositor);
        }

        // Update deposit details for 369 days mappings
        if (_urTokenAddress == urTokenAddressOfETH) {
            nativeCurrencyDepositedBy[depositor] += msg.value;
        }

        if (!depositedurTokensOf[depositor].contains(_urTokenAddress)) {
            depositedurTokensOf[depositor].add(_urTokenAddress);
        }

        uint256 currentPeriod = getCurrentPeriodFor369hours(); // Use memory variable for efficiency
        if (
            !depositedurTokensOfUserForPeriod[depositor][currentPeriod]
                .contains(_urTokenAddress)
        ) {
            depositedurTokensOfUserForPeriod[depositor][currentPeriod].add(
                _urTokenAddress
            );
        }
        depositedAmountOfUserAgainsturToken[depositor][
            _urTokenAddress
        ] += remaining;
        depositedAmountOfUserAgainsturTokenForPeriod[depositor][
            _urTokenAddress
        ][currentPeriod] += remaining;

        emit Protect(depositor, _urTokenAddress, currentPeriod, remaining);
    }

    function _handleFee(
        address _urTokenAddress,
        uint256 _depositFee,
        uint256 _currentTimePeriodCount
    ) internal {
        uint256 thirtyPercentShare = (_depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
        uint256 tenPercentShare = (_depositFee * percentofDevsAddress) / ZOOM;

        // Transfer fees and require success
        require(
            IurToken(_urTokenAddress).protect(ur369gift_30, thirtyPercentShare),
            "gift failed"
        );
        require(
            IurToken(_urTokenAddress).protect(ur369_30, thirtyPercentShare),
            "369 failed"
        );
        require(
            IurToken(_urTokenAddress).protect(
                ur369impact_30,
                thirtyPercentShare
            ),
            "369 failed"
        );
        require(
            IurToken(_urTokenAddress).protect(ur369devs_10, tenPercentShare),
            "369Dev failed"
        );

        // Update period deposits and depositors
        if (!isDepositedInPeriod[_currentTimePeriodCount]) {
            isDepositedInPeriod[_currentTimePeriodCount] = true;
        }

        if (!depositorsByPeriod[_currentTimePeriodCount].contains(msg.sender)) {
            depositorsByPeriod[_currentTimePeriodCount].add(msg.sender);
        }
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

        require(_isSignKeySetOf[withdrawer], "SignKey not set");
        if (_quantumVerified) {
            require(_isQuantumProtected[withdrawer], "Quantum not set");
        }
        require(
            verifyLogin(
                withdrawer,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            ),
            "SignKey incorrect"
        );
        require(
            _urTokenAddress == urTokenAddressOfETH ||
                urTokensOfAllowedTokens.contains(_urTokenAddress),
            "invalid urToken"
        );

        uint256 balance = IurToken(_urTokenAddress).balanceOf(withdrawer);
        require(_amount > 0, "invalid amount");
        require(balance >= _amount, "Not enough");

        require(
            IurToken(_urTokenAddress).burnAndUnprotect(withdrawer, _amount),
            "withdraw failed"
        );

        // Transfer the amount based on the token type
        if (_urTokenAddress == urTokenAddressOfETH) {
            payable(withdrawer).transfer(_amount);
        } else {
            IERC20(tokenAdressForurToken[_urTokenAddress]).transfer(
                withdrawer,
                _amount
            );
        }

        // Update the deposited amounts
        uint256 previousAmount = depositedAmountOfUserAgainsturToken[
            withdrawer
        ][_urTokenAddress];
        depositedAmountOfUserAgainsturToken[withdrawer][_urTokenAddress] =
            previousAmount -
            _amount;

        // Update the current period deposits
        uint256 currentPeriod = getCurrentPeriodFor369hours();
        if (
            depositedAmountOfUserAgainsturToken[withdrawer][_urTokenAddress] <
            depositedAmountOfUserAgainsturTokenForPeriod[withdrawer][
                _urTokenAddress
            ][currentPeriod]
        ) {
            depositedAmountOfUserAgainsturTokenForPeriod[withdrawer][
                _urTokenAddress
            ][currentPeriod] = depositedAmountOfUserAgainsturToken[withdrawer][
                _urTokenAddress
            ];
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

        require(_isSignKeySetOf[caller], "SignKey not set");
        if (_quantumVerified) {
            require(_isQuantumProtected[caller], "Quantum not set");
        }
        require(
            verifyLogin(
                caller,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            ),
            "SignKey incorrect"
        );
        require(_amount > 0, "Invalid amount");
        require(
            _urTokenAddress == urTokenAddressOfETH ||
                urTokensOfAllowedTokens.contains(_urTokenAddress),
            "invalid urToken"
        );

        // Transfer the tokens
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
        require(
            (!(_isSignKeySetOf[caller]) && !(_isMasterKeySetOf[caller])),
            "SignKey set"
        );
        _masterKeyOf[caller] = keccak256(bytes(_masterKey));
        _isMasterKeySetOf[caller] = true;
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
        _isQuantumProtected[caller] = false;
        _isSignKeySetOf[caller] = true;
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
        require(msg.value >= requiredETHFee);
        // transfer fee to the fee receivers addresses
        uint256 thirtyPercentShare = (fee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
        payable(ur369gift_30).transfer(thirtyPercentShare);
        payable(ur369_30).transfer(thirtyPercentShare);
        payable(ur369impact_30).transfer(thirtyPercentShare);
        payable(ur369devs_10).transfer(fee - (thirtyPercentShare * 3));

        require(
            (!(_isSignKeySetOf[caller]) && !(_isMasterKeySetOf[caller])),
            "SignKey set"
        );
        _masterKeyOf[caller] = keccak256(bytes(_masterKey));
        _isMasterKeySetOf[caller] = true;
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
        _isQuantumProtected[caller] = true;
        _isSignKeySetOf[caller] = true;
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
        require(
            ((_isSignKeySetOf[caller]) && (_isMasterKeySetOf[caller])),
            "User not registered"
        );
        require(
            _masterKeyOf[caller] == keccak256(bytes(_masterKey)),
            "incorrect masterkey"
        );

        if (_isQuantumProtected[caller]) {
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

    // function to change sign key type from simple to quantum
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
        require(!_isQuantumProtected[caller], "Already Quantum protected");
        require(
            ((_isSignKeySetOf[caller]) && (_isMasterKeySetOf[caller])),
            "not reg"
        );
        require(
            _masterKeyOf[caller] == keccak256(bytes(_masterKey)),
            "wrong masterkey"
        );
        // change from simple to quantum
        uint256 fee = msg.value;
        uint256 requiredETHFee = calculateETHFee(quantumActivationFee);
        require(msg.value >= requiredETHFee);
        // transfer fee to the fee receivers addresses
        uint256 thirtyPercentShare = (fee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
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
        _isQuantumProtected[caller] = true;
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
     * @dev Returns the addresses of all urTokens of the allowed tokens.
     *
     * This function returns an array of the addresses of all urTokens that correspond to currently allowed tokens.
     *
     * @return An array of addresses representing uTokens of allowed tokens.
     */
    function allurTokensOfAllowedTokens()
        public
        view
        returns (address[] memory)
    {
        return urTokensOfAllowedTokens.values();
    }

    /**
     * @dev Returns the count of all urTokens of the allowed tokens.
     *
     * This function returns the total count of urTokens that correspond to currently allowed tokens.
     *
     * @return A number representing the count of urTokens of allowed tokens.
     */
    function allurTokensOfAllowedTokensCount() public view returns (uint256) {
        return urTokensOfAllowedTokens.length();
    }

    /**
     * @dev Returns the address of the token corresponding to the given urToken.
     *
     * This function takes the address of a urToken and returns the address of the corresponding token.
     *
     * @param _urToken The address of the urToken.
     *
     * @return The address of the token that corresponds to the given urToken.
     */
    function getTokenAddressForurToken(
        address _urToken
    ) public view returns (address) {
        return tokenAdressForurToken[_urToken];
    }

    /**
     * @dev Returns the address of the urToken corresponding to the given token.
     *
     * This function takes the address of a token and returns the address of the corresponding urToken.
     *
     * @param _token The address of the token.
     *
     * @return The address of the urToken that corresponds to the given token.
     */
    function geturTokenAddressForToken(
        address _token
    ) public view returns (address) {
        return urTokenAddressForToken[_token];
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
        address urTokenAddress;
        uint256 amount;
    }

    function getDepositDetailsForUser(
        address _depositor
    ) public view returns (DepositsOfUser[] memory depositDetails) {
        address[] memory totalurTokens = depositedurTokensOf[_depositor]
            .values();
        uint256 tokensCount = totalurTokens.length;

        depositDetails = new DepositsOfUser[](tokensCount);
        if (tokensCount > 0) {
            for (uint256 i; i < tokensCount; i++) {
                depositDetails[i] = DepositsOfUser({
                    urTokenAddress: totalurTokens[i],
                    amount: depositedAmountOfUserAgainsturToken[_depositor][
                        totalurTokens[i]
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

        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(previousTimePeriod, deployTime))
        ) % depositorsLength;

        return depositors[randomNumber];
    }

    /**
     * @dev Returns the addresses of all urTokens deposited by a specific depositor.
     *
     * This function takes the address of an depositor and returns an array of addresses
     * representing all urTokens that the depositor has deposited in.
     *
     * @param _depositor The address of the depositor.
     *
     * @return depositedurTokens An array of urToken addresses in which the depositor has deposited.
     */
    function getDepositedurTokensForUser(
        address _depositor
    ) public view returns (address[] memory depositedurTokens) {
        depositedurTokens = depositedurTokensOf[_depositor].values();
    }

    /**
     * @dev Returns the addresses of all urTokens deposited by a specific depositor during a specific period.
     *
     * This function takes the address of an depositor and a period, and returns an array of addresses
     * representing all urTokens that the depositor has deposited in during the specified period.
     *
     * @param _depositor The address of the depositor.
     * @param _period The period of investment.
     *
     * @return depositedurTokensForPeriod An array of urToken addresses in which the depositor has deposited during the specified period.
     */
    function getDepositedurTokensOfUserForPeriodFor369hours(
        address _depositor,
        uint256 _period
    ) public view returns (address[] memory depositedurTokensForPeriod) {
        depositedurTokensForPeriod = depositedurTokensOfUserForPeriod[
            _depositor
        ][_period].values();
    }

    /**
     * @dev Returns the amount deposited by a specific depositor in a specific urToken during a specific period.
     *
     * This function takes the address of an depositor, a urToken, and a period, and returns the amount
     * that the depositor has deposited in the specified urToken during the specified period.
     *
     * @param _depositor The address of the depositor.
     * @param _urToken The address of the urToken.
     * @param _period The period of deposit.
     *
     * @return depositedAmount The amount deposited by the depositor in the specified urToken during the specified period.
     */
    function getDepositedAmountOfUserAgainsturTokenForPeriodFor369hours(
        address _depositor,
        address _urToken,
        uint256 _period
    ) public view returns (uint256 depositedAmount) {
        depositedAmount = depositedAmountOfUserAgainsturTokenForPeriod[
            _depositor
        ][_urToken][_period];
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
        address[] memory totalurTokens = depositedurTokensOfUserForPeriod[
            _depositor
        ][_period].values();
        uint256 tokensCount = totalurTokens.length;

        depositDetails = new DepositsForPeriodOfUser[](tokensCount);
        if (tokensCount > 0) {
            for (uint256 i; i < tokensCount; i++) {
                depositDetails[i] = DepositsForPeriodOfUser({
                    urTokenAddress: totalurTokens[i],
                    amount: depositedAmountOfUserAgainsturTokenForPeriod[
                        _depositor
                    ][totalurTokens[i]][_period]
                });
            }
        }
    }

    //  Retrieves the currency type associated with a urToken.
    function getCurrencyOfurToken(
        address _urToken
    ) public view returns (string memory currency) {
        return currencyOfurToken[_urToken];
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

    // functions related fetching live prices
    function calculateETHFee(
        uint256 _feeInStableCoin
    ) public view returns (uint256) {
        int256 ethPriceInUSD = getLatestPrice(); // Price of 1 ETH in USD (with 8 decimals)
        require(ethPriceInUSD > 0, "wrong from oracle");

        uint256 ethFee = (_feeInStableCoin * 1e8) / uint256(ethPriceInUSD); // Conversion to ETH amount
        return ethFee;
    }

    // Get the latest price of ETH in USD (used to calculate equivalent ETH for stablecoin fee)
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
