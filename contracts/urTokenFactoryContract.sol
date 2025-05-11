// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./urTokenContract.sol";
import "./interfaces/ITokenManager.sol";
import "./interfaces/IFeeManager.sol";
import "./interfaces/IPeriodManager.sol";
import "./interfaces/IUserManager.sol";
import "./interfaces/IPasswordManager.sol";

contract urTokenFactoryContract {
    using Address for address;

    // Contract instances
    ITokenManager public immutable tokenManager;
    IFeeManager public immutable feeManager;
    IPeriodManager public immutable periodManager;
    IUserManager public immutable userManager;
    IPasswordManager public immutable passwordManager;

    // Events
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

    // Errors
    error InvalidurToken();
    error WithdrawFailed();
    error Failed();
    error InvalidAmount();
    error InvalidAllowedToken();
    error SignKeyNotSet();
    error QuantumNotSet();
    error SignKeyIncorrect();
    error SignKeyAlreadySet();
    error UserNotRegistered();
    error MasterKeyIncorrect();
    error AlreadyQuantomProtected();

    constructor(
        address _tokenManager,
        address _feeManager,
        address _periodManager,
        address _userManager,
        address _passwordManager
    ) {
        tokenManager = ITokenManager(_tokenManager);
        feeManager = IFeeManager(_feeManager);
        periodManager = IPeriodManager(_periodManager);
        userManager = IUserManager(_userManager);
        passwordManager = IPasswordManager(_passwordManager);
    }

    function _validateAuth(
        address _user,
        bool _quantumVerified,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) internal view {
        if (!userManager.isSignKeySet(_user)) revert SignKeyNotSet();
        if (_quantumVerified && !userManager.isQuantumProtected(_user))
            revert QuantumNotSet();
        if (
            !passwordManager.verifyLogin(
                _user,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            )
        ) revert SignKeyIncorrect();
    }

    function _handleFee(uint256 _period, uint256 _fee) internal {
        uint256 thirtyPercentShare = (_fee *
            feeManager
                .percentOfPublicGoodRecipientCandidateAndSocialGoodAddress()) /
            100_000;
        periodManager.addETHToPeriod(_period, thirtyPercentShare);
        feeManager.handleFeeETH(_fee);
    }

    function protect(
        address _urTokenAddress,
        uint256 _amount,
        bool _quantumVerified,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature // address _paymentToken
    ) external payable {
        address depositor = msg.sender;

        _validateAuth(
            depositor,
            _quantumVerified,
            _customMessage,
            _signKeyHash,
            _deadline,
            _ethSignature
        );
        if (_amount <= 0) revert InvalidAmount();
        if (!tokenManager.isAllowedurToken(_urTokenAddress))
            revert InvalidurToken();

        uint256 currentTimePeriodCount = periodManager
            .getCurrentPeriodFor369hours();

        uint256 requiredFee = feeManager.calculateETHFee(
            feeManager.protectionFeeInUSD()
        );

        uint256 totalAmount = (_urTokenAddress ==
            tokenManager.urTokenAddressOfETH())
            ? requiredFee + _amount
            : requiredFee;

        if (msg.value < totalAmount) revert InvalidAmount();
        if (msg.value > totalAmount)
            payable(depositor).transfer(msg.value - totalAmount);

        _handleFee(currentTimePeriodCount, requiredFee);

        IurToken(_urTokenAddress).protect(depositor, _amount);

        if (_urTokenAddress != tokenManager.urTokenAddressOfETH()) {
            IERC20(tokenManager.getTokenAddressForurToken(_urTokenAddress))
                .transferFrom(depositor, address(this), _amount);
        }

        _updateDepositState(
            depositor,
            _urTokenAddress,
            _amount,
            currentTimePeriodCount
        );
        emit Protect(
            depositor,
            _urTokenAddress,
            currentTimePeriodCount,
            _amount
        );
    }

    function _updateDepositState(
        address _depositor,
        address _urTokenAddress,
        uint256 _amount,
        uint256 _period
    ) internal {
        userManager.addDepositor(_depositor);
        userManager.addDepositedurToken(_depositor, _urTokenAddress);
        if (_urTokenAddress == tokenManager.urTokenAddressOfETH())
            userManager.updateNativeCurrencyDeposited(_depositor, _amount);
        userManager.addDepositedurToken(_depositor, _urTokenAddress);
        userManager.addDepositedurTokenForPeriod(
            _depositor,
            _period,
            _urTokenAddress
        );

        userManager.updateDepositedAmount(_depositor, _urTokenAddress, _amount);
        userManager.updateDepositedAmountForPeriod(
            _depositor,
            _urTokenAddress,
            _period,
            _amount
        );
        if (_urTokenAddress == tokenManager.urTokenAddressOfETH()) {
            userManager.updateNativeCurrencyDeposited(_depositor, _amount);
        }

        periodManager.markPeriodAsDeposited(_period);
        periodManager.addDepositorToPeriod(_period, _depositor);
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
        _validateAuth(
            withdrawer,
            _quantumVerified,
            _customMessage,
            _signKeyHash,
            _deadline,
            _ethSignature
        );
        if (!tokenManager.isAllowedurToken(_urTokenAddress))
            revert InvalidurToken();

        uint256 balance = IurToken(_urTokenAddress).balanceOf(withdrawer);
        if (_amount <= 0 || balance < _amount) revert InvalidAmount();
        if (!IurToken(_urTokenAddress).burnAndUnprotect(withdrawer, _amount))
            revert WithdrawFailed();

        if (_urTokenAddress == tokenManager.urTokenAddressOfETH()) {
            payable(withdrawer).transfer(_amount);
        } else {
            IERC20(tokenManager.getTokenAddressForurToken(_urTokenAddress))
                .transfer(withdrawer, _amount);
        }

        // Update the deposited amounts
        uint256 previousAmount = userManager
            .getDepositedAmountOfUserAgainsturToken(
                withdrawer,
                _urTokenAddress
            );
        userManager.setDepositedAmount(
            withdrawer,
            _urTokenAddress,
            previousAmount - _amount
        );

        uint256 currentTimePeriodCount = periodManager
            .getCurrentPeriodFor369hours();

        if (
            userManager.getDepositedAmountOfUserAgainsturToken(
                withdrawer,
                _urTokenAddress
            ) <
            userManager
                .getDepositedAmountOfUserAgainsturTokenForPeriodFor369hours(
                    withdrawer,
                    _urTokenAddress,
                    currentTimePeriodCount
                )
        ) {
            userManager.setDepositedAmountForPeriod(
                withdrawer,
                _urTokenAddress,
                currentTimePeriodCount,
                userManager.getDepositedAmountOfUserAgainsturToken(
                    withdrawer,
                    _urTokenAddress
                )
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
    ) external {
        address sender = msg.sender;
        _validateAuth(
            sender,
            _quantumVerified,
            _customMessage,
            _signKeyHash,
            _deadline,
            _ethSignature
        );
        if (!tokenManager.isAllowedurToken(_urTokenAddress))
            revert InvalidurToken();

        uint256 balance = IurToken(_urTokenAddress).balanceOf(sender);
        if (_amount <= 0 || balance < _amount) revert InvalidAmount();
        if (!IurToken(_urTokenAddress).transferFrom(sender, _to, _amount))
            revert Failed();
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
            (!userManager.isSignKeySet(caller) &&
                !userManager.isMasterKeySet(caller)),
            "SignKeyAlreadySet"
        );

        userManager.setMasterKey(caller, _masterKey);
        passwordManager.register(
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
        userManager.setSignKey(caller, false);
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
        uint256 requiredETHFee = feeManager.calculateETHFee(
            feeManager.quantumActivationFee()
        );
        require(msg.value >= requiredETHFee, "InvalidAmount");

        feeManager.handleFeeETH(msg.value);
        require(
            (!userManager.isSignKeySet(caller) &&
                !userManager.isMasterKeySet(caller)),
            "SignKeyAlreadySet"
        );

        userManager.setMasterKey(caller, _masterKey);
        passwordManager.register(
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
        userManager.setSignKey(caller, true);
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
            (userManager.isSignKeySet(caller) &&
                userManager.isMasterKeySet(caller)),
            "User not registered"
        );
        require(
            userManager.isMasterKeyCorrect(caller, _masterKey),
            "MasterKeyIncorrect"
        );

        bool isQuantum = userManager.isQuantumProtected(caller);
        passwordManager.register(
            caller,
            isQuantum,
            false,
            _customMessage,
            _newSignKeyHash,
            _deadline,
            _ethSignature,
            isQuantum ? _quantumSignature : bytes(""),
            isQuantum ? _quamtumPublicKey : bytes("")
        );
        emit SignKeyChanged(caller, block.timestamp, isQuantum);
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
        require(
            !userManager.isQuantumProtected(caller),
            "AlreadyQuantumProtected"
        );
        require(
            (userManager.isSignKeySet(caller) &&
                userManager.isMasterKeySet(caller)),
            "not registered"
        );
        require(
            userManager.isMasterKeyCorrect(caller, _masterKey),
            "MasterKeyIncorrect"
        );

        uint256 requiredETHFee = feeManager.calculateETHFee(
            feeManager.quantumActivationFee()
        );
        require(msg.value >= requiredETHFee, "InvalidAmount");

        feeManager.handleFeeETH(msg.value);
        passwordManager.register(
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
        userManager.setSignKey(caller, true);
    }

    //--------------------Read Functions -------------------------------//

    function getCurrentRecipientCandidateFor369Days()
        public
        view
        returns (address)
    {
        uint256 previousTimePeriod = periodManager
            .getPreviousPeriodFor369days();

        if (previousTimePeriod == 0) return address(0);

        address[] memory depositors = userManager.getAllDepositorsInSystem();
        uint256 depositorsLength = depositors.length;

        if (depositorsLength == 0) return address(0);

        return
            depositors[
                uint256(
                    keccak256(
                        abi.encodePacked(
                            previousTimePeriod,
                            periodManager.deployTime()
                        )
                    )
                ) % depositorsLength
            ];
    }
}
