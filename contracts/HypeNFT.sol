// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HypeNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    error AmountIsZero();
    error InsufficientETH();
    error ErrorWhileTransfering();
    uint256 public nextTokenId;
    uint256 public constant nftPrice = 10 ** 17; // 1 HypeNFT = 0.1 ETH

    /**
     * @notice constructor
     * when deploying contract, we set msg.sender as owner, nextTokenId to 1.
     */
    constructor() ERC721("HypeNFT", "HypeNFT") Ownable(msg.sender) {
        nextTokenId = 1;
    }

    /**
     * @notice Mint HypeNFT with ETH
     * @param _amount an amount of ETH to mint HypeNFT (1 HypeNFT = 0.1 ETH)
     */
    function mint(uint256 _amount) external payable nonReentrant {
        if (_amount == 0) revert AmountIsZero();
        uint256 requiredETH = _amount * nftPrice;
        if (msg.value < requiredETH) revert InsufficientETH();

        uint256 tempNextTokenId = nextTokenId;
        nextTokenId += _amount;
        for (uint256 i = 0; i < _amount; ) {
            _safeMint(msg.sender, tempNextTokenId);
            tempNextTokenId += 1;
            unchecked {
                i++;
            }
        }
        // payable(owner()).transfer(msg.value);
        (bool result1, ) = payable(owner()).call{value: msg.value}("");
        if (result1 == false) revert ErrorWhileTransfering();
        if (msg.value > requiredETH) {
            (bool result2, ) = payable(msg.sender).call{
                value: (msg.value - requiredETH)
            }("");
            if (result2 == false) revert ErrorWhileTransfering();
        }
        // payable(msg.sender).transfer(msg.value - requiredETH);
    }

    /**
     * @notice Get next mintable token id.
     */
    function getNextTokenId() external view returns (uint256) {
        return nextTokenId;
    }

    /**
     * @notice Get tokenIds by owner address
     * @param owner Address of NFT owner
     */
    function tokensOwnedByAddr(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; ) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
            unchecked {
                i++;
            }
        }

        return tokenIds;
    }

    receive() external payable {}
}
