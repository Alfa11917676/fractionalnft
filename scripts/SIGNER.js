require('dotenv').config()
const ethers = require('ethers');
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY)// const wallet = new ethers.Wallet(process.env.KEY);
async function signTransaction(projectOwnerAddress,tokens, nonce) {
    const domain = {
        name: "ARNAB",
        version: "1",
        chainId: 4, //put the chain id
        verifyingContract: '0x264F1DD57CE81d67A912c0499925A526c3e832c5' //contract address
    }

    const types ={
        Signer: [
            {name: '_user', type: 'address'},
            {name: 'totalTokensToMint', type: 'uint256'},
            {name: 'nonce', type: 'uint256'},
        ],
    };

    const value = {
        _user: projectOwnerAddress,
        totalTokensToMint: tokens,
        nonce:nonce
    };

    const sign = await wallet._signTypedData(domain,types,value)
    console.log(sign);
}
signTransaction("0x79BF6Ab2d78D81da7d7E91990a25A81e93724a60",7,1656056388)
//["0x79BF6Ab2d78D81da7d7E91990a25A81e93724a60",7,1656056388,"0x95f55d14778431de991ba347d7c428025e9b7379f8f7f404dc5a719a80befd8c7a115ed7682ecab90611a36de1be709a46c286b054bd1db485f08c57720416281b"]
module.exports = signTransaction ;
