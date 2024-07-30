// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console2} from "@forge-std-1.9.1/src/Test.sol";
import {Crank} from "src/Crank.sol";

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/WETH.sol";

import "@uniswap-v3-core-1.0.2-solc-0.8-simulate/contracts/libraries/TickMath.sol";

contract CrankTest is Test {
	address constant owner = address(42);
	WETH weth;
	Crank dut;

    function setUp() public {
	weth = new WETH();

	vm.prank(owner);
	dut = new Crank();
    }

    function test_native() public {
	    startHoax(owner);
	    uint initialBalance = address(owner).balance;
	    payable(address(dut)).transfer(1000);
	    dut.withdrawNative();
	    assert(address(dut).balance == 0);
	    assert(owner.balance == initialBalance);

	    payable(address(dut)).transfer(1000);
	    assert(address(dut).balance == 1000);
	    assert(owner.balance == initialBalance -1000);

	    dut.withdrawNative();
	    assert(address(dut).balance == 0);
	    assert(owner.balance == initialBalance);
    }

    function test_erc20() public {
	    startHoax(owner);
	    weth.deposit{value: 1000}();
	    weth.transfer(address(dut), 1000);
	    dut.withdrawERC20(address(weth));
	    assert(weth.balanceOf(address(dut)) == 0);
	    assert(weth.balanceOf(owner) == 1000);

	    weth.transfer(address(dut), 1000);
	    assert(weth.balanceOf(address(dut)) == 1000);
	    assert(weth.balanceOf(owner) == 0);

	    dut.withdrawERC20(address(weth));
	    assert(weth.balanceOf(address(dut)) == 0);
	    assert(weth.balanceOf(owner) == 1000);
    }

    function test_auth() public {
	    vm.startPrank(address(1337));
	    vm.expectRevert(Ownable.Unauthorized.selector);
	    dut.withdrawNative();
	    vm.expectRevert(Ownable.Unauthorized.selector);
	    dut.withdrawERC20(address(weth));
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
    assert(aWsteth.balanceOf(address(dut)) == 1.5 ether);
    sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
    dut.wind(1 ether, 100, sqrtPriceLimitX96);
    assert(aWsteth.balanceOf(address(dut)) == 2.5 ether);
    }
}
