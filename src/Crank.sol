// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/ERC20.sol";

import "@uniswap-v3-core-1.0.2-solc-0.8-simulate/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap-v3-core-1.0.2-solc-0.8-simulate/contracts/interfaces/IUniswapV3Pool.sol";
import "src/libraries/PoolAddress.sol";

// AAVE
import "src/interfaces/Pool.sol";
import "src/interfaces/AToken.sol";
import "src/interfaces/PoolDataProvider.sol";


contract Crank is IUniswapV3SwapCallback, Ownable {
	    struct SwapCallbackData {
        PoolAddress.PoolKey poolKey;
    }

	constructor() {
		_initializeOwner(msg.sender);
	}

    receive() external payable {
    }

    // UniV3 factory (Mainnet, Polygon, Optimism, Arbitrum, Testnets)
    address public constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint16 public constant referralCode = 0;

    // Aave
    Pool public constant lendingPool = Pool(0x4e033931ad43597d96D6bcc25c280717730B58B1);
    PoolDataProvider public constant poolDataProvider = PoolDataProvider(0xa3206d66cF94AA1e93B21a9D8d409d6375309F4A);
    IAToken public aWeth = IAToken(0xfA1fDbBD71B0aA16162D76914d69cD8CB3Ef92da);
    IAToken public aWsteth = IAToken(0xC035a7cf15375cE2706766804551791aD035E0C2);
    ERC20 public weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 public wsteth = ERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    function withdrawNative() external onlyOwner {
	    // live dangerously. Works best assuming EIP-4758
	    selfdestruct(payable(msg.sender));
    }

    function withdrawERC20(address token) external onlyOwner {
	    ERC20(token).transfer(msg.sender, ERC20(token).balanceOf(address(this)));
    }

    function wind(uint wstethAmount, uint24 fee, uint160 sqrtPriceLimitX96) external onlyOwner {
	    PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: address(wsteth), token1: address(weth), fee: fee});
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
	bool zeroForOne = false;
        pool.swap(
            address(this),
	    zeroForOne,
	    -int256(wstethAmount),
	    sqrtPriceLimitX96,
            abi.encode(
                SwapCallbackData({
                    poolKey: poolKey
                })
            )
        );
    }

    function unwind(uint wstethAmount, uint24 fee, uint160 sqrtPriceLimitX96) external onlyOwner {
	    PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: address(wsteth), token1: address(weth), fee: fee});
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
	bool zeroForOne = true;
        pool.swap(
            address(this),
	    zeroForOne,
	    int256(wstethAmount),
	    sqrtPriceLimitX96,
            abi.encode(
                SwapCallbackData({
                    poolKey: poolKey
                })
            )
        );
    }

    function close(uint24 fee, uint160 sqrtPriceLimitX96) external onlyOwner {
	    (,,uint wethAmount,,,,,,) = poolDataProvider.getUserReserveData(address(weth), address(this));
	    PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: address(wsteth), token1: address(weth), fee: fee});
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
	bool zeroForOne = true;
        pool.swap(
            address(this),
	    zeroForOne,
	    -int256(wethAmount),
	    sqrtPriceLimitX96,
            abi.encode(
                SwapCallbackData({
                    poolKey: poolKey
                })
            )
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
	    SwapCallbackData memory decoded = abi.decode(data, (SwapCallbackData));
	    IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, decoded.poolKey));
	    require(msg.sender == address(pool));

	    if (amount1Delta > 0) {
	    uint wethAmount = uint(amount1Delta);
	    uint wstethBalance = wsteth.balanceOf(address(this));
	    wsteth.approve(address(lendingPool), wstethBalance);
	    lendingPool.supply(address(wsteth), wstethBalance, address(this), referralCode);

	    lendingPool.borrow(address(weth), wethAmount, 2, referralCode, address(this));
	    weth.transfer(msg.sender, wethAmount);
	    } else {
		    uint wstethAmount = uint(amount0Delta);
		    uint wethBalance = weth.balanceOf(address(this));
		    weth.approve(address(lendingPool), wethBalance);
		    lendingPool.repay(address(weth), wethBalance, 2, address(this));
		    lendingPool.withdraw(address(wsteth), wstethAmount, address(this));
		    wsteth.transfer(msg.sender, wstethAmount);
	    }
    }
}
