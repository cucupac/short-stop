// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Aave.sol";

contract AaveTest is Test {

    // Contracts
    Aave aave;

    address borrowTokenAddress = 0x85E44420b6137bbc75a85CAB5c9A3371af976FdE;  // Currently WBTC on Mumbai: 0x85E44420b6137bbc75a85CAB5c9A3371af976FdE

    function setUp() public {
        // aave = new Aave(borrowTokenAddress);
    }

    function testExample() public {
        assertTrue(true);
    }
}
