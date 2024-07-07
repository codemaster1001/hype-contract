// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HypeCoin is ERC20, Ownable, ReentrancyGuard {
    error NoETHToClaim();
    error ErrorWhileClaiming();
    uint256 public constant COIN_PRICE = 10 ** 16; // 1 HC = 0.01  ETH

    /**
     * @notice constructor.
     * @param _totalSupply total supply of ERC20 standard with decimals 18
     */
    constructor(
        uint256 _totalSupply
    ) ERC20("HypeCoin", "HC") Ownable(msg.sender) {
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @notice User can buy HypeCoin with ETH (1 HypeCoin = 0.01 ETH)
     * @param _amount an amount of HypeCoin user is going to buy
     */
    function buy(uint256 _amount) external payable {
        if (balanceOf(owner()) < _amount) revert();

        uint256 price = (_amount * COIN_PRICE) / 10 ** 18;
        if (msg.value < price) revert();
        _transfer(owner(), msg.sender, _amount);
        if (msg.value > price) payable(msg.sender).transfer(msg.value - price);
    }

    /**
     * @notice Only Owner can claim ETH from the contract
     * For saving gas, I used call function and reentrancy guard for sending ETH to Owner.
     */
    function claim() external onlyOwner nonReentrant {
        if (address(this).balance == 0) revert NoETHToClaim();
        uint256 value = address(this).balance;
        // payable(owner()).transfer(value);
        (bool result, ) = payable(owner()).call{value: value}("");
        if (result == false) revert ErrorWhileClaiming();
    }

    receive() external payable {}
}
