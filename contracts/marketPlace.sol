//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import './INft.sol';
import "./fractionalSigner.sol";
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
contract marketPlace is OwnableUpgradeable, SignerImplementation {

        address public designatedSigner;
        uint public platformPercentage;
        mapping (address => mapping (uint => bool)) public nonceStatus;
        IERC20Upgradeable paymentToken;


        struct Fee {
                uint platformFee;
                uint assetFee;
                uint royaltyFee;
                address tokenCreator;
        }

        function initialize (address _designatedSigner, string memory _signer, string memory _version, uint _platformPercentage, address _tokenAddress) public initializer {
                __Ownable_init();
                platformPercentage = _platformPercentage;
                designatedSigner = _designatedSigner;
                paymentToken = IERC20Upgradeable(_tokenAddress);
                __Eighty80StakingContractSigner_init(_signer,_version);
        }

        function mintNewTokens(Signer memory signer) external {
                require (getSigner(signer) == designatedSigner,'!Signer');
                require(msg.sender == signer._user, '!User');
                require (!nonceStatus[msg.sender][signer.nonce],'Nonce used');
                require (block.timestamp <= signer.nonce + 10 minutes, 'Signature Expired');
                nonceStatus[msg.sender][signer.nonce] = true;
                INft(signer._nftAddress).mintTokens(signer._user,signer.totalTokensToMint);
        }

        function calculateFees(uint paymentAmt, address nftAddress) internal view returns(Fee memory){
                address tokenCreator;
                uint royaltyFee;
                uint assetFee;
                uint platformFee = (paymentAmt * platformPercentage)/1000;
                (tokenCreator, royaltyFee) = INft(nftAddress).royaltyInfo(paymentAmt);
                assetFee = paymentAmt - royaltyFee - platformFee;
                return Fee(platformFee, assetFee, royaltyFee, tokenCreator);
        }

        function transferAsset(Signer memory signer, Fee memory fee) internal virtual {
                if (signer.inEth){
                        if (fee.platformFee >0) {
                                payable(owner()).transfer(fee.platformFee);
                        }
                        if (fee.royaltyFee > 0) {
                                payable(fee.tokenCreator).transfer(fee.royaltyFee);
                        }
                        payable(signer._user).transfer(fee.assetFee);
                        INft(signer._nftAddress).safeTransferFrom(signer._user, signer.buyer, signer.tokenId, 1, "");

                } else {

                        if(fee.platformFee > 0) {
                                paymentToken.transferFrom(signer.buyer, owner(), fee.platformFee);
                        }
                        if(fee.royaltyFee > 0) {
                                paymentToken.transferFrom( signer.buyer, fee.tokenCreator, fee.royaltyFee);
                        }
                        paymentToken.transferFrom( signer.buyer, signer._user, fee.assetFee);
                        INft(signer._nftAddress).safeTransferFrom(signer._user, signer.buyer, signer.tokenId, 1, "");
                }
        }

        function executeOrder (Signer memory signer) external payable {
                require (signer._user == msg.sender,'!User');
                require (!nonceStatus[msg.sender][signer.nonce],'Nonce Used');
                Fee memory fee;
                if (signer.inEth) {
                        require (msg.value == signer.amount * 1 ether,'Incorrect amount passed from buyer wallet');
                }
                nonceStatus[msg.sender][signer.nonce] = true;
                if (!signer.inEth)
                        fee  = calculateFees(signer.amount * 1 ether, signer._nftAddress);
                else
                        fee = calculateFees(msg.value, signer._nftAddress);
                transferAsset(signer,fee);
        }

        function setPaymentTokenAddress(address _paymentTokenAddress) external onlyOwner {
                paymentToken  = IERC20Upgradeable(_paymentTokenAddress);
        }

        function changePlatformPercentage(uint _percent) external onlyOwner {
                 platformPercentage = _percent;
        }


        function startRaffleOnProjects(address _nftAddress) external onlyOwner {
                INft(_nftAddress).startRaffle();
        }

        function addSigner(address _signer) external onlyOwner {
                designatedSigner = _signer;
        }
}
