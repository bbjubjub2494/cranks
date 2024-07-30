// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console2} from "@forge-std-1.9.1/src/Test.sol";
import {Crank} from "src/Crank.sol";

import "src/interfaces/PoolAddressesProvider.sol";

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/ERC20.sol";
import "@solady-0.0.228/src/utils/LibClone.sol";

import "@uniswap-v3-core-1.0.2-solc-0.8-simulate/contracts/libraries/TickMath.sol";

contract CrankTest is Test {
    address constant owner = address(42);
    Crank dut;

    // Lido dedicated AAVE market on Mainnet
    PoolAddressesProvider aave = PoolAddressesProvider(0xcfBf336fe147D643B9Cb705648500e101504B16d);

    // UniV3 factory (Mainnet, Polygon, Optimism, Arbitrum, Testnets)
    address univ3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    ERC20 constant weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 constant wsteth = ERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    ERC20 constant aWsteth = ERC20(0xC035a7cf15375cE2706766804551791aD035E0C2);

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.label(address(weth), "weth");
        vm.label(address(wsteth), "wsteth");
        vm.label(address(aWsteth), "aWsteth");
        address impl = address(new Crank());
        dut = Crank(LibClone.deployERC1967(impl));
        dut.initialize(owner, aave, univ3Factory);

        vm.label(address(impl), "impl");
        vm.label(address(dut), "dut");
    }

    function test_auth() public {
        vm.startPrank(address(1337));
        vm.expectRevert(Ownable.Unauthorized.selector);
        dut.withdrawERC20(address(weth));
    }

    function approx(uint256 a, uint256 b) public pure returns (bool) {
        if (a > b) {
            (a, b) = (b, a);
        }
        return (b - a) * 1000 / b < 2;
    }

    function test_wind() public {
        uint160 sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
        deal(address(wsteth), address(dut), 1 ether);
        vm.startPrank(owner);
        dut.wind(1 ether, 100, sqrtPriceLimitX96, 0);
        assert(approx(aWsteth.balanceOf(address(dut)), 2 ether));
        sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        dut.unwind(0.5 ether, 100, sqrtPriceLimitX96, 0);
        assert(approx(aWsteth.balanceOf(address(dut)), 1.5 ether));
        sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
        dut.wind(1 ether, 100, sqrtPriceLimitX96, 0);
        assert(approx(aWsteth.balanceOf(address(dut)), 2.5 ether));
        sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        dut.close(100, sqrtPriceLimitX96, 0);
        assert(approx(aWsteth.balanceOf(address(dut)), 1 ether));
        dut.withdrawERC20(address(aWsteth));
    }

    function test_minAmountIn() public {
        uint160 sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
        deal(address(wsteth), address(dut), 1 ether);
        vm.startPrank(owner);
        vm.expectRevert(Crank.Limit.selector);
        dut.wind(1 ether, 100, sqrtPriceLimitX96, 1.5 ether);
        dut.wind(1 ether, 100, sqrtPriceLimitX96, 0);
        sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        vm.expectRevert(Crank.Limit.selector);
        dut.unwind(1 ether, 100, sqrtPriceLimitX96, 1.5 ether);
    }

    function test_upgrade() public {
        address impl = address(new Crank());
        vm.startPrank(owner);
        dut.upgradeToAndCall(impl, "");
        dut.withdrawERC20(address(weth));
    }
}
