// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPasswordManager {
    struct PasswordData {
        bytes32 keccakHash; // Keccak256 hash of the password.
        bytes quantumSignature; // Quantum-resistant signature.
        bytes quantumPublicKey; // Public key for quantum verification.
    }

    // View functions
    function verifyLogin(
        address user,
        string memory customMessage,
        bytes32 keccakHash,
        uint256 deadline,
        bytes memory ethSignature
    ) external view returns (bool);

    function verifySignature(
        address signer,
        string memory customMessage,
        bytes32 passwordHash,
        uint256 deadline,
        bytes memory ethSignature
    ) external view returns (bool);

    function getPasswordData(
        address user
    )
        external
        view
        returns (
            bytes32 keccakHash,
            bytes memory quantumSignature,
            bytes memory quantumPublicKey
        );

    // write functions
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
    ) external;

    // Events
    event UserRegistered(address indexed user, bool isQuamtumProtected);

    // Errors
    error ERC2612ExpiredSignature(uint256 deadline);
    error NotRegistered();
    error InvalidSignature();
}
