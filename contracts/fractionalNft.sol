//SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.7;
import "./utils/ERC1155Upgradeable.sol";
import "./utils/Ownable.sol";
import './utils/Pausable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract fractionalNft is Ownable, Pausable, ERC1155Upgradeable, ReentrancyGuardUpgradeable, VRFConsumerBase {

    bytes32 public keyHash;
    uint public royaltyPercentage;
    mapping (uint => address) public ownerOfToken;
    bool public isRaffleDone;
    uint public currentTokenId = 1;
    uint public _maxSupply;
    uint public currentSupply;
    mapping (address => bool) public validUsers;
    bool public onlyOnce;
    uint256  internal fee;

    function init (string memory _uri,address _vrfCoordinator, address linkAddress, address _marketPlaceAddress, uint _supply, uint _royaltyAmount) external  {
                require (!onlyOnce,'Already Initialised');
                onlyOnce = true;
               Ownableinitialize();
               Pausableinitialize();
                royaltyPercentage = _royaltyAmount;
               __VRFConsumerBaseV1_init(_vrfCoordinator, linkAddress);
                validUsers[_marketPlaceAddress] = true;
               _maxSupply = _supply;
                 keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
               __ReentrancyGuard_init();
               __ERC1155_init(_uri);
    }

    function mintTokens(address _to, uint _tokenAmount) external nonReentrant {
        require (validUsers[msg.sender],'!Valid User Call');
        currentSupply += _tokenAmount;
        for (uint i =0;i<_tokenAmount;i++) {
            currentTokenId++;
            _mint(_to,currentTokenId,1,'');
        }
    }

    function burnToken(address _user, uint[] memory tokenIds) external {
        require (validUsers[msg.sender],'!Valid User');
        currentSupply -= tokenIds.length;
        for (uint i=0; i < tokenIds.length; i++) {
            _burn(_user,tokenIds[i],1);
        }
    }

    function addValidUser(address _user) external onlyOwner {
        validUsers[_user] = true;
    }

    function startRaffle() external returns(bytes32){
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

    function royaltyInfo (uint paymentAmount) external view returns (address,uint) {
        uint royalty = (paymentAmount * royaltyPercentage) / 1000;
        return (owner(),royalty);
    }

    function setRoyaltyPercentage (uint _amount) external onlyOwner {
        royaltyPercentage = _amount;
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
