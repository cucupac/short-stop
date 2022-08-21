// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma abicoder v2;

import "@aave-protocol/lendingpool/LendingPool.sol";
import "@uniswap/interfaces/ISwapRouter.sol";
import "@uniswap/libraries/TransferHelper.sol";

contract ShortStop is LendingPool {
    // Enables access to functions in the ISwapRouter interface
    ISwapRouter public immutable swapRouter;

    // Hardcode token address (configure this)
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Hardcode pool fee (3000 => 0.3%)
    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter) 
    {
        swapRouter = _swapRouter;
    }

    /// @notice swapExactInputSingle swaps a fixed amount of WETH9 for a maximum possible amount of WETH9
    /// using the WETH9/USDC 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its WETH9 for this function to succeed.
    /// @param amountIn The exact amount of WETH9 that will be swapped for USDC.
    /// @return amountOut The amount of USDC received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) 
    {
        
        // msg.sender must approve this contract
        address tokenIn = WETH9; 
        address tokenOut = USDC;

        // Transfer the specified amount of TokenIn to this contract
        // note: This contract must first be approved by msg.sender
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);

        // Approve the router to spend 
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        // create params of swap 
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams(
            {
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap given the route.
        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of DAI for a fixed amount of WETH.
    /// @dev The calling address must approve this contract to spend its DAI for this function to succeed. As the amount of input DAI is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of WETH9 to receive from the swap.
    /// @param amountInMaximum The amount of USDC we are willing to spend to receive the specified amount of WETH9.
    /// @return amountIn The amount of USDC actually spent in the swap.
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        
        // msg.sender must approve this contract
        address tokenIn = USDC; 
        address tokenOut = WETH9;
        
        // Transfer the specified amount of USDC to this contract.
        TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amountInMaximum);

        // Approve the router to spend the specified `amountInMaximum` of USDC.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to achieve a better swap.
        TransferHelper.safeApprove(USDC, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: USDC,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(USDC, address(swapRouter), 0);
            TransferHelper.safeTransfer(USDC, msg.sender, amountInMaximum - amountIn);
        }
    }


    function main_short(void) external returns (void)
    {
        unit256 amountShorted = 1;      // i.e. short 1 wrapped eth
        uint256 swap_out;               // amount stored of token out (USDC)
        uint256 amountInRemaining;      // amount of USDC actually spent to repay amountShorted            
        
        // WETH -> USDC 
        swap_out = swapExactInputSingle(amountShorted);
        console.log("--- after WETH -> USDC swap ---");
        log_balances();
        
        //... time to close short position and pay back AAVE loan

        // USDC -> WETH 
        amountInRemaining = swapExactOutputSingle(amountShorted, swap_out);
        console.log("--- after USDC -> WETH swap ---");
        log_balances();
    }
}