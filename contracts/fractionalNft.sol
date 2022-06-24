//SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.7;
import "./utils/ERC1155Upgradeable.sol";
import "./utils/Ownable.sol";
import './utils/Pausable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./fractionalSigner.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract fractionalNft is Ownable, Pausable, ERC1155Upgradeable, SignerImplementation, ReentrancyGuardUpgradeable, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public s_subscriptionId;
    address public vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 public keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    mapping (address => mapping (uint => bool)) public nonceStatus;
    mapping (uint => address) public ownerOfToken;
    bool public isRaffleDone;
    uint public currentTokenId = 1;
    address public designatedSigner;
    uint public _maxSupply;
    uint public currentSupply;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    mapping (address => bool) public validUsers;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;


    function init (string memory _uri, string memory _signer, string memory _version, uint64 subscriptionId, address _vrfAddress, address _vrfCoordinator, address _marketPlaceAddress, uint _supply) external initializer {
               Ownableinitialize();
               Pausableinitialize();
               __VRFConsumerBaseV2_init(_vrfAddress);
               COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
                validUsers[_marketPlaceAddress] = true;
               _maxSupply = _supply;
               s_owner = msg.sender;
               s_subscriptionId = subscriptionId;
               __ReentrancyGuard_init();
               __ERC1155_init(_uri);
               __Eighty80StakingContractSigner_init(_signer,_version);
    }

    function mintTokens(Signer memory signer) external nonReentrant {
        require (validUsers[msg.sender],'!Valid User Call');
        require (getSigner(signer) == designatedSigner,'!Signer');
        require(msg.sender == signer._user, '!User');
        require (block.timestamp <= signer.nonce + 10 minutes, 'Signature Expired');
        require (!nonceStatus[msg.sender][signer.nonce],'Nonce used');
        nonceStatus[msg.sender][signer.nonce] = true;
        currentSupply += signer.totalTokensToMint;
        for (uint i =0;i<signer.totalTokensToMint;i++) {
            currentTokenId++;
            _mint(msg.sender,currentTokenId,1,'');
        }
    }

    function burnToken(address _user, uint[] memory tokenIds) external {
        require (validUsers[msg.sender],'!Valid User');
        currentSupply -= tokenIds.length;
        for (uint i=0; i < tokenIds.length; i++) {
            _burn(_user,tokenIds[i],1);
        }
    }
    function addSigner(address _signer) external onlyOwner {
        designatedSigner = _signer;
    }

    function addValidUser(address _user) external onlyOwner {
        validUsers[_user] = true;
    }

    function startRaffle() external onlyOwner {
        require (validUsers[msg.sender],'!Valid User');
        require (currentTokenId > _maxSupply/2,'50% not reached');
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
    }

    function fulfillRandomWords(
        uint256 ,
        uint256[] memory randomWords
    ) internal override {
        isRaffleDone = true;
        uint randomNumber = randomWords[0];
        uint winnerTokenId;
        winnerTokenId = randomNumber % currentTokenId;
        winnerTokenId +=2;
        _mint(ownerOfToken[winnerTokenId],1,1,'');
    }

    function changeSubscriptionId(uint64 _id) external onlyOwner {
        s_subscriptionId = _id;
    }


    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override virtual {

        for (uint i=0;i<ids.length;i++) {
            require(!isRaffleDone || ids[i] == 1, 'Transfer| Stopped');
            ownerOfToken[ids[i]] = to;
        }
        super._beforeTokenTransfer(
            operator, from, to, ids, amounts, data);
    }

}
