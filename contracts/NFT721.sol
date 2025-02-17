// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; 

   contract MyNFT is ERC721, ERC721URIStorage, ERC721Burnable, ERC721Enumerable, Ownable {
    // Add marketplace address
    address public marketplace;
    uint private _tokenIdCounter;
    event TokenURIUpdated(uint256 tokenId, string newURI);
    constructor() ERC721("pioneNFT", "UNFT") {}
    
    // Add function to set marketplace address
    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    // Modify safeMint to allow marketplace to mint
    function safeMint(address to, uint256 tokenId, string memory uri) public {
        require(msg.sender == owner() || msg.sender == marketplace, "Not authorized to mint");
        require(!_exists(tokenId), "Token already exists");
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
    function updateTokenURI(uint256 tokenId, string memory newURI) public onlyOwner {
        require(tokenId < _tokenIdCounter, "Token ID does not exist");
        _setTokenURI(tokenId, newURI);
        emit TokenURIUpdated(tokenId, newURI);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}