//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
interface INft is IERC1155Upgradeable{
    function royaltyInfo (uint paymentAmount) external view returns (address,uint);
    function mintTokens(address _to, uint _tokenAmount) external;
    function startRaffle() external returns(bytes32);
}
