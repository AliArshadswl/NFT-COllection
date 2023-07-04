import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import { abi as contractABI } from './ContractABI'; // Replace './ContractABI' with the path to your ABI file

const contractAddress = '0x9FaA558C2f1489CAc702DD882aA59C011a9f5ED2';

const YourComponent = () => {
    const [maxSupply, setMaxSupply] = useState(0);
    const [mintedNFTs, setMintedNFTs] = useState(0);
    const [maxTokensPerWallet, setMaxTokensPerWallet] = useState(0);
    const [mintFee, setMintFee] = useState(0);
    const [provider, setProvider] = useState(null);
    const [account, setAccount] = useState(null);
    const [metaMaskContract, setMetaMaskContract] = useState(null);
   // const [rpcContract, setRpcContract] = useState(null);
    const [walletConnected, setWalletConnected] = useState(false);



    useEffect(() => {
        const connectToMetaMask = async () => {
            if (window.ethereum) {
                try {
                    await window.ethereum.request({ method: 'eth_requestAccounts' });
                    const accounts = await window.ethereum.request({ method: 'eth_accounts' });
                    const currentProvider = new ethers.providers.Web3Provider(window.ethereum);
                    const currentAccount = accounts[0];
                    setProvider(currentProvider);
                    setAccount(currentAccount);

                    const contract = new ethers.Contract(contractAddress, contractABI, currentProvider);
                    setMetaMaskContract(contract);
                    setWalletConnected(true);
                } catch (error) {
                    console.error('Error connecting to MetaMask:', error);
                }
            } else {
                console.error('Please install MetaMask to use this feature.');
            }
        };



        const getContractInfo = async () => {
            try {
                const rpcProvider = new ethers.providers.JsonRpcProvider('https://goerli.infura.io/v3/88d364215f63477aae7fa9b77ee7ca03');

                const contract = new ethers.Contract(contractAddress, contractABI, rpcProvider);
                //setRpcContract(contract);

                const supply = await contract.MAX_TOKENS();
                setMaxSupply(supply.toNumber());

                // Replace with the appropriate function call to get minted NFTs
                const minted = await contract.totalSupply();
                setMintedNFTs(minted.toNumber());

                const maxPerWallet = await contract.MAX_MINT_PER_TX();
                setMaxTokensPerWallet(maxPerWallet.toNumber());

                const fee = await contract.price();
                setMintFee(ethers.utils.formatEther(fee));
            } catch (error) {
                console.error('Error getting contract information:', error);
            }
        };

        connectToMetaMask();
        getContractInfo();
    }, []);





    const mintNFT = async () => {
        try {
            if (metaMaskContract && account) {
                const numTokens = 1; // Number of tokens to mint
                const price = await metaMaskContract.price();
                const value = price.mul(numTokens);

                const signer = provider.getSigner();
                const contractWithSigner = metaMaskContract.connect(signer);
                const transaction = await contractWithSigner.mint(numTokens, { value: value });
                await transaction.wait();

                // Update mintedNFTs state after successful minting
                const updatedMinted = await metaMaskContract.totalSupply(); // Replace with the appropriate function call to get the total supply of NFTs
                setMintedNFTs(updatedMinted.toNumber());
            } else {
                console.error('Contract or account not available. Please connect to MetaMask.');
            }
        } catch (error) {
            console.error('Error minting NFT:', error);
        }
    };

    return (
        <div>
            <p>Max Supply: {maxSupply}</p>
            <p>Minted NFTs: {mintedNFTs}</p>
            <p>Max Tokens per Wallet: {maxTokensPerWallet}</p>
            <p>Mint Fee: {mintFee} ETH</p>
            {walletConnected && (
                <button onClick={mintNFT}>
                    Mint NFT
                </button>
            )}
        </div>
    );
};

export default YourComponent;
