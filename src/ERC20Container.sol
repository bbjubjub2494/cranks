// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@solady-0.0.228/src/auth/Ownable.sol";
import "@solady-0.0.228/src/tokens/ERC20.sol";

// Module for containing ERC20 tokens belonging to the owner
abstract contract ERC20Container is Ownable {
    // nothing to do to receive ERC20 tokens

    function withdrawERC20(address token) external onlyOwner {
        ERC20(token).transfer(msg.sender, ERC20(token).balanceOf(address(this)));
    }
}
