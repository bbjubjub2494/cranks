// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console2} from "@forge-std-1.9.1/src/Test.sol";
import {Crank} from "src/Crank.sol";

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/ERC20.sol";

import "@uniswap-v3-core-1.0.2-solc-0.8-simulate/contracts/libraries/TickMath.sol";

contract CrankTest is Test {
	address constant owner = address(42);
	Crank dut;

    function setUp() public {
	vm.prank(owner);
	dut = new Crank();
    }
    function test_auth() public {
	    vm.startPrank(address(1337));
	    // TODO
    }

    function approx(uint a, uint b) public pure returns (bool) {
	    if (a > b) {
		    (a, b) = (b, a);
	    }
	    return (b-a)*1000/b < 2;
    }

    function test_wind() public {
    ERC20 weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 wsteth = ERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    ERC20 aWsteth = ERC20(0xC035a7cf15375cE2706766804551791aD035E0C2);
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
	dut = new Crank();
	uint160 sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
    deal(address(wsteth), address(dut), 1 ether);
    dut.wind(1 ether, 100, sqrtPriceLimitX96);
    assert(aWsteth.balanceOf(address(dut)) == 2 ether);
    sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
    dut.unwind(.5 ether, 100, sqrtPriceLimitX96);
    assert(approx(aWsteth.balanceOf(address(dut)), 1.5 ether));
    sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
    dut.wind(1 ether, 100, sqrtPriceLimitX96);
    assert(approx(aWsteth.balanceOf(address(dut)), 2.5 ether));
    sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
    dut.close(100, sqrtPriceLimitX96);
    assert(approx(aWsteth.balanceOf(address(dut)), 1 ether));
    dut.withdrawERC20(address(aWsteth));
    }
}
