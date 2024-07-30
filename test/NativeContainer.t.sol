// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {NativeContainer} from "src/NativeContainer.sol";

import {Test, console2} from "@forge-std-1.9.1/src/Test.sol";

import "@solady-0.0.228/src/auth/Ownable.sol";

contract DUT is NativeContainer {
    constructor() {
        _initializeOwner(msg.sender);
    }
}

contract NativeContainerTest is Test {
    address constant owner = address(42);
    DUT dut;

    function setUp() public {
        vm.prank(owner);
        dut = new DUT();
    }

    function test_deposit_withdraw() public {
        startHoax(owner);
        uint256 initialBalance = address(owner).balance;
        payable(address(dut)).transfer(1000);
        dut.withdrawNative();
        assert(address(dut).balance == 0);
        assert(owner.balance == initialBalance);

        payable(address(dut)).transfer(1000);
        assert(address(dut).balance == 1000);
        assert(owner.balance == initialBalance - 1000);

        dut.withdrawNative();
        assert(address(dut).balance == 0);
        assert(owner.balance == initialBalance);
    }

    function test_auth() public {
        vm.startPrank(address(1337));
        vm.expectRevert(Ownable.Unauthorized.selector);
        dut.withdrawNative();
    }
}
