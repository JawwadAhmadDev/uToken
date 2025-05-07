// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IPasswordManager.sol";

contract PasswordManager is IPasswordManager, EIP712 {
    bytes32 public constant PASSWORD_HASH_TYPEHASH =
        keccak256(
            "PasswordHash(address signer,string customMessage,bytes32 passwordHash,uint256 deadline)"
        );

    mapping(address => PasswordData) public passwordDataOf;

    error ERC2612ExpiredSignature(uint256 deadline);
    error NotRegistered();
    error InvalidSignature();

    constructor(string memory appName) EIP712(appName, "1") {}

    function register(
        address user,
        bool isQuantumProtected,
        bool isChangeSignKeyRequest,
        string memory customMessage,
        bytes32 keccakHash,
        uint256 deadline,
        bytes memory ethSignature,
        bytes memory quantumSignature,
        bytes memory quantumPublicKey
    ) internal {
        if (isChangeSignKeyRequest) {
            if (passwordDataOf[user].keccakHash == 0) {
                revert NotRegistered();
            }
        } else {
            if (
                passwordDataOf[user].keccakHash != 0 &&
                passwordDataOf[user].quantumSignature.length != 0
            ) {
                revert NotRegistered();
            }
        }

        // Verify that the Ethereum signature is correct
        if (
            !verifySignature(
                user,
                customMessage,
                keccakHash,
                deadline,
                ethSignature
            )
        ) {
            revert InvalidSignature();
        }

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
        bytes32 keccakHash,
        uint256 deadline,
        bytes memory ethSignature
    ) public view override returns (bool) {
        bool success = passwordDataOf[user].keccakHash == keccakHash &&
            verifySignature(
                user,
                customMessage,
                keccakHash,
                deadline,
                ethSignature
            );
        return success;
    }

    function verifySignature(
        address signer,
        string memory customMessage,
        bytes32 passwordHash,
        uint256 deadline,
        bytes memory ethSignature
    ) public view override returns (bool) {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }
        bytes32 typeHash = keccak256(
            abi.encode(
                keccak256(
                    "PasswordHash(address signer,string customMessage,bytes32 passwordHash,uint256 deadline)"
                ),
                signer,
                keccak256(bytes(customMessage)),
                passwordHash,
                deadline
            )
        );

        bytes32 digest = _hashTypedDataV4(typeHash);
        address _signer = ECDSA.recover(digest, ethSignature);

        return (_signer != signer) ? false : true;
    }

    function getPasswordData(
        address user
    )
        public
        view
        override
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
