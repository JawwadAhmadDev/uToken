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
        mapping(bytes32 => uint256) _positions;
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: contracts/uxTokenContract.sol

pragma solidity ^0.8.18;

interface IuxToken {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
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
    uint256 private unlocked = 1;
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
        for (uint256 i; i < _whiteListAddressess.length; i++) {
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

pragma solidity ^0.8.24;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(
        uint256 a,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (
                    unsignedRoundsUp(rounding) && 1 << (result << 3) < value
                        ? 1
                        : 0
                );
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(
        int256 value
    ) internal pure returns (string memory) {
        return
            string.concat(
                value < 0 ? "-" : "",
                toString(SignedMath.abs(value))
            );
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return
            bytes(a).length == bytes(b).length &&
            keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: @openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.20;

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(
        bytes32 messageHash
    ) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(
        bytes memory message
    ) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    "\x19Ethereum Signed Message:\n",
                    bytes(Strings.toString(message.length)),
                    message
                )
            );
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(
        address validator,
        bytes memory data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}

// File: @openzeppelin/contracts/utils/StorageSlot.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(
        bytes32 slot
    ) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(
        bytes32 slot
    ) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(
        bytes32 slot
    ) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(
        bytes32 slot
    ) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(
        bytes32 slot
    ) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(
        string storage store
    ) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(
        bytes32 slot
    ) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(
        bytes storage store
    ) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// File: @openzeppelin/contracts/utils/ShortStrings.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.20;

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant FALLBACK_SENTINEL =
        0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(
        string memory str
    ) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(
        string memory value,
        string storage store
    ) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(
        ShortString value,
        string storage store
    ) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using
     * {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(
        ShortString value,
        string storage store
    ) internal view returns (uint256) {
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// File: @openzeppelin/contracts/interfaces/IERC5267.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.20;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// File: @openzeppelin/contracts/utils/cryptography/EIP712.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.20;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding scheme specified in the EIP requires a domain separator and a hash of the typed structured data, whose
 * encoding is very generic and therefore its implementation in Solidity is not feasible, thus this contract
 * does not implement the encoding itself. Protocols need to implement the type-specific encoding they need in order to
 * produce the hash of their typed data using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the {_domainSeparatorV4} function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    _hashedName,
                    _hashedVersion,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {IERC-5267}.
     */
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _name which is an immutable value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    function _EIP712Name() internal view returns (string memory) {
        return _name.toStringWithFallback(_nameFallback);
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _version which is an immutable value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    function _EIP712Version() internal view returns (string memory) {
        return _version.toStringWithFallback(_versionFallback);
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (
                address(0),
                RecoverError.InvalidSignatureLength,
                bytes32(signature.length)
            );
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(
            hash,
            signature
        );
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs &
                bytes32(
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                );
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(
            hash,
            r,
            vs
        );
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(
            hash,
            v,
            r,
            s
        );
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// File: contracts/PasswordManager.sol

pragma solidity ^0.8.24;

contract PasswordManager is EIP712 {
    struct PasswordData {
        bytes32 keccakHash; // Keccak256 hash of the password.
        bytes quantumSignature; // Quantum-resistant signature.
        bytes quantumPublicKey; // Public key for quantum verification.
    }
    bytes32 public constant PASSWORD_HASH_TYPEHASH =
        keccak256(
            "PasswordHash(address signer,string customMessage,string password,bytes32 passwordHash,uint256 deadline)"
        );

    mapping(address => PasswordData) public passwordDataOf;

    event UserRegistered(address indexed user, bool isQuamtumProtected);

    error ERC2612ExpiredSignature(uint256 deadline);

    constructor(string memory appName) EIP712(appName, "1") {}

    function register(
        address user,
        bool isQuantumProtected,
        string memory customMessage,
        string memory password,
        bytes32 keccakHash,
        uint256 deadline,
        bytes memory ethSignature,
        bytes memory quantumSignature,
        bytes memory quantumPublicKey
    ) internal {
        require(
            passwordDataOf[user].keccakHash == 0 &&
                passwordDataOf[user].quantumSignature.length == 0,
            "Already registered"
        );

        // Verify that the Ethereum signature is correct
        require(
            verifySignature(
                user,
                customMessage,
                password,
                keccakHash,
                deadline,
                ethSignature
            ),
            "Invalid Ethereum signature"
        );
        if (isQuantumProtected) {
            passwordDataOf[user] = PasswordData(
                keccakHash,
                quantumSignature,
                quantumPublicKey
            );
            emit UserRegistered(user, true);
        } else {
            passwordDataOf[user] = PasswordData(keccakHash, "", "");
            emit UserRegistered(user, false);
        }
    }

    function verifyLogin(
        address user,
        string memory customMessage,
        string memory password,
        bytes32 keccakHash,
        uint256 deadline,
        bytes memory ethSignature
    ) public view returns (bool) {
        bool success = passwordDataOf[user].keccakHash == keccakHash &&
            verifySignature(
                user,
                customMessage,
                password,
                keccakHash,
                deadline,
                ethSignature
            );
        return success;
    }

    function verifySignature(
        address signer,
        string memory customMessage,
        string memory password,
        bytes32 passwordHash,
        uint256 deadline,
        bytes memory ethSignature
    ) public view returns (bool) {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }
        bytes32 typeHash = keccak256(
            abi.encode(
                keccak256(
                    "PasswordHash(address signer,string customMessage,string password,bytes32 passwordHash,uint256 deadline)"
                ),
                signer,
                keccak256(bytes(customMessage)),
                keccak256(bytes(password)),
                passwordHash,
                deadline
            )
        );

        bytes32 digest = _hashTypedDataV4(typeHash);
        address _signer = ECDSA.recover(digest, ethSignature);

        return (_signer != signer) ? false : true;
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

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
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
    mapping(uint256 => mapping(address => uint256))
        private totalRewardAmountForTokenInPeriod; // (period count) => tokenAddress => totalInvestedAmount
    mapping(uint256 => bool) private hasRewardBeenCollectedForPeriod; // (period count) => boolean
    mapping(uint256 => bool) private isDepositedInPeriod; // period count => boolean (to check that in which period some investment is made.

    // mappings to store Sign Key and randomly generated Master key against user.
    mapping(address => bool) private _isQuantumProtected;
    mapping(address => bool) private _isSignKeySetOf;
    mapping(address => bytes32) private _masterKeyOf;
    mapping(address => bool) private _isMasterKeySetOf;

    AggregatorV3Interface public priceFeed; // Chainlink ETH/USD Price Feed

    // tokens addresses.
    address public uxTokenAddressOfETH;
    EnumerableSet.AddressSet private allowedTokens; // total allowed ERC20 tokens
    EnumerableSet.AddressSet private uxTokensOfAllowedTokens; // uxTokens addresses of allowed ERC20 Tokens
    address[] private whiteListAddresses; // whitelist addresss set only once and will be send to all the deployed tokens.

    // salt for create2 opcode.
    uint256 private _salt;

    // fee detial
    uint256 public quantumActivationFee = 3.69 * 1e18;
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
                "INVALID ALLOWED TOKEN ADDRESS"
            );
            require(!allowedTokens.contains(tokenAddress), "Already added");

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

            require(allowedTokens.contains(tokenAddress), "Not Added");

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
        string memory _customMessage,
        string memory _signKey,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) external payable {
        address depositor = msg.sender;

        require(_isSignKeySetOf[depositor], "SignKey not set.");
        if (_quantumVerified) {
            require(_isQuantumProtected[depositor], "Quantum not set.");
        }
        require(
            verifyLogin(
                depositor,
                _customMessage,
                _signKey,
                _signKeyHash,
                _deadline,
                _ethSignature
            ),
            "SignKey incorrect"
        );
        require(_amount > 0, "invalid amount");
        require(
            _uxTokenAddress == uxTokenAddressOfETH ||
                uxTokensOfAllowedTokens.contains(_uxTokenAddress),
            "invalid uxToken address"
        );

        // Calculate deposit fee and remaining amount
        uint256 depositFee = (_amount * benefactionFeePercent) / ZOOM;
        uint256 remaining = _amount - depositFee;

        // Call protect method on uxToken contract
        require(
            IuxToken(_uxTokenAddress).protect(depositor, remaining),
            "deposit failed"
        );

        uint256 currentTimePeriodCount = getCurrentPeriodFor369hours();

        uint256 thirtyPercentShare = (depositFee *
            percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) / ZOOM;
        // Handle fees and deposits
        if (_uxTokenAddress == uxTokenAddressOfETH) {
            require(msg.value > 0, "invalid Ether");

            ETHInPeriod[currentTimePeriodCount] += thirtyPercentShare;
        } else {
            require(
                IERC20(tokenAdressForUxToken[_uxTokenAddress]).transferFrom(
                    depositor,
                    address(this),
                    _amount
                ),
                "TransferFrom failed"
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
        string memory _customMessage,
        string memory _signKey,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) external {
        address withdrawer = msg.sender;

        require(_isSignKeySetOf[withdrawer], "SignKey not set.");
        if (_quantumVerified) {
            require(_isQuantumProtected[withdrawer], "Quantum not set.");
        }
        require(
            verifyLogin(
                withdrawer,
                _customMessage,
                _signKey,
                _signKeyHash,
                _deadline,
                _ethSignature
            ),
            "SignKey incorrect"
        );
        require(
            _uxTokenAddress == uxTokenAddressOfETH ||
                uxTokensOfAllowedTokens.contains(_uxTokenAddress),
            "invalid uxToken"
        );

        uint256 balance = IuxToken(_uxTokenAddress).balanceOf(withdrawer);
        require(_amount > 0, "invalid amount");
        require(balance >= _amount, "Not enough tokens");

        require(
            IuxToken(_uxTokenAddress).burnAndUnprotect(withdrawer, _amount),
            "withdraw failed"
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
                "transfer failed"
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
        string memory _customMessage,
        string memory _signKey,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) external returns (bool) {
        address caller = msg.sender;

        require(_isSignKeySetOf[caller], "SignKey not set yet.");
        if (_quantumVerified) {
            require(_isQuantumProtected[caller], "Quantum not set yet.");
        }
        require(
            verifyLogin(
                caller,
                _customMessage,
                _signKey,
                _signKeyHash,
                _deadline,
                _ethSignature
            ),
            "SignKey incorrect"
        );
        require(_amount > 0, "Factory: Invalid amount");
        require(
            _uxTokenAddress == uxTokenAddressOfETH ||
                uxTokensOfAllowedTokens.contains(_uxTokenAddress),
            "invalid uxToken"
        );

        // Transfer the tokens
        require(
            IuxToken(_uxTokenAddress).transfer(_to, _amount),
            "transfer failed"
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
        string memory _customMessage,
        string memory _signKey,
        bytes32 _signKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature
    ) external {
        address caller = msg.sender;
        require(
            (!(_isSignKeySetOf[caller]) && !(_isMasterKeySetOf[caller])),
            "SignKey already set"
        );
        _masterKeyOf[caller] = keccak256(bytes(_masterKey));
        _isMasterKeySetOf[caller] = true;
        register(
            caller,
            false,
            _customMessage,
            _signKey,
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
        string memory _signKey,
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
        payable(ux369gift_30).transfer(thirtyPercentShare);
        payable(ux369_30).transfer(thirtyPercentShare);
        payable(ux369impact_30).transfer(thirtyPercentShare);
        payable(ux369devs_10).transfer(fee - (thirtyPercentShare * 3));

        require(
            (!(_isSignKeySetOf[caller]) && !(_isMasterKeySetOf[caller])),
            "SignKey already set"
        );
        _masterKeyOf[caller] = keccak256(bytes(_masterKey));
        _isMasterKeySetOf[caller] = true;
        register(
            caller,
            true,
            _customMessage,
            _signKey,
            _signKeyHash,
            _deadline,
            _ethSignature,
            _quantumSignature,
            _quamtumPublicKey
        );
        _isQuantumProtected[caller] = true;
        _isSignKeySetOf[caller] = true;
    }

    function changeSignKey(
        string memory _masterKey,
        string memory _customMessage,
        string memory _newSignKey,
        bytes32 _newSignKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature,
        bytes memory _quantumSignature,
        bytes memory _quamtumPublicKey
    ) external payable {
        address caller = msg.sender;
        require(
            ((_isSignKeySetOf[caller]) && (_isMasterKeySetOf[caller])),
            "User not registered yet."
        );
        require(
            _masterKeyOf[caller] == keccak256(bytes(_masterKey)),
            "incorrect master key"
        );

        if (_isQuantumProtected[caller]) {
            register(
                caller,
                true,
                _customMessage,
                _newSignKey,
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
                _customMessage,
                _newSignKey,
                _newSignKeyHash,
                _deadline,
                _ethSignature,
                "",
                ""
            );
            emit SignKeyChanged(caller, block.timestamp, false);
        }
    }

    // function to change sign key type from simple to quantum or from quantum to simple
    function changeSignKeyType(
        string memory _masterKey,
        bool _isAlreadyQuantumProtected,
        string memory _customMessage,
        string memory _newSignKey,
        bytes32 _newSignKeyHash,
        uint256 _deadline,
        bytes memory _ethSignature,
        bytes memory _quantumSignature,
        bytes memory _quamtumPublicKey
    ) external payable {
        address caller = msg.sender;
        require(
            ((_isSignKeySetOf[caller]) && (_isMasterKeySetOf[caller])),
            "User not registered yet."
        );
        require(
            _masterKeyOf[caller] == keccak256(bytes(_masterKey)),
            "incorrect master key"
        );

        if (_isAlreadyQuantumProtected && _isQuantumProtected[caller]) {
            // change from quantum to simple
            register(
                caller,
                false,
                _customMessage,
                _newSignKey,
                _newSignKeyHash,
                _deadline,
                _ethSignature,
                "",
                ""
            );
            _isQuantumProtected[caller] = false;
            emit SignKeyChanged(caller, block.timestamp, false);
        } else {
            // change from simple to quantum
            uint256 fee = msg.value;
            uint256 requiredETHFee = calculateETHFee(quantumActivationFee);
            require(msg.value >= requiredETHFee);
            // transfer fee to the fee receivers addresses
            uint256 thirtyPercentShare = (fee *
                percentOfPublicGoodRecipientCandidateAndSocialGoodAddress) /
                ZOOM;
            payable(ux369gift_30).transfer(thirtyPercentShare);
            payable(ux369_30).transfer(thirtyPercentShare);
            payable(ux369impact_30).transfer(thirtyPercentShare);
            payable(ux369devs_10).transfer(fee - (thirtyPercentShare * 3));
            register(
                caller,
                true,
                _customMessage,
                _newSignKey,
                _newSignKeyHash,
                _deadline,
                _ethSignature,
                _quantumSignature,
                _quamtumPublicKey
            );
            emit SignKeyChanged(caller, block.timestamp, true);
            _isQuantumProtected[caller] = true;
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
            for (uint256 i; i < tokensCount; i++) {
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

        uint256 randomNumber = uint256(
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
            for (uint256 i; i < tokensCount; i++) {
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
        require(ethPriceInUSD > 0, "Invalid price from oracle");

        uint256 ethFee = (_feeInStableCoin * 1e8) / uint256(ethPriceInUSD); // Conversion to ETH amount
        return ethFee;
    }

    // Get the latest price of ETH in USD (used to calculate equivalent ETH for stablecoin fee)
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
