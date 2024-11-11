// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
