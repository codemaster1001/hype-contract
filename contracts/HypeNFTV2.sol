// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HypeNFTV2 is ERC721Enumerable, Ownable, ReentrancyGuard {
    error AmountIsZero();
    error InsufficientETH();
    error InsufficientHypeCoins();
    error ErrorWhileTransfering();
    error AllowanceTooLow();

    IERC20 public hypeCoin;
    uint256 public nextTokenId;
    uint256 public constant nftPrice = 0.1 ether; // 1 HypeNFT = 0.1 ETH
    mapping(uint256 => uint256) public lastClaimed;
    uint256 public constant DAILY_REWARD = 1 * 10 ** 18;

    /**
     * @notice constructor
     * when deploying contract, we set msg.sender as owner, nextTokenId to 1, set HypeCoin address.
     */
    constructor(
        address _coinAddress
    ) ERC721("HypeNFT", "HypeNFT") Ownable(msg.sender) {
        nextTokenId = 1;
        hypeCoin = IERC20(_coinAddress);
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
            lastClaimed[tempNextTokenId] = block.timestamp;
            tempNextTokenId += 1;
            unchecked {
                i++;
            }
        }
        (bool result1, ) = payable(owner()).call{value: msg.value}("");
        if (result1 == false) revert ErrorWhileTransfering();
        if (msg.value > requiredETH) {
            (bool result2, ) = payable(msg.sender).call{
                value: (msg.value - requiredETH)
            }("");
            if (result2 == false) revert ErrorWhileTransfering();
        }
    }

    /**
     * @notice Get next mintable token id.
     */
    function getNextTokenId() external view returns (uint256) {
        return nextTokenId;
    }

    /**
     * @notice Get tokenIds by owner address
     * @param _owner Address of NFT owner
     */
    function tokensOwnedByAddr(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; ) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            unchecked {
                i++;
            }
        }

        return tokenIds;
    }

    /**
     * @notice Mint NFTs with HypeCoins (1 HypeNFT = 5 HypeCoins)
     * Before calling this function, users have to approve their HypeCoins to this contract first.
     * @param _tokenAmount an amount of HypeCoins needed for minting HypeNFTs.
     */
    function mintWithHypeCoin(uint256 _tokenAmount) external {
        uint256 _nftPrice = 5 * 10 ** 18;
        if (_tokenAmount < _nftPrice) revert InsufficientHypeCoins();

        uint256 remainder = _tokenAmount % _nftPrice;
        uint256 nftCount = (_tokenAmount - remainder) / _nftPrice;
        uint256 requiredTokenAmount = nftCount * _nftPrice;

        uint256 balance = hypeCoin.balanceOf(msg.sender);
        uint256 allowance = hypeCoin.allowance(msg.sender, address(this));
        if (balance < requiredTokenAmount) revert InsufficientHypeCoins();
        if (allowance < requiredTokenAmount) revert AllowanceTooLow();

        if (
            hypeCoin.transferFrom(
                msg.sender,
                address(this),
                requiredTokenAmount
            ) == false
        ) revert ErrorWhileTransfering();
        uint256 tempNextTokenId = nextTokenId;
        nextTokenId += nftCount;
        for (uint256 i = 0; i < nftCount; ) {
            _safeMint(msg.sender, tempNextTokenId);
            lastClaimed[tempNextTokenId] = block.timestamp;
            tempNextTokenId += 1;
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Overrides the transferFrom function of NFT721 to let users collect HypeCoins before transfering.
     * @param _from Address of user sending NFT
     * @param _to Address of user who receive NFT
     * @param _tokenId token id to send
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(ERC721, IERC721) {
        if (_from != address(0)) {
            _collectReward(_tokenId);
        }
        super.transferFrom(_from, _to, _tokenId);
    }

    /**
     * @notice private function to collect HypeCoins with tokenId
     * 1 NFT can generate 1 HypeCoin every day.
     * @param _tokenId token id to collect rewards of HypeCoin
     */
    function _collectReward(uint256 _tokenId) private {
        uint256 timeHeld = block.timestamp - lastClaimed[_tokenId];
        uint256 rewards = (timeHeld / 1 days) * DAILY_REWARD;
        hypeCoin.transfer(ownerOf(_tokenId), rewards);
        lastClaimed[_tokenId] = block.timestamp;
    }

    /**
     * @notice Collect HypeCoins by holding NFTs for more than one day
     */
    function collect() public {
        uint256[] memory tokenIds = tokensOwnedByAddr(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; ) {
            _collectReward(tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    receive() external payable {}
}
