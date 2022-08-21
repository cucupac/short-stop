// contracts/RunChallenger.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
pragma abicoder v2;

import "@aave-protocol/protocol/pool/Pool.sol";
import "@uniswap/interfaces/ISwapRouter.sol";
import "@uniswap/libraries/TransferHelper.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ShortStop is Pool, ERC20 {

    // Storage Variables
    ISwapRouter public immutable swapRouter;
    uint24 public constant poolFee = 3000;
    address public shortTokenPolygonAddress;
    address public usdcPolygonAddress = 0x2791bca1f2de4661ed88a30c99a7a9449aa84174;
    address public aavePolygonAddress = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    ERC20 usdcToken = ERC20(usdcPolygonAddress);
    ERC20 shortToken = ERC20(shortTokenPolygonAddress); // NOTE: we are currently assuming that all shorted assets are non-native
    Pool aavePool = Pool(aavePolygonAddress);

    constructor(address shortTokenPolygonAddress, ISwapRouter _swapRouter) {
        shortTokenPolygonAddress = shortTokenPolygonAddress;
        swapRouter = _swapRouter;
    }
   

    // Handle inital deposit from user
    // NOTE: This assumes that this contract has already been authorized to move a user's tokens (via polygonscan or other means)
    function deposit(uint _amount) public payable {
        usdcToken.transferFrom(msg.sender, address(this), _amount);
        initiateLoan();
    }

    // Use USD balance to initiate loan with Aave
    function initiateLoan(uint _amount) private view {
        // 1. Approve Aave's pool to spend money on this contract's behalf
        usdcToken.approve(aavePolygonAddress, _amount);
        // 2. Supply Aave with USDC collateral
        aavePool.supply(usdcPolygonAddress, _amount, address(this), 0);
        // 3. Borrow 1 Curve
        aavePool.borrow(shortTokenPolygonAddress, 1 ether, 2, 0, address(this));
        // 4. Once loan is received, swap to USDC
        swapToUSDC();
    }

    // Swap from Short Token to USDC
    function swapToUSDC() private {
        // 1. Get contract's short token balance
        uint shortTokenBalance = ERC20(shortTokenPolygonAddress).balanceOf(address(this));
        // 2. Approve Uniswap to spend our short tokens
        TransferHelper.safeApprove(shortTokenPolygonAddress, address(swapRouter), shortTokenBalance);

        // 3. Construct swap params
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: shortTokenPolygonAddress,
                tokenOut: usdcPolygonAddress,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: shortTokenBalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // 4. Execute token swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    // Swap from USDC to ShortToken
    function swapToShortToken() private {
        // 1. Get contract's short token balance
        uint usdcBalance = ERC20(usdcPolygonAddress).balanceOf(address(this));
        // 2. Approve Uniswap to spend our short tokens
        TransferHelper.safeApprove(shortTokenPolygonAddress, address(swapRouter), usdcBalance);

        // 3. Construct swap params
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: usdcPolygonAddress,
                tokenOut: shortTokenPolygonAddress,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: usdcBalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // 4. Execute token swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function closePosition() {
        swapToShortToken();
        uint shortTokenBalance = ERC20(shortTokenPolygonAddress).balanceOf(address(this));
        shortToken.approve(aavePolygonAddress, shortTokenBalance);
        aavePool.repay(shortTokenPolygonAddress, shortTokenBalance, 2, address(this)); // NOTE: uint(-1) was changed to shortTokenBalance
    }
}
