// contracts/RunChallenger.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@aave-protocol/lendingpool/LendingPool.sol";
import "@uniswap/interfaces/ISwapRouter.sol";
import "@uniswap/libraries/TransferHelper.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ShortStop is LendingPool, ERC20 {

    address public shortTokenAddress;
    ERC20 usdcToken = ERC20(0x2791bca1f2de4661ed88a30c99a7a9449aa84174);

    constructor(address shortTokenAddress) {
        shortTokenAddress = shortTokenAddress;
    }
   

    // Handle inital deposit from user
    function deposit(uint _amount) public payable {
        daiToken.transferFrom(msg.sender, address(this), _amount);
        initiateLoan();
    }

    // Use USD balance to initiate loan with Aave
    function initiateLoan(uint _amount) private view {
        usdcToken.approve(0x794a61358D6845594F94dc1DB02A252b5b4814aD, _amount);
    }

    // Swap from Short Token to USDC
    function swapToUSDC() {

    }

    // Swap from USDC to ShortToken
    function swapToShortToken() {

    }
}






