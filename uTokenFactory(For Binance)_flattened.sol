// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IuToken {
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
        address[] memory _whiteListAddressess
    ) external;

    function protect(address _owner, uint256 _amount) external returns (bool);

    function burnAndUnprotect(address _owner, uint256 _amount) external returns (bool);

    function currency() external view returns (string memory);
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

contract uToken is IuToken {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private whiteList; // set to store whitelist users.
    // whitelist users are those which are not required to set any password to transfer funds or they are also not required to transfer funds from factory only.

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    string private _currency;

    address public immutable factory = msg.sender;

    // Re-entracy attack
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "uWTokenForEth: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    // modifier: will be applied on the functions which can only be called from factory.
    // such as deposit and withdraw.
    modifier onlyFactory() {
        require(msg.sender == factory, "uWTokenForEth: NOT AUTHORIZED");
        _;
    }

    // called once at the time of deployment from factory
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory currency_,
        address[] memory _whiteListAddressess
    ) public onlyFactory {
        _name = name_;
        _symbol = symbol_;
        _currency = currency_;

        // setting whitelist addresses
        for (uint i; i < _whiteListAddressess.length; i++) {
            whiteList.add(_whiteListAddressess[i]);
        }
    }

    // function to take ethers and transfer uTokens
    function protect(
        address _owner,
        uint256 _amount
    ) external onlyFactory returns (bool) {
        _mint(_owner, _amount);
        return true;
    }

    // function to take uTokens and send Ethers back
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
        return 18;
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
            require(msg.sender == factory, "uWTokenForEth: NOT AUTHORIZED");
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
    ) public virtual override onlyFactory returns (bool) {
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
            require(msg.sender == factory, "uWTokenForEth: NOT AUTHORIZED");
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
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

// File: IERC20.sol

pragma solidity ^0.8.18;

interface IERC20 {
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
}
// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// interface IERC20Permit {
//     /**
//      * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
//      * given ``owner``'s signed approval.
//      *
//      * IMPORTANT: The same issues {IERC20-approve} has related to transaction
//      * ordering also apply here.
//      *
//      * Emits an {Approval} event.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      * - `deadline` must be a timestamp in the future.
//      * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
//      * over the EIP712-formatted function arguments.
//      * - the signature must use ``owner``'s current nonce (see {nonces}).
//      *
//      * For more information on the signature format, see the
//      * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
//      * section].
//      *
//      * CAUTION: See Security Considerations above.
//      */
//     function permit(
//         address owner,
//         address spender,
//         uint256 value,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external;

//     /**
//      * @dev Returns the current nonce for `owner`. This value must be
//      * included whenever a signature is generated for {permit}.
//      *
//      * Every successful call to {permit} increases ``owner``'s nonce by one. This
//      * prevents a signature from being used multiple times.
//      */
//     function nonces(address owner) external view returns (uint256);

//     /**
//      * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
//      */
//     // solhint-disable-next-line func-name-mixedcase
//     function DOMAIN_SEPARATOR() external view returns (bytes32);
// }

// contract VerifySignature {
//     string public contractName;

//     struct EIP712Domain {
//         string name;
//         string version;
//         uint256 chainId;
//         address verifyingContract;
//     }

//     struct MessageForWithdraw {
//         address relayer;
//         uint256 amount;
//         string message;
//     }

//     struct MessageForTransfer {
//         address relayer;
//         address to;
//         uint256 amount;
//         string message;
//     }

//     bytes32 constant EIP712DOMAIN_TYPEHASH =
//         keccak256(
//             "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
//         );

//     bytes32 constant MESSAGE_TYPEHASH_ForWithdraw =
//         keccak256("Message(address relayer,uint256 amount,string message)");

//     bytes32 constant MESSAGE_TYPEHASH_forTransfer =
//         keccak256(
//             "Message(address relayer,address to,uint256 amount,string message)"
//         );

//     constructor(string memory _contractName) {
//         contractName = _contractName;
//     }

//     function verifyForWithdraw(
//         address signer,
//         uint256 amount,
//         string memory message,
//         bytes memory signature
//     ) public view returns (bool) {
//         MessageForWithdraw memory m = MessageForWithdraw({
//             relayer: msg.sender,
//             amount: amount,
//             message: message
//         });

//         bytes32 digest = keccak256(
//             abi.encodePacked(
//                 "\x19\x01",
//                 domainSeparator(),
//                 keccak256(
//                     abi.encode(
//                         MESSAGE_TYPEHASH_ForWithdraw,
//                         m.relayer,
//                         m.amount,
//                         keccak256(bytes(m.message))
//                     )
//                 )
//             )
//         );

//         return recoverSigner(digest, signature) == signer;
//     }

//     function verifyForTransfer(
//         address _relayer,
//         address _signer,
//         address _to,
//         uint256 _amount,
//         string memory _message,
//         bytes memory _signature
//     ) public view returns (bool) {
//         MessageForTransfer memory m = MessageForTransfer({
//             relayer: _relayer,
//             to: _to,
//             amount: _amount,
//             message: _message
//         });

//         bytes32 digest = keccak256(
//             abi.encodePacked(
//                 "\x19\x01",
//                 domainSeparator(),
//                 keccak256(
//                     abi.encode(
//                         MESSAGE_TYPEHASH_forTransfer,
//                         m.relayer,
//                         m.to,
//                         m.amount,
//                         keccak256(bytes(m.message))
//                     )
//                 )
//             )
//         );

//         return recoverSigner(digest, _signature) == _signer;
//     }

//     function domainSeparator() internal view returns (bytes32) {
//         // You should define your domain values here
//         return
//             keccak256(
//                 abi.encode(
//                     EIP712DOMAIN_TYPEHASH,
//                     keccak256(bytes(contractName)),
//                     keccak256(bytes("1")),
//                     block.chainid,
//                     address(this)
//                 )
//             );
//     }

//     function recoverSigner(
//         bytes32 digest,
//         bytes memory signature
//     ) internal pure returns (address) {
//         (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
//         return ecrecover(digest, v, r, s);
//     }

//     function splitSignature(
//         bytes memory sig
//     ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
//         require(sig.length == 65, "invalid signature length");

//         assembly {
//             // first 32 bytes, after the length prefix
//             r := mload(add(sig, 32))
//             // second 32 bytes
//             s := mload(add(sig, 64))
//             // final byte (first byte of the next 32 bytes)
//             v := byte(0, mload(add(sig, 96)))
//         }

//         return (r, s, v);
//     }
// }

pragma solidity ^0.8.18;

contract uTokenFactory is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // all investors of the system
    EnumerableSet.AddressSet private allDepositors;

    // overall investment of a depostitor
    // mapping: depositor => tokens
    mapping(address => EnumerableSet.AddressSet) private depositedTokensOf;
    // mapping: depositor => amount of deposited native currency
    mapping(address => uint256) private nativeCurrencyDepositedBy;
    // mapping: depositor => token => amount
    mapping(address => mapping(address => uint256))
        private depositedAmountOfUserForToken;

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
    uint256 public timeLimitForReward = 129600;
    uint256 public timeLimitForReward_369days = 31881600; // 369 days
    // uint256 public timeLimitForRewardCollection = 10;
    uint256 public deployTime;

    // zoom to handle percentage in the decimals
    uint256 public constant ZOOM = 1_000_00; // actually 100. this is divider to calculate percentage

    // fee receiver addresses.
    address public fundAddress = 0x7c81e517C256666A57424969038b6E91238e798D; // address which will receive all fees
    address public charityAddress = 0x2568C2F2E66cB20D8392bdBad7B93A02Afe3E803; // address which will receive share of charity.
    address public forthAddress = 0xCC18F97a8f88Ae469F4729DC414EF51Cac7550F0;
    address public rewardDistributer =
        0x908640438eE0cBc982E62355f119DCf86F9C7752;

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

    constructor(
        address[] memory _allowedTokens,
        address[] memory _whiteListAddressess
    ) {
        deployTime = block.timestamp;
        whiteListAddresses = _whiteListAddressess;

        deployedAddressOfEth = _deployEth();
        if(_allowedTokens.length != 0)
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
            "uBNB",
            "uBNB",
            "BNB",
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

    // function depositWithPermit(
    //     // string memory _password,
    //     address _uTokenAddress,
    //     address _owner,
    //     uint256 _amount,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external payable {
    //     address depositor = _owner;
    //     // require(_isPasswordSet[depositor], "Factory: Password not set yet.");
    //     // require(
    //     //     _passwordOf[depositor] == keccak256(bytes(_password)),
    //     //     "Factory: Password incorrect"
    //     // );
    //     require(_amount > 0, "Factory: invalid amount");
    //     require(
    //         _uTokenAddress == deployedAddressOfEth ||
    //             uTokensOfAllowedTokens.contains(_uTokenAddress),
    //         "Factory: invalid uToken address"
    //     );
    //     uint256 _depositFee = _amount.mul(depositFeePercent).div(ZOOM);
    //     uint256 _remaining = _amount.sub(_depositFee);

    //     require(
    //         IuToken(_uTokenAddress).deposit(_owner, _remaining),
    //         "Factory: deposit failed"
    //     );
    //     // if (_uTokenAddress == deployedAddressOfEth) {
    //     //     require(msg.value > 0, "Factory: invalid Ether");
    //     //     // payable(fundAddress).transfer(_depositFee);
    //     //     // _handleFeeEth(_depositFee);
    //     // } else {
    //     address tokenAddress = tokenAdressOf_uToken[_uTokenAddress];
    //     IERC20Permit(tokenAddress).permit(
    //         _owner,
    //         address(this),
    //         _amount,
    //         deadline,
    //         v,
    //         r,
    //         s
    //     );
    //     require(
    //         IERC20(tokenAdressOf_uToken[_uTokenAddress]).transferFrom(
    //             _owner,
    //             address(this),
    //             _amount
    //         ),
    //         "Factory: TransferFrom failed"
    //     );
    //     // require(IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(fundAddress, _depositFee), "Factory: transfer failed");
    //     _handleFeeTokens(tokenAdressOf_uToken[_uTokenAddress], _depositFee);
    //     // }

    //     // If this is first time to deposit in the system, add it to the depositors list of the system
    //     if (!(allDepositors.contains(depositor))) allDepositors.add(depositor);

    //     // investment details update for 369 days mappings.

    //     // if native currency then add accordingly otherwise add tokens and add amount of that token
    //     if (_uTokenAddress == deployedAddressOfEth)
    //         nativeCurrencyDepositedBy[depositor] = nativeCurrencyDepositedBy[depositor].add(_amount);
    //     else {
    //         if (!depositedTokensOf[depositor].contains(tokenAddress))
    //             depositedTokensOf[depositor].add(tokenAddress);
    //         depositedAmountOfUserForToken[depositor][tokenAddress] = depositedAmountOfUserForToken[depositor][tokenAddress].add(_amount);
    //     }

    //     if (!(investeduTokensOf[depositor].contains(_uTokenAddress)))
    //         investeduTokensOf[depositor].add(_uTokenAddress);

    //     uint256 _currentPeriod = get_CurrentPeriod();
    //     if (
    //         !(investeduTokens_OfUser_ForPeriod[depositor][_currentPeriod])
    //             .contains(_uTokenAddress)
    //     )
    //         investeduTokens_OfUser_ForPeriod[depositor][_currentPeriod].add(
    //             _uTokenAddress
    //         );
    //     investedAmount_OfUser_AgainstuTokens_ForPeriod[depositor][
    //         _uTokenAddress
    //     ][_currentPeriod] = investedAmount_OfUser_AgainstuTokens_ForPeriod[
    //         depositor
    //     ][_uTokenAddress][_currentPeriod].add(_amount);
    //     emit Deposit(depositor, _uTokenAddress, _currentPeriod, _amount);
    // }

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
    function protect(
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

        require(
            IuToken(_uTokenAddress).protect(depositor, _remaining),
            "Factory: deposit failed"
        );
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

        // If this is first time to deposit in the system, add it to the depositors list of the system
        if (!(allDepositors.contains(depositor))) allDepositors.add(depositor);

        // investment details update for 369 days mappings.

        // if native currency then add accordingly otherwise add tokens and add amount of that token
        if (_uTokenAddress == deployedAddressOfEth)
            nativeCurrencyDepositedBy[depositor] = nativeCurrencyDepositedBy[depositor].add(msg.value);
        else {
            address tokenAddress = tokenAdressOf_uToken[_uTokenAddress];
            if (!depositedTokensOf[depositor].contains(tokenAddress))
                depositedTokensOf[depositor].add(tokenAddress);
            depositedAmountOfUserForToken[depositor][tokenAddress] = depositedAmountOfUserForToken[depositor][tokenAddress].add(_amount);
        }

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
        emit Protect(depositor, _uTokenAddress, _currentPeriod, _remaining);
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

    // function withdrawWithPermit(
    //     // string memory _password,
    //     address _uTokenAddress,
    //     address _signer,
    //     uint256 _amount,
    //     string memory _message,
    //     bytes memory _signature
    // ) external {
    //     // verifying the signature
    //     require(
    //         verifyForWithdraw(_signer, _amount, _message, _signature),
    //         "Factory: Invalid Signature"
    //     );
    //     address withdrawer = _signer;
    //     // require(_isPasswordSet[withdrawer], "Factory: Password not set yet.");
    //     // require(
    //     //     _passwordOf[withdrawer] == keccak256(bytes(_password)),
    //     //     "Factory: Password incorrect"
    //     // );
    //     require(
    //         _uTokenAddress == deployedAddressOfEth ||
    //             uTokensOfAllowedTokens.contains(_uTokenAddress),
    //         "Factory: invalid uToken address"
    //     );
    //     uint256 balance = IuToken(_uTokenAddress).balanceOf(withdrawer);
    //     require(_amount > 0, "Factory: invalid amount");
    //     require(balance >= _amount, "Factory: Not enought tokens");

    //     require(
    //         IuToken(_uTokenAddress).withdraw(withdrawer, _amount),
    //         "Factory: withdraw failed"
    //     );

    //     if (_uTokenAddress == deployedAddressOfEth) {
    //         payable(withdrawer).transfer(_amount);
    //     } else {
    //         require(
    //             IERC20(tokenAdressOf_uToken[_uTokenAddress]).transfer(
    //                 withdrawer,
    //                 _amount
    //             ),
    //             "Factory: transfer failed"
    //         );
    //     }

    //     if (balance.sub(_amount) == 0) {
    //         investeduTokensOf[withdrawer].remove(_uTokenAddress);
    //         investeduTokens_OfUser_ForPeriod[withdrawer][get_CurrentPeriod()]
    //             .remove(_uTokenAddress);
    //     }

    //     emit Withdraw(withdrawer, _uTokenAddress, _amount);
    // }

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
    function burnAndUnprotect(
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
            IuToken(_uTokenAddress).burnAndUnprotect(withdrawer, _amount),
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

        emit BurnAndUnprotect(withdrawer, _uTokenAddress, _amount);
    }

    // address _uTokenAddress,
    //     address _owner,
    //     uint256 _amount,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // function transferWithPermit(
    //     // string memory _password,
    //     address _uTokenAddress,
    //     address _owner,
    //     address _to,
    //     uint256 _amount,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // )
    //     external
    //     returns (
    //         // string memory _message,
    //         // bytes memory _signature
    //         bool
    //     )
    // {
    //     // verifying signature
    //     // require(
    //     //     verifyForTransfer(msg.sender, _signer, _to, _amount, _message, _signature),
    //     //     "Factory: Invalid Signature"
    //     // );
    //     // address caller = _signer;
    //     // require(_isPasswordSet[caller], "Factory: Password not set yet.");
    //     // require(
    //     //     _passwordOf[caller] == keccak256(bytes(_password)),
    //     //     "Factory: Password incorrect"
    //     // );
    //     require(_amount > 0, "Factory: Invalid amount");
    //     require(
    //         _uTokenAddress == deployedAddressOfEth ||
    //             uTokensOfAllowedTokens.contains(_uTokenAddress),
    //         "Factory: invalid uToken address"
    //     );

    //     address tokenAddress = tokenAdressOf_uToken[_uTokenAddress];
    //     IERC20Permit(tokenAddress).permit(
    //         _owner,
    //         address(this),
    //         _amount,
    //         deadline,
    //         v,
    //         r,
    //         s
    //     );
    //     require(
    //         IERC20(tokenAdressOf_uToken[_uTokenAddress]).transferFrom(
    //             _owner,
    //             _to,
    //             _amount
    //         ),
    //         "Factory: TransferFrom failed"
    //     );
    //     // require(
    //     //     IuToken(_uTokenAddress).transfer(_to, _amount),
    //     //     "Factory, transfer failed"
    //     // );
    //     investeduTokensOf[_to].add(_uTokenAddress);
    //     return true;
    // }

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
    function setMasterKeyAndSignKey(
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

    // function to change the time limit for reward of 369 days
    function changeTimeLimitForReward_369days(
        uint256 _time
    ) external onlyOwner {
        timeLimitForReward_369days = _time;
    }

    // function to change time limit for reward collection. only owner is authorized.
    // function changeTimeLimitForRewardCollection(
    //     uint256 _time
    // ) external onlyOwner {
    //     timeLimitForRewardCollection = _time;
    // }

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

    //-------------------- Investment Details for 369 days -------------------------------//
    function getAllDepositors_inSystem()
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

    struct InvestmentOfUser {
        address tokenAddress;
        uint256 amount;
    }

    function getInvestmentDetails_OfUser(
        address _depositor
    ) public view returns (InvestmentOfUser[] memory investmentDetails) {
        address[] memory totalTokens = depositedTokensOf[_depositor].values();
        uint256 tokensCount = totalTokens.length;

        investmentDetails = new InvestmentOfUser[](tokensCount);
        if (tokensCount > 0) {
            for (uint i; i < tokensCount; i++) {
                investmentDetails[i] = InvestmentOfUser({
                    tokenAddress: totalTokens[i],
                    amount: depositedAmountOfUserForToken[_depositor][
                        totalTokens[i]
                    ]
                });
            }
        }
    }

    function get_currentWinner_for369Days() public view returns (address) {
        uint256 previousTimePeriod = ((block.timestamp - deployTime) /
            timeLimitForReward_369days);
    
        if(previousTimePeriod == 0)
            return address(0);

        address[] memory depositors = getAllDepositors_inSystem();
        uint256 depositorsLength = depositors.length;

        if (depositorsLength == 0) return address(0);

        uint randomNumber = uint(
            keccak256(abi.encodePacked(previousTimePeriod, deployTime))
        ) % depositorsLength;

        return depositors[randomNumber];
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

    function get_CurrentPeriod_for369days() public view returns (uint) {
        return
            ((block.timestamp - deployTime) / timeLimitForReward_369days) + 1;
    }

    // Calculates and returns the previous period based on the timestamp of the block, the deploy time of the contract, and the time limit for a reward.
    // The function returns an integer representing the previous period.
    function get_PreviousPeriod() public view returns (uint) {
        return ((block.timestamp - deployTime) / timeLimitForReward);
    }

    function get_PreviousPeriod_for369days() public view returns (uint) {
        return ((block.timestamp - deployTime) / timeLimitForReward_369days);
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

    function get_CurrentPeriod_StartAndEndTime_for369days()
        public
        view
        returns (uint startTime, uint endTime)
    {
        uint currentTimePeriod = get_CurrentPeriod_for369days();

        if (currentTimePeriod == 1) {
            startTime = deployTime;
            endTime = deployTime + timeLimitForReward_369days;
        } else {
            startTime =
                deployTime +
                (timeLimitForReward_369days * (currentTimePeriod - 1));
            endTime = timeLimitForReward_369days + startTime;
        }
    }

    // Retrieves the time limit for the winner to collect their reward for the current period.
    // The function returns a timestamp that represents the deadline for collecting the reward.
    // It is calculated by adding the time limit for reward collection to the start time of the current period.
    // function get_TimeLimitForWinnerForCurrentPeriod()
    //     public
    //     view
    //     returns (uint256 rewardTimeLimit)
    // {
    //     (uint startTime, ) = get_CurrentPeriod_StartAndEndTime();
    //     rewardTimeLimit = startTime + timeLimitForRewardCollection;
    // }

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
        // checking
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
