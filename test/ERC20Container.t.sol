// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ERC20Container} from "src/ERC20Container.sol";

import {Test, console2} from "@forge-std-1.9.1/Test.sol";

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/WETH.sol";

contract DUT is ERC20Container {
    constructor() {
        _initializeOwner(msg.sender);
    }
}

contract ERC20ContainerTest is Test {
    address constant owner = address(42);
    WETH weth;
    DUT dut;

    function setUp() public {
        weth = new WETH();

        vm.prank(owner);
        dut = new DUT();
    }

    function test_deposit_withdraw() public {
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
        dut.withdrawERC20(address(weth));
    }
}
