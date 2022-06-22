//SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.7;
import "./utils/ERC721Upgradeable.sol";
import "./utils/Ownable.sol";
import './utils/Pausable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./fractionalSigner.sol";
contract fractionalNft is Ownable, Pausable, ERC721Upgradeable, SignerImplementation, ReentrancyGuardUpgradeable {

    mapping (address => mapping (uint => bool)) public nonceStatus;
    bool public isRaffleDone;
    uint public currentTokenId = 1;
    address public designatedSigner;

    function init (string memory _name, string memory _symbol, string memory _signer, string memory _version) external initializer {
               Ownableinitialize();
               Pausableinitialize();
               __ReentrancyGuard_init();
               __ERC721_init(_name,_symbol);
               __Eighty80StakingContractSigner_init(_signer,_version);
    }

    function mintTokens(Signer memory signer) external nonReentrant {
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

    function addSigner(address _signer) external onlyOwner {
        designatedSigner = _signer;
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
