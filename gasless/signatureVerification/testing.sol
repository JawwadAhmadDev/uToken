// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Testing {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

     struct MessageForWithdraw {
        address relayer;
        uint256 amount;
        string message;
    }

    struct MessageForTransfer {
        address relayer;    
        address to;
        uint256 amount;
        string message;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant MESSAGE_TYPEHASH_ForWithdraw = keccak256(
        "Message(address relayer,uint256 amount,string message)"
    );

    bytes32 constant MESSAGE_TYPEHASH_forTransfer =
        keccak256(
        "Message(address relayer,address to,uint256 amount,string message)"
    );


    function verifyForWithdraw(address signer, uint256 amount, string memory message, bytes memory signature) public view returns (bool) {
        MessageForWithdraw memory m = MessageForWithdraw({
            relayer: msg.sender,
            amount: amount,
            message: message
        });

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator(),
            keccak256(abi.encode(MESSAGE_TYPEHASH_ForWithdraw, m.relayer, m.amount, keccak256(bytes(m.message))))
        ));

        return recoverSigner(digest, signature) == signer;
    }
    function transferWithPermit(
        // string memory _password,
        // address _uTokenAddress,
        address _to,
        address _signer,
        uint256 _amount,
        string memory _message,
        bytes memory _signature
    ) external view returns (bool) {
        // verifying signature
        require(
            verifyForTransfer(_signer, _to, _amount, _message, _signature),
            "Factory: Invalid Signature"
        );
        return true;
    }

    function verifyForTransfer(address signer, address to, uint256 amount, string memory message, bytes memory signature) public view returns (bool) {
        MessageForTransfer memory m = MessageForTransfer({
            relayer: msg.sender,
            to: to,
            amount: amount,
            message: message
        });

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator(),
            keccak256(abi.encode(MESSAGE_TYPEHASH_forTransfer, m.relayer, m.to, m.amount, keccak256(bytes(m.message))))
        ));

        return recoverSigner(digest, signature) == signer;
    }


    function domainSeparator() internal view returns (bytes32) {
        // You should define your domain values here
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes("Testing")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    function recoverSigner(
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(digest, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (r, s, v);
    }
}
