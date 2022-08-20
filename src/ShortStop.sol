// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@aave-protocol/lendingpool/LendingPool.sol";
import "@uniswap/interfaces/ISwapRouter.sol";
import "@uniswap/libraries/TransferHelper.sol";

contract ShortStop is LendingPool {}

