//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
///@author Alfa
contract SignerImplementation is EIP712Upgradeable{

    string private SIGNING_DOMAIN;
    string private SIGNATURE_VERSION;

    struct Signer{
        address _user;
        uint totalTokensToMint;
        uint nonce;
        bytes signature;
    }

    function __Eighty80StakingContractSigner_init(string memory domain, string memory version) internal initializer {
        SIGNATURE_VERSION = version;
        SIGNING_DOMAIN = domain;
        __EIP712_init(domain, version);
    }

    function getSigner(Signer memory signer) public view returns(address){
        return _verify(signer);
    }

    /// @notice Returns a hash of the given rarity, prepared using EIP712 typed data hashing rules.

    function _hash(Signer memory signer) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("Signer(address _user,uint256 totalTokensToMint,uint256 nonce)"),
                    signer._user,
                    signer.totalTokensToMint,
                    signer.nonce
            )));
    }

    function _verify(Signer memory signer) internal view returns (address) {
        bytes32 digest = _hash(signer);
        return ECDSAUpgradeable.recover(digest, signer.signature);
    }

}