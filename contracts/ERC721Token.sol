//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Token is ERC721 {
    struct NFT {
        string name;
        uint256 createAt;
        uint256 param1;
    }

    mapping (uint256 => NFT) TokenIdToNFT;

    constructor() ERC721("okada nft", "OKDNFT"){
        NFT memory first_nft = NFT("first nft", block.timestamp, 100);
        TokenIdToNFT[0] = first_nft;
        _mint(msg.sender, 0);
    }


}

