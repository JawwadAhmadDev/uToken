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

    function _validateAuth(
        address _user,
        bool _quantumVerified,
        string memory _customMessage,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) internal view {
        if (!isSignKeySet(_user)) revert SignKeyNotSet();
        if (_quantumVerified && !isQuantumProtected(_user))
            revert QuantumNotSet();
        if (
            !verifyLogin(
                _user,
                _customMessage,
                _signKeyHash,
                _deadline,
                _ethSignature
            )
        ) revert SignKeyIncorrect();
    }

    function _handleFeeDistribution(uint256 fee) internal {
        uint256 thirtyPercentShare = (fee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
            100_000;
        payable(ur369gift_30).transfer(thirtyPercentShare);
        payable(ur369_30).transfer(thirtyPercentShare);
        payable(ur369impact_30).transfer(thirtyPercentShare);
        payable(ur369devs_10).transfer(fee - (thirtyPercentShare * 3));
    }

    function _handleFee(
        uint256 _period,
        address _token,
        uint256 _fee,
        bool _isETH
    ) internal {
        if (_isETH) {
            uint256 thirtyPercentShare = (_fee *
                percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
                100_000;
            addETHToPeriod(_period, thirtyPercentShare);
            _handleFeeETH(_fee);
        } else {
            uint256 thirtyPercentShare = (_fee *
                percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
                100_000;
            addTokenToPeriod(_period, _token);
            addTokenRewardToPeriod(_period, _token, thirtyPercentShare);
            _handleFeeToken(_token, _fee);
        }
    }

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

        _validateAuth(
            depositor,
            _quantumVerified,
            _customMessage,
            _signKeyHash,
            _deadline,
            _ethSignature
        );
        if (_amount <= 0) revert InvalidAmount();
        if (!isAllowedurToken(_urTokenAddress)) revert InvalidurToken();

        uint256 currentTimePeriodCount = getCurrentPeriodFor369hours();
        uint256 requiredFee = payInETH
            ? calculateETHFee(protectionFeeInUSD)
            : calculateTokenFee(protectionFeeInUSD, _paymentToken);
        uint256 totalAmount = payInETH
            ? (
                _urTokenAddress == urTokenAddressOfETH
                    ? requiredFee + _amount
                    : requiredFee
            )
            : requiredFee;

        if (payInETH) {
            if (msg.value < totalAmount) revert InvalidAmount();
            if (msg.value > totalAmount)
                payable(depositor).transfer(msg.value - totalAmount);
        } else if (!isAllowedToken(_paymentToken)) revert InvalidAllowedToken();

        _handleFee(
            currentTimePeriodCount,
            _paymentToken,
            requiredFee,
            payInETH
        );
        IurToken(_urTokenAddress).protect(depositor, _amount);

        if (_urTokenAddress != urTokenAddressOfETH) {
            IERC20(getTokenAddressForurToken(_urTokenAddress)).transferFrom(
                depositor,
                address(this),
                _amount
            );
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
        addDepositor(_depositor);
        addDepositedurToken(_depositor, _urTokenAddress);
        addDepositedurTokenForPeriod(_depositor, _period, _urTokenAddress);
        updateDepositedAmount(_depositor, _urTokenAddress, _amount);
        updateDepositedAmountForPeriod(
            _depositor,
            _urTokenAddress,
            _period,
            _amount
        );
        if (_urTokenAddress == urTokenAddressOfETH) {
            updateNativeCurrencyDeposited(_depositor, _amount);
        }
        markPeriodAsDeposited(_period);
        addDepositorToPeriod(_period, _depositor);
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
        if (!isAllowedurToken(_urTokenAddress)) revert InvalidurToken();

        uint256 balance = IurToken(_urTokenAddress).balanceOf(withdrawer);
        if (_amount <= 0 || balance < _amount) revert InvalidAmount();
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
        _validateAuth(
            msg.sender,
            _quantumVerified,
            _customMessage,
            _signKeyHash,
            _deadline,
            _ethSignature
        );
        if (_amount <= 0) revert InvalidAmount();
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
            bytes(""),
            bytes("")
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
        uint256 requiredETHFee = calculateETHFee(quantumActivationFee);
        if (msg.value < requiredETHFee) revert InvalidAmount();

        _handleFeeDistribution(msg.value);
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

        bool isQuantum = isQuantumProtected(caller);
        register(
            caller,
            true,
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
        if (isQuantumProtected(caller)) revert AlreadyQuantomProtected();
        if (!(isSignKeySet(caller) && isMasterKeySet(caller)))
            revert UserNotRegistered();
        if (!isMasterKeyCorrect(caller, _masterKey))
            revert MasterKeyIncorrect();

        uint256 requiredETHFee = calculateETHFee(quantumActivationFee);
        if (msg.value < requiredETHFee) revert InvalidAmount();

        _handleFeeDistribution(msg.value);
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

        return
            depositors[
                uint256(
                    keccak256(abi.encodePacked(previousTimePeriod, deployTime))
                ) % depositorsLength
            ];
    }
}
