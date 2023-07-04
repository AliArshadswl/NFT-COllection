// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721, Ownable {
    using Strings for uint256;

    uint private constant DEFAULT_MAX_TOKENS = 1000;
    uint private constant DEFAULT_TOKENS_RESERVED = 10;
    uint private constant DEFAULT_PRICE = 0.01 ether;
    uint256 private constant DEFAULT_MAX_MINT_PER_TX = 10;

    uint public MAX_TOKENS;
    uint private TOKENS_RESERVED;
    uint public price;
    uint256 public MAX_MINT_PER_TX;

    bool public isSaleActive;

    uint256 public totalSupply;

    mapping(address => uint256) private mintedPerWallet;

    string public baseUri;
    string public baseExtension = ".json";

    uint256 public contractBalance;

    constructor() ERC721("GangClub", "GNG") {
        baseUri = "ipfs://bafybeiefb7s245y7wrtxkfg323xreayjxkplzgxq3kzwo6bu25eqlycciq/";
        MAX_TOKENS = DEFAULT_MAX_TOKENS;
        TOKENS_RESERVED = DEFAULT_TOKENS_RESERVED;
        price = DEFAULT_PRICE;
        MAX_MINT_PER_TX = DEFAULT_MAX_MINT_PER_TX;

        for (uint256 i = 1; i <= TOKENS_RESERVED; ++i) {
            _safeMint(msg.sender, i);
        }

        totalSupply = TOKENS_RESERVED;
        contractBalance = address(this).balance;
    }

    modifier onlyOwnerOrAuthorized() {
        require(msg.sender == owner() || isAuthorized(msg.sender), "Unauthorized access");
        _;
    }

    function isAuthorized(address account) internal view returns (bool) {
        // Implement your own logic to determine authorized accounts
        // For example, you can maintain a list of authorized accounts as a mapping
        // and check if the given account is in the list
        return false;
    }

    function mint(uint256 _numTokens) external payable {
        require(isSaleActive, "The sale is paused.");
        require(
            mintedPerWallet[msg.sender] + _numTokens <= MAX_MINT_PER_TX,
            "You cannot mint that many total."
        );
        require(
            totalSupply + _numTokens <= MAX_TOKENS,
            "Exceeds total supply."
        );
        require(_numTokens * price <= msg.value, "Insufficient funds.");

        for (uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, totalSupply + i);
        }

        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;
        contractBalance = address(this).balance;
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseUri(string memory _baseUri) external onlyOwnerOrAuthorized {
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) external onlyOwnerOrAuthorized {
        price = _price;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwnerOrAuthorized {
        MAX_MINT_PER_TX = _maxMintPerTx;
    }

    function setMaxTokens(uint256 _maxTokens) external onlyOwnerOrAuthorized {
        MAX_TOKENS = _maxTokens;
    }

    function setTokensReserved(uint256 _tokensReserved) external onlyOwnerOrAuthorized {
        TOKENS_RESERVED = _tokensReserved;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = (balance * 100) / 100;

        (bool transferOne, ) = payable(
            0x196300DE0666697a1d2310a0764372634411B66A
        ).call{value: balanceOne}("");

        require(transferOne, "Transfer failed.");
        contractBalance = address(this).balance;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}
