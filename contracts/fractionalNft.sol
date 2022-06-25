//SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.7;
import "./utils/ERC1155Upgradeable.sol";
import "./utils/Ownable.sol";
import './utils/Pausable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./fractionalSigner.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract fractionalNft is Ownable, Pausable, ERC1155Upgradeable, SignerImplementation, ReentrancyGuardUpgradeable, VRFConsumerBase {
//    VRFCoordinatorV2Interface COORDINATOR;
//    uint64 public s_subscriptionId;
//    address public vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 public keyHash;
    mapping (address => mapping (uint => bool)) public nonceStatus;
    mapping (uint => address) public ownerOfToken;
    bool public isRaffleDone;
    uint public currentTokenId = 1;
    address public designatedSigner;
    uint public _maxSupply;
    uint public currentSupply;
//    uint32 callbackGasLimit = 100000;
//    uint16 requestConfirmations = 3;
    mapping (address => bool) public validUsers;
//    uint256[] public s_randomWords;
//    uint256 public s_requestId;
//    address s_owner;
    bool public onlyOnce;
//    bytes32  internal keyHash;
    uint256  internal fee;

    function init (string memory _uri, string memory _signer, string memory _version,address _vrfCoordinator, address linkAddress, address _marketPlaceAddress, uint _supply) external  {
                require (!onlyOnce,'Already Initialised');
                onlyOnce = true;
               Ownableinitialize();
               Pausableinitialize();
               __VRFConsumerBaseV1_init(_vrfCoordinator, linkAddress);
//               COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
//                keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
                validUsers[_marketPlaceAddress] = true;
               _maxSupply = _supply;
//                __VRFInit_(0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,0x326C977E6efc84E512bB9C30f76E30c160eD06FB); //for matic
                 keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
//               s_owner = msg.sender;
//               s_subscriptionId = subscriptionId;
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

    function startRaffle() external onlyOwner returns(bytes32){
        require (validUsers[msg.sender],'!Valid User');
        require (currentTokenId - 1 > _maxSupply/2,'50% not reached');
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require (!isRaffleDone,'Raffle Ended');
        bytes32 data = requestRandomness(keyHash, fee);
        return data;
    }

    function fulfillRandomness(
        bytes32 , uint256 randomness
    ) internal override {
        isRaffleDone = true;
        uint winnerTokenId;
        winnerTokenId = randomness % currentTokenId;
        winnerTokenId +=2;
        _mint(ownerOfToken[winnerTokenId],1,1,'');
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
