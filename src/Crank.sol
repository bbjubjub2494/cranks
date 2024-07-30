// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/ERC20.sol";
import "@solady-0.0.228/src/utils/UUPSUpgradeable.sol";

import "@uniswap-v3-core-1.0.2-solc-0.8-simulate/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap-v3-core-1.0.2-solc-0.8-simulate/contracts/interfaces/IUniswapV3Pool.sol";
import "src/libraries/PoolAddress.sol";

// AAVE
import "src/interfaces/Pool.sol";
import "src/interfaces/AToken.sol";
import "src/interfaces/PoolDataProvider.sol";
import "src/interfaces/PoolAddressesProvider.sol";
import "src/ERC20Container.sol";

contract Crank is IUniswapV3SwapCallback, Ownable, ERC20Container, UUPSUpgradeable {
    struct SwapCallbackData {
        PoolAddress.PoolKey poolKey;
        uint256 limit;
    }

    error Limit(); // frontrunning protection

    address _factory;
    PoolAddressesProvider _aave;

    function initialize(address owner, PoolAddressesProvider aave, address univ3Factory) external {
        // will revert if already initialized
        _initializeOwner(owner);
        _factory = univ3Factory;
        _aave = aave;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    uint16 public constant referralCode = 0;

    // transient storage callback lock to prevent unauthorized from flash swapping
    uint256 constant CALLBACK_LOCK = 0x364dc090748f5c0b79091ce041de48d4cffbbb61e8c524062913953b7ab199ef; //uint(keccak256("Crank Callback Lock"))

    ERC20 public constant weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 public constant wsteth = ERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    function _swap(bool zeroForOne, int256 amount, uint24 fee, uint160 sqrtPriceLimitX96, uint256 limit) internal {
        assembly {
            tstore(CALLBACK_LOCK, 1)
        }
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: address(wsteth), token1: address(weth), fee: fee});
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(_factory, poolKey));
        pool.swap(
            address(this),
            zeroForOne,
            amount,
            sqrtPriceLimitX96,
            abi.encode(SwapCallbackData({poolKey: poolKey, limit: limit}))
        );
        assembly {
            tstore(CALLBACK_LOCK, 0)
        }
    }

    function wind(uint256 wstethAmount, uint24 fee, uint160 sqrtPriceLimitX96, uint256 limit) external onlyOwner {
        _swap(false, -int256(wstethAmount), fee, sqrtPriceLimitX96, limit);
    }

    function unwind(uint256 wstethAmount, uint24 fee, uint160 sqrtPriceLimitX96, uint256 limit) external onlyOwner {
        _swap(true, int256(wstethAmount), fee, sqrtPriceLimitX96, limit);
    }

    function close(uint24 fee, uint160 sqrtPriceLimitX96, uint256 limit) external onlyOwner {
        (,, uint256 wethAmount,,,,,,) = _aave.getPoolDataProvider().getUserReserveData(address(weth), address(this));
        _swap(true, -int256(wethAmount), fee, sqrtPriceLimitX96, limit);
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        uint256 callbackLock;
        assembly {
            callbackLock := tload(CALLBACK_LOCK)
        }
        require(callbackLock != 0);
        SwapCallbackData memory decoded = abi.decode(data, (SwapCallbackData));
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(_factory, decoded.poolKey));
        require(msg.sender == address(pool));
        Pool lendingPool = _aave.getPool();

        if (amount1Delta > 0) {
            uint256 wethAmount = uint256(amount1Delta);
            require(wethAmount >= decoded.limit, Limit());
            uint256 wstethBalance = wsteth.balanceOf(address(this));
            wsteth.approve(address(lendingPool), wstethBalance);
            // keep 1 wei for the storage slots
            lendingPool.supply(address(wsteth), wstethBalance - 1, address(this), referralCode);

            lendingPool.borrow(address(weth), wethAmount, 2, referralCode, address(this));
            weth.transfer(msg.sender, wethAmount);
        } else {
            uint256 wethAmount = uint256(-amount1Delta);
            require(wethAmount >= decoded.limit, Limit());
            uint256 wstethAmount = uint256(amount0Delta);
            uint256 wethBalance = weth.balanceOf(address(this));
            weth.approve(address(lendingPool), wethBalance);
            // keep 1 wei for the storage slots
            lendingPool.repay(address(weth), wethBalance - 1, 2, address(this));
            lendingPool.withdraw(address(wsteth), wstethAmount, address(this));
            wsteth.transfer(msg.sender, wstethAmount);
        }
    }
}
