// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "./urTokenContract.sol";
import "./TokenManager.sol";
import "./FeeManager.sol";
import "./PeriodManager.sol";
import "./UserManager.sol";

contract urTokenFactoryContract is
    TokenManager,
    FeeManager,
    PeriodManager,
    UserManager
{
    using Address for address;

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
    error InvalidurToken();
    error WithdrawFailed();
    error Failed();

    constructor(
        string memory _appName,
        address[] memory _allowedTokens,
        address[] memory _whiteListAddresses,
        address _priceFeedAddress
    )
        TokenManager(_whiteListAddresses, _allowedTokens)
        FeeManager(_priceFeedAddress)
        PeriodManager()
        UserManager(_appName)
    {}

    function protect(
        address _urTokenAddress,
        uint256 _amount,
        bool _quantumVerified,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature,
        address _paymentToken
    ) external payable {
        address depositor = msg.sender;
        bool payInETH = _paymentToken == address(0);

        if (!isSignKeySet(depositor)) revert SignKeyNotSet();
        if (_quantumVerified && !isQuantumProtected(depositor))
            revert QuantumNotSet();
        if (
            !verifyLogin(
                depositor,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            )
        ) revert SignKeyIncorrect();
        if (!(_amount > 0)) revert InvalidAmount();
        if (!isAllowedurToken(_urTokenAddress)) revert InvalidurToken();

        uint256 currentTimePeriodCount = getCurrentPeriodFor369hours();
        uint256 requiredETHFee;

        if (payInETH) {
            requiredETHFee = calculateETHFee(protectionFeeInUSD);
            uint256 _totalETHAmount;
            if (_urTokenAddress == urTokenAddressOfETH) {
                _totalETHAmount = requiredETHFee + _amount;
            } else {
                _totalETHAmount = requiredETHFee;
            }

            if (!(msg.value >= _totalETHAmount)) revert InvalidAmount();

            if (msg.value > _totalETHAmount) {
                payable(depositor).transfer(msg.value - _totalETHAmount);
            }

            uint256 thirtyPercentShare = (requiredETHFee *
                percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
                100_000;
            addETHToPeriod(currentTimePeriodCount, thirtyPercentShare);
            _handleFeeETH(requiredETHFee);
        } else {
            if (!isAllowedToken(_paymentToken)) revert InvalidAllowedToken();

            uint256 requiredTokenAmount = calculateTokenFee(
                protectionFeeInUSD,
                _paymentToken
            );
            uint256 thirtyPercentShare = (requiredTokenAmount *
                percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
                100_000;

            addTokenToPeriod(currentTimePeriodCount, _paymentToken);
            addTokenRewardToPeriod(
                currentTimePeriodCount,
                _paymentToken,
                thirtyPercentShare
            );
            _handleFeeToken(_paymentToken, requiredTokenAmount);
        }

        IurToken(_urTokenAddress).protect(depositor, _amount);

        if (_urTokenAddress != urTokenAddressOfETH) {
            IERC20(getTokenAddressForurToken(_urTokenAddress)).transferFrom(
                depositor,
                address(this),
                _amount
            );
        }

        addDepositor(depositor);
        addDepositedurToken(depositor, _urTokenAddress);
        addDepositedurTokenForPeriod(
            depositor,
            currentTimePeriodCount,
            _urTokenAddress
        );
        updateDepositedAmount(depositor, _urTokenAddress, _amount);
        updateDepositedAmountForPeriod(
            depositor,
            _urTokenAddress,
            currentTimePeriodCount,
            _amount
        );

        if (_urTokenAddress == urTokenAddressOfETH) {
            updateNativeCurrencyDeposited(depositor, _amount);
        }

        markPeriodAsDeposited(currentTimePeriodCount);
        addDepositorToPeriod(currentTimePeriodCount, depositor);

        emit Protect(
            depositor,
            _urTokenAddress,
            currentTimePeriodCount,
            _amount
        );
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

        if (!isSignKeySet(withdrawer)) revert SignKeyNotSet();
        if (_quantumVerified && !isQuantumProtected(withdrawer))
            revert QuantumNotSet();
        if (
            !verifyLogin(
                withdrawer,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            )
        ) revert SignKeyIncorrect();
        if (!isAllowedurToken(_urTokenAddress)) revert InvalidurToken();

        uint256 balance = IurToken(_urTokenAddress).balanceOf(withdrawer);
        if (!(_amount > 0)) revert InvalidAmount();
        if (!(balance >= _amount)) revert InvalidAmount();

        if (!IurToken(_urTokenAddress).burnAndUnprotect(withdrawer, _amount))
            revert WithdrawFailed();

        if (_urTokenAddress == urTokenAddressOfETH) {
            payable(withdrawer).transfer(_amount);
        } else {
            IERC20(getTokenAddressForurToken(_urTokenAddress)).transfer(
                withdrawer,
                _amount
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
    ) external returns (bool) {
        address caller = msg.sender;

        if (!isSignKeySet(caller)) revert SignKeyNotSet();
        if (_quantumVerified && !isQuantumProtected(caller))
            revert QuantumNotSet();
        if (
            !verifyLogin(
                caller,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            )
        ) revert SignKeyIncorrect();
        if (!(_amount > 0)) revert InvalidAmount();
        if (!isAllowedurToken(_urTokenAddress)) revert InvalidurToken();

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
        if (isSignKeySet(caller) && isMasterKeySet(caller)) revert SignKeySet();

        setMasterKey(caller, _masterKey);
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
        setSignKey(caller, false);
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
        if (!(msg.value >= requiredETHFee)) revert InvalidAmount();

        uint256 thirtyPercentShare = (fee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
            100_000;
        payable(ur369gift_30).transfer(thirtyPercentShare);
        payable(ur369_30).transfer(thirtyPercentShare);
        payable(ur369impact_30).transfer(thirtyPercentShare);
        payable(ur369devs_10).transfer(fee - (thirtyPercentShare * 3));

        if (isSignKeySet(caller) && isMasterKeySet(caller)) revert SignKeySet();

        setMasterKey(caller, _masterKey);
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
        setSignKey(caller, true);
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
        if (!(isSignKeySet(caller) && isMasterKeySet(caller)))
            revert UserNotRegistered();
        if (!isMasterKeyCorrect(caller, _masterKey))
            revert MasterKeyIncorrect();

        if (isQuantumProtected(caller)) {
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
        if (isQuantumProtected(caller)) revert AlreadyQuantomProtected();
        if (!(isSignKeySet(caller) && isMasterKeySet(caller)))
            revert UserNotRegistered();
        if (!isMasterKeyCorrect(caller, _masterKey))
            revert MasterKeyIncorrect();

        uint256 fee = msg.value;
        uint256 requiredETHFee = calculateETHFee(quantumActivationFee);
        if (!(msg.value >= requiredETHFee)) revert InvalidAmount();

        uint256 thirtyPercentShare = (fee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
            100_000;
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
        setSignKey(caller, true);
    }

    //--------------------Read Functions -------------------------------//

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
}
