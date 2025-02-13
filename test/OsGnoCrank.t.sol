// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console2} from "@forge-std-1.9.1/src/Test.sol";
import "src/OsGnoCrank.sol";

import "src/interfaces/PoolAddressesProvider.sol";

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/ERC20.sol";
import "@solady-0.0.228/src/utils/LibClone.sol";

    uint constant GNOSIS_CHAINID = 100;

contract OsGnoCrankTest is Test {
    address constant owner = address(42);
    OsGnoCrank dut;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.label(address(gno), "Gno");
        vm.label(address(osgno), "OsGno");
        //vm.label(address(aave_pool), "AAVE Pool");
        address impl = address(new OsGnoCrank());
        dut = OsGnoCrank(LibClone.deployERC1967(impl));
	dut.initialize(owner);

        vm.label(address(impl), "impl");
        vm.label(address(dut), "dut");
    }

    function ensureChainId() internal {
	vm.skip(block.chainid != GNOSIS_CHAINID);
    }

    function test_auth() public {
	    ensureChainId();
        vm.startPrank(address(1337));
        vm.expectRevert(Ownable.Unauthorized.selector);
        dut.withdrawERC20(address(gno));
    }

    function approx(uint256 a, uint256 b) public pure returns (bool) {
        if (a > b) {
            (a, b) = (b, a);
        }
        return (b - a) * 1000 / b < 2;
    }

    function test_upgrade() public {
	    ensureChainId();
        address impl = address(new OsGnoCrank());
        vm.startPrank(owner);
        dut.upgradeToAndCall(impl, "");
        dut.withdrawERC20(address(gno));
    }

    function test_wind() public {
	    ensureChainId();
	    deal(address(gno), address(this), 1 ether);
	    gno.approve(address(stakewiseVault), 1 ether);
	    stakewiseVault.deposit(1 ether, address(dut), address(0));
	    vm.prank(owner);
	    dut.wind(1 ether);
    }
}
