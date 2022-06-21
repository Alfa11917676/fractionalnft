//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./fractionalSigner.sol";
contract fractionalNft is Ownable, ERC721,SignerImplementation, ReentrancyGuard {

    mapping (address => mapping (uint => bool)) public nonceStatus;
    bool public isRaffleDone;
    uint public currentTokenId = 1;
    address public designatedSigner;
    constructor (string memory _name, string memory _symbol) ERC721(_name,_symbol){}


    function mintTokens(Signer memory signer) external nonReentrant{
        require (getSigner(signer) == designatedSigner,'!Signer');
        require(msg.sender == signer._user, '!User');
        require (block.timestamp <= signer.nonce + 10 minutes, 'Signature Expired');
        require (!nonceStatus[msg.sender][signer.nonce],'Nonce used');
        nonceStatus[msg.sender][signer.nonce] = true;
        for (uint i =0;i<signer.totalTokensToMint;i++) {
            currentTokenId++;
            _mint(msg.sender,currentTokenId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        require (!isRaffleDone || tokenId == 1,'Transfer| Stopped');
        super._beforeTokenTransfer(
         from,
         to,
        tokenId);
    }

}
