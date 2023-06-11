// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "IERC20.sol";
import "uToken.sol";

contract uTokenFactory is Ownable{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    // uToken -> Token Address (against which contract is deployed)
    mapping (address => address) private tokenAdressOf_uToken;
    mapping (address => string) private currencyOf_uToken;
    // token -> uToken
    mapping (address => address) private uTokenAddressOf_token;
    // investorAddress -> All uTokens addresses invested in
    mapping (address => EnumerableSet.AddressSet) private investeduTokensOf;

    // (period count i.e. how much 15 days passed) => depositors addresses.
    mapping (uint256 => EnumerableSet.AddressSet) private depositorsInPeriod;
    // (period count i.e. how much 15 days passed) => depositedTokens address
    mapping (uint256 => EnumerableSet.AddressSet) private tokensInPeriod;
    // (period count i.e. how much 15 days passed) => deposited Ethers in the this period
    mapping (uint256 => uint256) private ethInPeriod;
    // (period count) => tokenAddress => totalInvestedAmount
    mapping (uint256 => mapping (address => uint)) private rewardAmountOfTokenForPeriod;
    // (period count) => boolean
    mapping (uint256 => bool) private isRewardCollectedOfPeriod;
    // period count => boolean (to check that in which period some investment is made.
    mapping (uint256 => bool) private isDepositedInPeriod;

    // mappings to store password and randomly generated phrase against user.
    mapping (address => bytes32) private _passwordOf;
    mapping (address => bool) private _isPasswordSet;
    mapping (address => bytes32) private _recoveryNumberOf;
    mapping (address => bool) private _isRecoveryNumberSet;


    // tokens addresses.
    address public deployedAddressOfEth;
    EnumerableSet.AddressSet private allowedTokens; // total allowed ERC20 tokens
    EnumerableSet.AddressSet private uTokensOfAllowedTokens; // uTokens addresses of allowed ERC20 Tokens

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
    uint256 public constant ZOOM = 1_000_00;  // actually 100. this is divider to calculate percentage

    // fee receiver addresses.
    address public fundAddress = 0x4B7C3C9b2D4aC50969f9A7c1b3BbA490F9088fE7 ; // address which will receive all fees
    address public charityAddress = 0x9317Dc1623d472a588DE7d1f471a79720600019d; // address which will receive share of charity.
    address public forthAddress = 0x9317Dc1623d472a588DE7d1f471a79720600019d;

    event Deposit(address depositor, address token, uint256 amount);
    event Withdraw(address withdrawer, address token, uint256 amount);
    event Reward(address rewardCollector, uint256 period, uint256 ethAmount);

    constructor (address[] memory _allowedTokens) {
        deployTime = block.timestamp;
        deployedAddressOfEth = _deployEth();
        _addAllowedTokens(_allowedTokens);
    }

    function _deployEth() internal returns (address deployedEth) {
        bytes memory bytecode = type(uToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedEth := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IuToken(deployedEth).initialize("uMatic", "uMatic", "Matic");
    }

    function _deployToken(address _token) internal returns (address deployedToken) {
        IERC20 __token = IERC20(_token);
        string memory name = string.concat("u" ,__token.name());
        string memory symbol = string.concat("u", __token.symbol());
        string memory currency = __token.symbol();

        bytes memory bytecode = type(uToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(++_salt));
        assembly {
            deployedToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IuToken(deployedToken).initialize(name, symbol, currency);
    }

    function _addAllowedTokens(address[] memory _allowedTokens) internal {
        for(uint i; i < _allowedTokens.length; i++) {
            address _token = _allowedTokens[i];
            require(_token.isContract(), "uTokenFactory: INVALID ALLOWED TOKEN ADDRESS");
            require(!(allowedTokens.contains(_token)), "Factory: Already added");
            address _deployedAddress = _deployToken(_token);
            tokenAdressOf_uToken[_deployedAddress] = _token;
            uTokenAddressOf_token[_token] = _deployedAddress;
            currencyOf_uToken[_deployedAddress] = IuToken(_deployedAddress).currency();
            allowedTokens.add(_token);
            uTokensOfAllowedTokens.add(_deployedAddress);
        }
    }

    function addAllowedTokens(address[] memory _allowedTokens) external onlyOwner {
        _addAllowedTokens(_allowedTokens);
    }

    function deposit(string memory _password, address _uTokenAddress, uint256 _amount) external payable {
        address depositor = msg.sender;
        require(_isPasswordSet[depositor], "Factory: Password not set yet.");
        require(_passwordOf[depositor] == keccak256(bytes(_password)), "Factory: Password incorrect");
        require(_amount > 0, "Factory: invalid amount");
        require(_uTokenAddress == deployedAddressOfEth || uTokensOfAllowedTokens.contains(_uTokenAddress), "Factory: invalid uToken address");
        uint256 _depositFee = _amount.mul(depositFeePercent).div(ZOOM);
        uint256 _remaining = _amount.sub(_depositFee);

        if(_uTokenAddress == deployedAddressOfEth) {
            require(msg.value > 0, "Factory: invalid Ether");
            // payable(fundAddress).transfer(_depositFee);
            _handleFeeEth(_depositFee);
        } else {
            require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transferFrom(depositor, address(this), _amount), "Factory: TransferFrom failed");
            // require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(fundAddress, _depositFee), "Factory: transfer failed");
            _handleFeeTokens(tokenAdressOf_uToken[_uTokenAddress], _depositFee);
        }
        
        require(IuToken(_uTokenAddress).deposit(_remaining), "Factory: deposit failed");
        if(!(investeduTokensOf[depositor].contains(_uTokenAddress))) investeduTokensOf[depositor].add(_uTokenAddress);

        emit Deposit(depositor, _uTokenAddress, _remaining);
    }

    function _handleFeeEth(uint256 _depositFee) internal {
        uint256 thirtyPercentShare = _depositFee.mul(percentOfCharityWinnerAndFundAddress).div(ZOOM);
        uint256 shareOfWinnerAddress = thirtyPercentShare;
        uint256 shareOfCharityAddress = thirtyPercentShare; // because winner and charity will receive same percentage.
        uint256 shareOfFundAddress = thirtyPercentShare; // because winner and charity will receive same percentage.
        uint256 shareOfForthAddress = _depositFee - (thirtyPercentShare * 3); // it will receive remaining 10% percent

        payable(charityAddress).transfer(shareOfCharityAddress);
        payable(fundAddress).transfer(shareOfFundAddress);
        payable(forthAddress).transfer(shareOfForthAddress);

        uint256 currentTimePeriodCount = ((block.timestamp - deployTime) / timeLimitForReward) + 1;
        if(!isDepositedInPeriod[currentTimePeriodCount])
            isDepositedInPeriod[currentTimePeriodCount] = true;
        
        if(!(depositorsInPeriod[currentTimePeriodCount].contains(msg.sender))){
            depositorsInPeriod[currentTimePeriodCount].add(msg.sender);
        }

        ethInPeriod[currentTimePeriodCount] = ethInPeriod[currentTimePeriodCount].add(shareOfWinnerAddress); 

        // remaining 32% of deposited fee will be in the contract address for reward.
    }

    function _handleFeeTokens(address _tokenAddress, uint256 _depositFee) internal {
        uint256 thirtyPercentShare = _depositFee.mul(percentOfCharityWinnerAndFundAddress).div(ZOOM);
        uint256 shareOfWinnerAddress = thirtyPercentShare;
        uint256 shareOfCharityAddress = thirtyPercentShare; // because winner and charity will receive same percentage.
        uint256 shareOfFundAddress = thirtyPercentShare; // because winner and charity will receive same percentage.
        uint256 shareOfForthAddress = _depositFee - (thirtyPercentShare * 3); // it will receive remaining 10% percent

        IERC20(_tokenAddress).transfer(charityAddress, shareOfCharityAddress);
        IERC20(_tokenAddress).transfer(fundAddress, shareOfFundAddress);
        IERC20(_tokenAddress).transfer(forthAddress, shareOfForthAddress);

        uint256 currentTimePeriodCount = ((block.timestamp - deployTime) / timeLimitForReward) + 1;
        if(!isDepositedInPeriod[currentTimePeriodCount])
            isDepositedInPeriod[currentTimePeriodCount] = true;

        if(!(depositorsInPeriod[currentTimePeriodCount].contains(msg.sender))){
            depositorsInPeriod[currentTimePeriodCount].add(msg.sender);
        }
        if(!(tokensInPeriod[currentTimePeriodCount].contains(_tokenAddress))){

            tokensInPeriod[currentTimePeriodCount].add(_tokenAddress);
        }
        rewardAmountOfTokenForPeriod[currentTimePeriodCount][_tokenAddress] = rewardAmountOfTokenForPeriod[currentTimePeriodCount][_tokenAddress].add(shareOfWinnerAddress);
        // remaining 32% of deposited fee will be in the contract address reward.
    }

    function withdraw(string memory _password, address _uTokenAddress, uint256 _amount) external {
        address withdrawer = msg.sender;
        require(_isPasswordSet[withdrawer], "Factory: Password not set yet.");
        require(_passwordOf[withdrawer] == keccak256(bytes(_password)), "Factory: Password incorrect");
        require(_uTokenAddress == deployedAddressOfEth || uTokensOfAllowedTokens.contains(_uTokenAddress), "Factory: invalid uToken address");
        uint256 balance = IuToken(_uTokenAddress).balanceOf(withdrawer);
        require(_amount > 0, "Factory: invalid amount");
        require(balance >= _amount, "Factory: Not enought tokens");

        require(IuToken(_uTokenAddress).withdraw(_amount), "Factory: withdraw failed");
        
        if(_uTokenAddress == deployedAddressOfEth) {
            payable(withdrawer).transfer(_amount);
        } else {
            require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(withdrawer, _amount), "Factory: transfer failed");
        }

        if(balance.sub(_amount) == 0) investeduTokensOf[withdrawer].remove(_uTokenAddress);

        emit Withdraw(withdrawer, _uTokenAddress, _amount);
    }

    function transfer(string memory _password, address _uTokenAddress, address _to, uint256 _amount) external returns (bool) {
        address caller = msg.sender;
        require(_isPasswordSet[caller], "Factory: Password not set yet.");
        require(_passwordOf[caller] == keccak256(bytes(_password)), "Factory: Password incorrect");
        require(_amount > 0, "Factory: Invalid amount");
        require(_uTokenAddress == deployedAddressOfEth || uTokensOfAllowedTokens.contains(_uTokenAddress), "Factory: invalid uToken address");

        require(IuToken(_uTokenAddress).transfer(_to, _amount), "Factory, transfer failed");
        investeduTokensOf[_to].add(_uTokenAddress);
        return true;
    }

    function setPasswordAndRecoveryNumber(string memory _password, string memory _recoveryNumber) external {
        address caller = msg.sender;
        require((!(_isPasswordSet[caller]) && !(_isRecoveryNumberSet[caller])), "Factory: Already set");
        _passwordOf[caller] = keccak256(bytes(_password));
        _recoveryNumberOf[caller] = keccak256(bytes(_recoveryNumber));
        _isPasswordSet[caller] = true;
        _isRecoveryNumberSet[caller] = true;
    }

    function changePassword(string memory _recoveryNumber, string memory _password) external {
        address caller = msg.sender;
        require(_recoveryNumberOf[caller] == keccak256(bytes(_recoveryNumber)), "Factory: incorrect recovery number");
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
    function changeTimeLimitForRewardCollection(uint256 _time) external onlyOwner {
        timeLimitForRewardCollection = _time;
    }

    // function to withdrawReward for winner
    function withdrawReward() external {
        require(get_currentWinner() == msg.sender, "You are not winner"); // check caller is winner or not

        // check whether user is coming within time limit
        uint256 endPointOfLimit = get_TimeLimitForWinnerForCurrentPeriod();
        uint256 startPointOfLimit = endPointOfLimit.sub(timeLimitForRewardCollection);
        require(block.timestamp > startPointOfLimit && block.timestamp <= endPointOfLimit, "Time limit exceeded");

        uint256 period = get_PreviousPeriod();
        while(!(isRewardCollectedOfPeriod[period])){
            if(!isDepositedInPeriod[period]) {
                if(period == 1) break;
                period--;
                continue;
            }

            uint256 _ethInPeriod = get_ETHInPeriod(period);
            // uint256 _tokensCountInPeriod = get_TokensDepositedInPeriodCount(period);
            if(_ethInPeriod > 0){
                payable(msg.sender).transfer(_ethInPeriod);
            }

            address[] memory _tokens = get_TokensDepositedInPeriod(period);
            uint256 _tokensCount = _tokens.length;
            if(_tokensCount > 0){
                for(uint i; i < _tokensCount; i++){
                    address _token = _tokens[i];
                    IERC20(_token).transfer(msg.sender, get_rewardAmountOfTokenInPeriod(period, _token));
                }
            }

            isRewardCollectedOfPeriod[period] = true;
            emit Reward(msg.sender, period, _ethInPeriod);

            if(period == 1) break;
            period--;
        }
    }
    //--------------------Read Functions -------------------------------//
    //--------------------Allowed Tokens -------------------------------//
    function all_AllowedTokens() public view returns (address[] memory){
        return allowedTokens.values();
    }

    function all_AllowedTokensCount() public view returns (uint256) {
        return allowedTokens.length();
    }

    function all_uTokensOfAllowedTokens() public view returns (address[] memory){
        return uTokensOfAllowedTokens.values();
    }

    function all_uTokensOfAllowedTokensCount() public view returns (uint256) {
        return uTokensOfAllowedTokens.length();
    }

    function get_TokenAddressOfuToken(address _uToken) public view returns (address) {
        return tokenAdressOf_uToken[_uToken];
    }

    function get_uTokenAddressOfToken(address _token) public view returns (address) {
        return uTokenAddressOf_token[_token];
    }

    function getInvested_uTokensOfUser(address _investor) public view returns (address[] memory investeduTokens) {
        investeduTokens = investeduTokensOf[_investor].values();
    }

    function get_CurrencyOfuToken(address _uToken) public view returns (string memory currency) {
        return currencyOf_uToken[_uToken];
    }

    function isPasswordCorrect(address _user, string memory _password) public view returns (bool) {
        return (_passwordOf[_user] == keccak256(bytes(_password)));
    }

    function isRecoveryNumberCorrect(address _user, string memory _recoveryNumber) public view returns (bool) {
        return (_recoveryNumberOf[_user] == keccak256(bytes(_recoveryNumber)));
    }

    function isPasswordSet(address _user) public view returns (bool) {
        return _isPasswordSet[_user];
    }

    function isRecoveryNumberSet(address _user) public view returns (bool) {
        return _isRecoveryNumberSet[_user];
    }

    function IsDepositedInPeriod(uint256 _period) public view returns (bool) {
        return isDepositedInPeriod[_period];
    }

    function get_TokensDepositedInPeriod(uint256 _period) public view returns (address[] memory tokens){
        return tokensInPeriod[_period].values();
    }

    function get_TokensDepositedInPeriodCount(uint256 _period) public view returns (uint256){
        return tokensInPeriod[_period].length();
    }

    function get_DepositorsInPeriod(uint256 _period) public view returns (address[] memory depositors) {
        return depositorsInPeriod[_period].values();
    }

    function get_DepositorsInPeriodCount(uint256 _period) public view returns (uint) {
        return depositorsInPeriod[_period].length();
    }

    function get_ETHInPeriod(uint256 _period) public view returns (uint256) {
        return ethInPeriod[_period];
    }

    function get_rewardAmountOfTokenInPeriod(uint256 _period, address _token) public view returns (uint256) {
        return rewardAmountOfTokenForPeriod[_period][_token];
    }

    function get_CurrentPeriod() public view returns (uint) {
        return ((block.timestamp - deployTime) / timeLimitForReward) + 1; 
    }

    function get_PreviousPeriod() public view returns (uint) {
        return ((block.timestamp - deployTime) / timeLimitForReward);
    }

    function get_CurrentPeriod_StartAndEndTime() public view returns (uint startTime, uint endTime) {
        uint currentTimePeriod = get_CurrentPeriod();

        if(currentTimePeriod == 1){
            startTime = deployTime;
            endTime = deployTime + timeLimitForReward;
        }
        else {
            startTime = deployTime + (timeLimitForReward * (currentTimePeriod - 1)); 
            endTime = timeLimitForReward + startTime;
        }
    }

    function get_TimeLimitForWinnerForCurrentPeriod() public view returns (uint256 rewardTimeLimit){
        (uint startTime,) = get_CurrentPeriod_StartAndEndTime();
        rewardTimeLimit = startTime + timeLimitForRewardCollection;
    }

    function get_currentWinner() public view returns (address) {
        uint256 previousTimePeriod = ((block.timestamp - deployTime) / timeLimitForReward);

        address[] memory depositors = get_DepositorsInPeriod(previousTimePeriod);
        uint256 depositorsLength = get_DepositorsInPeriodCount(previousTimePeriod);

        if(depositorsLength == 0) return address(0);

        uint randomNumber = uint(keccak256(abi.encodePacked(previousTimePeriod, deployTime))) % depositorsLength;

        return depositors[randomNumber];
    }

    function rewardHistoryForEth() public view returns (uint256 ethHistory) {
        uint256 period = get_PreviousPeriod();
        while(!isRewardCollectedOfPeriod[period]){
            ethHistory += get_ETHInPeriod(period);
            if(period == 0) break;
            period--;
        }
    }

    function IsRewardCollectedOfPeriod(uint256 _period) public view returns (bool) {
        return isRewardCollectedOfPeriod[_period];
    }

    struct RewardAgainstToken {
        address token;
        uint amount;
    }
    
    function rewardHistoryForTokensForPeriod(uint256 _period) public view returns (RewardAgainstToken[] memory record){
        address[] memory _tokens = get_TokensDepositedInPeriod(_period);
        uint256 _tokensCount = _tokens.length;
        record = new RewardAgainstToken[](_tokensCount);
        if(_tokensCount > 0){
            for(uint i; i < _tokensCount; i++){
                record[i] = RewardAgainstToken({token: _tokens[i], amount: get_rewardAmountOfTokenInPeriod(_period, _tokens[i])});
            }
        }
    }

    function pendingPeriodsForReward() public view returns (uint[] memory pendingPeriods) {
        uint256 period = get_PreviousPeriod();
        uint[] memory _pendingPeriods = new uint[](period);
        uint256 count;
        while(!isRewardCollectedOfPeriod[period]){
            if(!isDepositedInPeriod[period]) {
                if(period == 0) break;
                period--;
                continue;
            }
            _pendingPeriods[count++] = period;
            if(period == 0) break;
            period--;
        }

        pendingPeriods = new uint[](count);
        uint _count;
        for(uint i; i < _pendingPeriods.length; i++){
            if(_pendingPeriods[i] > 0) {
                pendingPeriods[_count++] = _pendingPeriods[i];
            }
        }
    }
}