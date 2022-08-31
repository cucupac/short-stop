// contracts/TokenSwap.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

// import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";
// import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol";
import "@uniswap-v3-periphery/interfaces/ISwapRouter.sol";
import "@uniswap-v3-periphery/libraries/TransferHelper.sol";

contract TokenSwap {

    // Storage Variables
    ISwapRouter public immutable swapRouter;
    uint24 public constant poolFee = 3000;
    address public tokenGive = 0x0000000000000000000000000000000000001010;
    address public tokenReceive = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
    // IERC20 maticToken = IERC20(tokenGive);    // NOTE : Is this ERC20?
    IERC20 wethToken = IERC20(tokenReceive); // NOTE: we are currently assuming that all shorted assets are non-native

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    } 

    // Swap from matic to weth
    function swapToWeth() public {
        // 1. Get contract’s matic token balance
        uint maticBalance = address(this).balance;
        // 2. Approve Uniswap to spend our matic tokens
        TransferHelper.safeApprove(tokenGive, address(swapRouter), maticBalance);

        // 3. Construct swap params
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenGive,
                tokenOut: tokenReceive,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: maticBalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // 4. Execute token swap.
        swapRouter.exactInputSingle(params);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}