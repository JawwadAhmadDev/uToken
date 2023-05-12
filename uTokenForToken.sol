// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface IuTokenForToken {
    event Deposited(address depositor, address token, uint256 amount);
    event Withdrawl(address withdrawer, address token, uint256 amount);

    function initialize(address _currencyToken) external;
    function depositToken(uint256 _amount) external;
    function withdrawToken(uint256 _amount) external;
    function currency() external view returns (string memory);
}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}



contract uTokenForToken is ERC20, IuTokenForToken {
    using SafeMath for uint256;

    address public factory;
    address public currencyToken;
    
    uint256 private previousBalance;


    // Re-entracy attack
    uint private unlocked = 1; 
    modifier lock() {
        require(unlocked == 1, 'uTokenForToken: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // modifier: will be applied on the functions which can only be called from factory.
    // such as deposit and withdraw.
    modifier onlyFactory() {
        require(msg.sender == factory, "uTokenForToken: NOT AUTHORIZED");
        _;
    }


    constructor(address _currencyToken) ERC20("uTokenForToken", "UWTT"){
        factory = msg.sender;
        initialize(_currencyToken);
    }

    // called once at the time of deployment from factory
    function initialize(address _currencyToken) public { 
        require(msg.sender == factory, "Invalid initializer");
        currencyToken = _currencyToken;
    }
    

    // function to take ethers and transfer uTokens
    function depositToken(uint256 _amount) external onlyFactory{
        address depositor = tx.origin;
        require(IERC20(currencyToken).balanceOf(address(this)).sub(previousBalance) >= _amount, "uTokenForToken: TRANSFERFROM FAILED");
        require(_amount > 0, "uTokenForToken: INVALID ETH VALUE");

       _mint(depositor, _amount);
        skim(); // update previous balance accordingly.
        
        emit Deposited(depositor, currencyToken, _amount);
    }

    // function to take uTokens and send Ethers back
    function withdrawToken(uint256 _amount) external onlyFactory lock{
        address withdrawer = tx.origin;
        require(_amount > 0, "uTokenForToken: INVALID WITHDRAW AMOUNT");
        require(balanceOf(withdrawer) >= _amount, "uTokenForToken: INVALID WITHDRAW AMOUNT");

        _burn(withdrawer, _amount);
        IERC20(currencyToken).transfer(withdrawer, _amount);
        skim();

        emit Withdrawl(withdrawer, currencyToken, _amount);
    }

    // function to show currency.
    function currency() external view returns (string memory) {
        return IERC20(currencyToken).symbol();
    }


    // to update previous balance, which will be used to check that factory has transferred tokens to this address.
    function skim() internal {
        previousBalance = IERC20(currencyToken).balanceOf(address(this));
    }

    receive() external payable {}
}
