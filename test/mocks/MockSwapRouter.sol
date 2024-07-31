// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";

contract MockSwapRouter {
    function exactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint256 deadline,
        uint256 amountOut,
        uint256 amountInMaximum,
        uint256 sqrtPriceLimitX96
    ) external returns (uint256 amountIn) {
        // Assume token transfer is successful for simplicity
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountInMaximum);
        IERC20(tokenOut).transfer(recipient, amountOut);

        // Mock the amount of input used for the swap
        return amountInMaximum; // Simplified example
    }
}
