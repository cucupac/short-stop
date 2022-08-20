// contracts/RunChallenger.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@aave-protocol/lendingpool/LendingPool.sol";
import "@uniswap/interfaces/ISwapRouter.sol";
import "@uniswap/libraries/TransferHelper.sol";

contract ShortStop is LendingPool {

    address public shortTokenAddress;

    constructor(address shortTokenAddress) {
        shortTokenAddress = shortTokenAddress;
    }
   

    // Handle inital deposit from user
    function deposit() public payable {

    }

    // Use USD balance to initiate loan with Aave
    function initiateLoan() private view {

    }

    // Swap from Short Token to USDC
    function swapToUSDC() {

    }

    // Swap from USDC to ShortToken
    function swapToShortToken() {

    }
}






