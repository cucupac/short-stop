// contracts/ShortStop.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "@aave-protocol/protocol/pool/Pool.sol";
import "@uniswap-v3-periphery/interfaces/ISwapRouter.sol";
import "@uniswap-v3-periphery/libraries/TransferHelper.sol";
import "@uniswap-v3-core/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

contract ShortStop {

    // Storage Variables
    address payable admin;
    ISwapRouter public immutable swapRouter;
    uint24 public constant poolFee = 3000;
    address public shortTokenPolygonAddress;
    address public usdcPolygonAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; //Polygon Mainnet
    address public usdcxPolygonAddress = 0xCAa7349CEA390F89641fe306D93591f87595dc1F; //Polygon Mainnet
    address public aavePoolPolygonAddress = 0x794a61358D6845594F94dc1DB02A252b5b4814aD; //Polygon Mainnet
    IERC20 usdcToken = IERC20(usdcPolygonAddress);
    ISuperToken usdcxToken = ISuperToken(usdcxPolygonAddress);
    IERC20 shortToken = IERC20(shortTokenPolygonAddress); // NOTE: we are currently assuming that all shorted assets are non-native
    Pool aavePool = Pool(aavePoolPolygonAddress);

    constructor(address _shortTokenPolygonAddress, ISwapRouter _swapRouter) {
        shortTokenPolygonAddress = _shortTokenPolygonAddress;
        swapRouter = _swapRouter;
        admin = payable(msg.sender);
        usdcToken.approve(aavePoolPolygonAddress, 1000000000000000000000000000000000);
    }
   
    

    // Use USD balance to initiate loan with Aave
    function initiateLoan() public {

        uint amountToDrain = usdcToken.balanceOf(address(this));
        // 3. Supply Aave with USDC collateral
        aavePool.supply(usdcPolygonAddress, amountToDrain, address(this), 0);
        // 4. Borrow 1 Curve
        aavePool.borrow(shortTokenPolygonAddress, 100000000, 2, 0, address(this));
        // 5. Once loan is received, swap to USDC
        swapToUSDC();
    }

    // Swap from Short Token to USDC
    function swapToUSDC() public {
        // 1. Get contract's short token balance
        uint shortTokenBalance = IERC20(shortTokenPolygonAddress).balanceOf(address(this));
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
        uint amountOut = swapRouter.exactInputSingle(params);
    }

    // Swap from USDC to ShortToken
    function swapToShortToken() private {
        // 1. Get contract's short token balance
        uint usdcBalance = IERC20(usdcPolygonAddress).balanceOf(address(this));
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
        uint amountOut = swapRouter.exactInputSingle(params);
    }

    function closePosition() public {
        swapToShortToken();
        uint shortTokenBalance = IERC20(shortTokenPolygonAddress).balanceOf(address(this));
        shortToken.approve(aavePoolPolygonAddress, shortTokenBalance);
        aavePool.repay(shortTokenPolygonAddress, shortTokenBalance, 2, address(this)); // NOTE: uint(-1) was changed to shortTokenBalance
    }

    function returnMoney() public {
        uint amountToReturnUSDC = usdcToken.balanceOf(address(this));
        
        admin.transfer(amountToReturnUSDC);
        uint amountToReturnShort = shortToken.balanceOf(address(this));
        admin.transfer(amountToReturnShort);
        uint amountToReturnUSDCX = usdcxToken.balanceOf(address(this));
        admin.transfer(amountToReturnUSDCX);
    }

    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}
