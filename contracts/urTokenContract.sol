// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IurToken {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function initialize(
        string memory name,
        string memory symbol,
        string memory currency,
        uint8 decimals,
        address[] memory _whiteListAddressess
    ) external;

    function protect(address _owner, uint256 _amount) external returns (bool);

    function burnAndUnprotect(
        address _owner,
        uint256 _amount
    ) external returns (bool);

    function currency() external view returns (string memory);
}

contract urTokenContract is IurToken {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private whiteList; // set to store whitelist users.
    // whitelist users are those which are not required to set any password to transfer funds or they are also not required to transfer funds from factory only.

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    string private _currency;
    uint8 private _decimals;

    address public immutable factory = msg.sender;

    error Locked();
    error NotFactory();
    error InvalidAddress();
    error ERC20InsufficientBalance(
        address account,
        uint256 balance,
        uint256 amount
    );
    error ERC20InsufficientAllowance(
        address spender,
        uint256 currentAllowance,
        uint256 amount
    );

    // Re-entracy attack
    uint256 private unlocked = 1;
    modifier lock() {
        if (unlocked == 0) {
            revert Locked();
        }
        unlocked = 0;
        _;
        unlocked = 1;
    }
    // modifier: will be applied on the functions which can only be called from factory.
    // such as deposit and withdraw.
    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert NotFactory();
        }
        _;
    }

    // called once at the time of deployment from factory
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory currency_,
        uint8 decimals_,
        address[] memory _whiteListAddressess
    ) public onlyFactory {
        _name = name_;
        _symbol = symbol_;
        _currency = currency_;
        _decimals = decimals_;

        // setting whitelist addresses
        for (uint256 i; i < _whiteListAddressess.length; i++) {
            whiteList.add(_whiteListAddressess[i]);
        }
    }

    // function to take ethers and transfer urTokens
    function protect(
        address _owner,
        uint256 _amount
    ) external onlyFactory returns (bool) {
        _mint(_owner, _amount);
        return true;
    }

    // function to take urTokens and send Ethers back
    function burnAndUnprotect(
        address _owner,
        uint256 _amount
    ) external onlyFactory lock returns (bool) {
        _burn(_owner, _amount);
        return true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function currency() public view virtual override returns (string memory) {
        return _currency;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner;
        if (msg.sender.code.length != 0 && whiteList.contains(msg.sender)) {
            // if caller is contract and is in whitelist.
            owner = msg.sender;
        } else {
            // caller is EOA
            if (msg.sender != factory) {
                revert NotFactory();
            }
            owner = tx.origin;
        }
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = tx.origin;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender;
        if (msg.sender.code.length != 0 && whiteList.contains(msg.sender)) {
            // if caller is contract and is in whitelist.
            spender = msg.sender;
        } else {
            // caller is EOA
            if (msg.sender != factory) {
                revert NotFactory();
            }
            spender = tx.origin;
        }
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual onlyFactory returns (bool) {
        address owner = tx.origin;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual onlyFactory returns (bool) {
        address owner = tx.origin;
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < subtractedValue) {
            revert ERC20InsufficientAllowance(
                spender,
                currentAllowance,
                subtractedValue
            );
        }
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            revert InvalidAddress();
        }
        if (to == address(0)) {
            revert InvalidAddress();
        }

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert ERC20InsufficientBalance(from, fromBalance, amount);
        }
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
        if (account == address(0)) {
            revert InvalidAddress();
        }

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
        if (account == address(0)) {
            revert InvalidAddress();
        }

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        if ((accountBalance < amount)) {
            revert ERC20InsufficientBalance(account, accountBalance, amount);
        }
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) {
            revert InvalidAddress();
        }
        if (spender == address(0)) {
            revert InvalidAddress();
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    amount
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
