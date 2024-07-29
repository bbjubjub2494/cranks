// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@solady-0.0.228/src/auth/Ownable.sol";

// Module for containing native currency (on Mainnet: ETH) belonging to the owner
abstract contract NativeContainer is Ownable {
    receive() external payable {}

    function withdrawNative() external onlyOwner {
        // live dangerously. Works best assuming EIP-4758
        selfdestruct(payable(msg.sender));
    }
}
