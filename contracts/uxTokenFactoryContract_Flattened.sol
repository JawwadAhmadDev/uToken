// SDPX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata
    ) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

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
        return set._positions[value] != 0;
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

// File: contracts/IERC20.sol

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

// File: contracts/uxTokenContract.sol

pragma solidity ^0.8.18;

interface IuxToken {
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

contract uxTokenContract is IuxToken {
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

    // Re-entracy attack
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "uxWTokenForETH: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    // modifier: will be applied on the functions which can only be called from factory.
    // such as deposit and withdraw.
    modifier onlyFactory() {
        require(msg.sender == factory, "uxWTokenForETH: NOT AUTHORIZED");
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
        for (uint i; i < _whiteListAddressess.length; i++) {
            whiteList.add(_whiteListAddressess[i]);
        }
    }

    // function to take ethers and transfer uxTokens
    function protect(
        address _owner,
        uint256 _amount
    ) external onlyFactory returns (bool) {
        _mint(_owner, _amount);
        return true;
    }

    // function to take uxTokens and send Ethers back
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

contract PasswordManager {
    struct PasswordData {
        bytes32 keccakHash; // Keccak256 hash of the password.
        bytes quantumSignature; // Quantum-resistant signature.
        bytes quantumPublicKey; // Public key for quantum verification.
    }

    mapping(address => PasswordData) public passwordDataOf;

    event UserRegistered(address indexed user, bool isQuamtumProtected);
    event LoginAttempt(address indexed user, bool success);

    // Registration functions (same as previously defined)
    function registerWithKeccak(
        address user,
        bytes32 keccakHash,
        bytes memory ethSignature
    ) public {
        require(
            passwordDataOf[user].keccakHash == 0 &&
                passwordDataOf[user].quantumSignature.length == 0,
            "Already registered"
        );

        require(
            verifyEthSignature(user, keccakHash, ethSignature),
            "Invalid Ethereum signature"
        );

        passwordDataOf[user] = PasswordData(keccakHash, "", "");

        emit UserRegistered(user, false);
    }

    function registerWithKeccakForChangeSignKey(
        address user,
        bytes32 keccakHash,
        bytes memory ethSignature
    ) public {
        require(
            verifyEthSignature(user, keccakHash, ethSignature),
            "Invalid Ethereum signature"
        );

        passwordDataOf[user] = PasswordData(keccakHash, "", "");

        emit UserRegistered(user, false);
    }

    function registerWithQuantumProtection(
        address user,
        bytes32 keccakHash,
        bytes memory quantumSignature,
        bytes memory quantumPublicKey,
        bytes memory ethSignature
    ) internal {
        require(
            passwordDataOf[user].keccakHash == 0 &&
                passwordDataOf[user].quantumSignature.length == 0,
            "Already registered"
        );

        // Verify that the Ethereum signature is correct
        require(
            verifyEthSignature(user, keccakHash, ethSignature),
            "Invalid Ethereum signature"
        );

        passwordDataOf[user] = PasswordData(
            keccakHash,
            quantumSignature,
            quantumPublicKey
        );

        emit UserRegistered(user, true);
    }

    function registerWithQuantumProtectionForChangeSignKey(
        address user,
        bytes32 keccakHash,
        bytes memory quantumSignature,
        bytes memory quantumPublicKey,
        bytes memory ethSignature
    ) internal {
        // Verify that the Ethereum signature is correct
        require(
            verifyEthSignature(user, keccakHash, ethSignature),
            "Invalid Ethereum signature"
        );

        passwordDataOf[user] = PasswordData(
            keccakHash,
            quantumSignature,
            quantumPublicKey
        );

        emit UserRegistered(user, true);
    }

    // Verify login attempt
    function verifyLogin_KeccakHash(
        address user,
        bytes32 keccakHash,
        bytes memory ethSignature
    ) public view returns (bool) {
        bool success = passwordDataOf[user].keccakHash == keccakHash &&
            verifyEthSignature(user, keccakHash, ethSignature);
        return success;
    }

    function verifyLogin_Quantum(
        address user,
        bool quantumVerified,
        bytes32 keccakHash,
        bytes memory ethSignature
    ) public view returns (bool) {
        bool success = quantumVerified &&
            passwordDataOf[user].keccakHash == keccakHash &&
            verifyEthSignature(user, keccakHash, ethSignature);
        return success;
    }

    // Verify the Ethereum signature
    function verifyEthSignature(
        address user,
        bytes32 hashedPassword,
        bytes memory ethSignature
    ) internal pure returns (bool) {
        // Prefix the hashed password with "\x19Ethereum Signed Message:\n32" to mimic web3.eth.sign behavior
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedPassword)
        );

        // Recover the signer's address from the Ethereum signature
        address signer = recoverSigner(messageHash, ethSignature);

        // Return true if the recovered address matches the user
        return signer == user;
    }

    // Recover the signer's address using ecrecover
    function recoverSigner(
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract r, s, and v from the signature
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Perform ecrecover operation
        return ecrecover(messageHash, v, r, s);
    }

    // get password details of the user
    function getPasswordData(
        address user
    )
        public
        view
        returns (
            bytes32 keccakHash,
            bytes memory quantumSignature,
            bytes memory quantumPublicKey
        )
    {
        PasswordData memory _userData = passwordDataOf[user];
        return (
            _userData.keccakHash,
            _userData.quantumSignature,
            _userData.quantumPublicKey
        );
    }
}

// File: contracts/uxTokenFactoryContract.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import "./SafeMath.sol";

contract uxTokenFactoryContract is Ownable, PasswordManager {
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
    mapping(address => bool) private _isQuantumProtected;
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
    address public ux369gift_30 = 0xBe9ECB5353A3Db50DE7d50d7B85986D8c3A845A1;
    address public ux369impact_30 = 0x822dbBB741B82d9f8c6F22Cb414b735817cd42EA;
    address public ux369_30 = 0xcE14e3556FF59C83F849D0a4082258000FA23D30;
    address public ux369devs_10 = 0x29817e172E0d798dCc052f87a486fEd529c015C3;

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

    function removeAllowedTokens(
        address[] memory _allowedTokens
    ) external onlyOwner {
        uint256 length = _allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = _allowedTokens[i]; // Store in a local variable

            require(allowedTokens.contains(tokenAddress), "Factory: Not Added");

            allowedTokens.remove(tokenAddress);
            uxTokensOfAllowedTokens.remove(
                uxTokenAddressForToken[tokenAddress]
            );

            emit TokenRemoved(tokenAddress);
        }
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
        address _uxTokenAddress,
        uint256 _amount,
        bool _quantumVerified,
        bytes32 _signKey,
        bytes memory ethSignature
    ) external payable {
        address depositor = msg.sender;

        // Validate sign key
        require(_isSignKeySetOf[depositor], "Factory: SignKey not set yet.");
        if (_isQuantumProtected[depositor]) {
            require(
                verifyLogin_Quantum(
                    depositor,
                    _quantumVerified,
                    _signKey,
                    ethSignature
                ),
                "Factory: SignKey incorrect"
            );
        } else {
            require(
                verifyLogin_KeccakHash(depositor, _signKey, ethSignature),
                "Factory: SignKey incorrect"
            );
        }
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

        uint256 currentTimePeriodCount = getCurrentPeriodFor369hours();

        uint256 thirtyPercentShare = (depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
        // Handle fees and deposits
        if (_uxTokenAddress == uxTokenAddressOfETH) {
            require(msg.value > 0, "Factory: invalid Ether");

            ETHInPeriod[currentTimePeriodCount] += thirtyPercentShare;
        } else {
            require(
                IERC20(tokenAdressForUxToken[_uxTokenAddress]).transferFrom(
                    depositor,
                    address(this),
                    _amount
                ),
                "Factory: TransferFrom failed"
            );

            if (
                !tokensByPeriod[currentTimePeriodCount].contains(
                    tokenAdressForUxToken[_uxTokenAddress]
                )
            ) {
                tokensByPeriod[currentTimePeriodCount].add(
                    tokenAdressForUxToken[_uxTokenAddress]
                );
            }

            totalRewardAmountForTokenInPeriod[currentTimePeriodCount][
                tokenAdressForUxToken[_uxTokenAddress]
            ] += thirtyPercentShare;
        }

        _handleFee(_uxTokenAddress, depositFee, currentTimePeriodCount);

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

    function _handleFee(
        address _uxTokenAddress,
        uint256 _depositFee,
        uint256 _currentTimePeriodCount
    ) internal {
        uint256 thirtyPercentShare = (_depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
        uint256 tenPercentShare = (_depositFee * percentofDevsAddress) / ZOOM;

        // Transfer fees and require success
        require(
            IuxToken(_uxTokenAddress).protect(ux369gift_30, thirtyPercentShare),
            "Transfer to ux369gift_30 failed"
        );
        require(
            IuxToken(_uxTokenAddress).protect(ux369_30, thirtyPercentShare),
            "Transfer to ux369_30 failed"
        );
        require(
            IuxToken(_uxTokenAddress).protect(
                ux369impact_30,
                thirtyPercentShare
            ),
            "Transfer to ux369impact_30 failed"
        );
        require(
            IuxToken(_uxTokenAddress).protect(ux369devs_10, tenPercentShare),
            "Transfer to ux369devs_10 failed"
        );

        // Update period deposits and depositors
        if (!isDepositedInPeriod[_currentTimePeriodCount]) {
            isDepositedInPeriod[_currentTimePeriodCount] = true;
        }

        if (!depositorsByPeriod[_currentTimePeriodCount].contains(msg.sender)) {
            depositorsByPeriod[_currentTimePeriodCount].add(msg.sender);
        }
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
        address _uxTokenAddress,
        uint256 _amount,
        bool _quantumVerified,
        bytes32 _signKey,
        bytes memory ethSignature
    ) external {
        address withdrawer = msg.sender;

        require(_isSignKeySetOf[withdrawer], "Factory: SignKey not set yet.");
        if (_isQuantumProtected[withdrawer]) {
            require(
                verifyLogin_Quantum(
                    withdrawer,
                    _quantumVerified,
                    _signKey,
                    ethSignature
                ),
                "Factory: SignKey incorrect"
            );
        } else {
            require(
                verifyLogin_KeccakHash(withdrawer, _signKey, ethSignature),
                "Factory: SignKey incorrect"
            );
        }
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
        address _uxTokenAddress,
        address _to,
        uint256 _amount,
        bool _quantumVerified,
        bytes32 _signKey,
        bytes memory ethSignature
    ) external returns (bool) {
        address caller = msg.sender;

        require(_isSignKeySetOf[caller], "Factory: SignKey not set yet.");
        if (_isQuantumProtected[caller]) {
            require(
                verifyLogin_Quantum(
                    caller,
                    _quantumVerified,
                    _signKey,
                    ethSignature
                ),
                "Factory: SignKey incorrect"
            );
        } else {
            require(
                verifyLogin_KeccakHash(caller, _signKey, ethSignature),
                "Factory: SignKey incorrect"
            );
        }
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
        string memory _masterKey,
        bytes32 _signKey,
        bytes memory ethSignature
    ) external {
        address caller = msg.sender;
        require(
            (!(_isSignKeySetOf[caller]) && !(_isMasterKeySetOf[caller])),
            "Factory: SignKey already set"
        );
        _masterKeyOf[caller] = keccak256(bytes(_masterKey));
        _isMasterKeySetOf[caller] = true;
        registerWithKeccak(caller, _signKey, ethSignature);
        _isQuantumProtected[caller] = false;
        _isSignKeySetOf[caller] = true;
    }

    function setMasterKeyAndQuantumResistantSignKey(
        string memory _masterKey,
        bytes32 _signKey,
        bool _quantumProtected,
        bytes memory quantumSignature,
        bytes memory quamtumPublicKey,
        bytes memory ethSignature
    ) external {
        address caller = msg.sender;
        require(
            (!(_isSignKeySetOf[caller]) && !(_isMasterKeySetOf[caller])),
            "Factory: SignKey already set"
        );
        _masterKeyOf[caller] = keccak256(bytes(_masterKey));
        _isMasterKeySetOf[caller] = true;
        registerWithQuantumProtection(
            caller,
            _signKey,
            quantumSignature,
            quamtumPublicKey,
            ethSignature
        );
        _isQuantumProtected[caller] = true;
        _isSignKeySetOf[caller] = true;
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
        bytes32 _signKey,
        bool _quantumProtected,
        bytes memory quantumSignature,
        bytes memory quamtumPublicKey,
        bytes memory ethSignature
    ) external {
        address caller = msg.sender;
        require(
            _masterKeyOf[caller] == keccak256(bytes(_masterKey)),
            "Factory: incorrect recovery number"
        );
        if (_quantumProtected) {
            registerWithQuantumProtectionForChangeSignKey(
                caller,
                _signKey,
                quantumSignature,
                quamtumPublicKey,
                ethSignature
            );
            _isQuantumProtected[caller] = true;
        } else {
            registerWithKeccakForChangeSignKey(caller, _signKey, ethSignature);
            _isQuantumProtected[caller] = false;
        }
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
        bool _quantumVerified,
        bytes32 _signKey,
        bytes memory ethSignature
    ) public view returns (bool) {
        if (_isQuantumProtected[_user])
            return
                verifyLogin_Quantum(
                    _user,
                    _quantumVerified,
                    _signKey,
                    ethSignature
                );
        else return verifyLogin_KeccakHash(_user, _signKey, ethSignature);
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
