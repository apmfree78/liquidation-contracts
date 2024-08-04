// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {console} from "lib/forge-std/src/Test.sol";

contract MockSwapRouter {
    function exactOutput(ISwapRouter.ExactOutputParams calldata params) external returns (uint256 amountIn) {
        // Decode path to find tokenIn and tokenOut
        // Assume path encodes tokenIn at start and tokenOut at an offset, simplified
        // Decode the path to get tokenIn and tokenOut addresses

        address tokenIn = getTokenIn(params.path);
        address tokenOut = getTokenOut(params.path);
        // address[] memory path = abi.decode(params.path, (address[]));
        // address tokenIn = path[0];
        // address tokenOut = path[path.length - 1];

        // Transfer the maximum amount allowed from the caller to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), params.amountInMaximum);

        // Simulate the swap by sending the exact output amount to the recipient
        IERC20(tokenOut).transfer(params.recipient, params.amountOut);

        // Simplify the return to just use the maximum input as the amount used for the swap
        return params.amountInMaximum;
    }

    function getTokenIn(bytes memory path) internal pure returns (address tokenIn) {
        require(path.length >= 20, "Invalid path length");
        // Extract tokenIn from the first 20 bytes of the path
        assembly {
            tokenIn := div(mload(add(path, 32)), 0x1000000000000000000000000)
        }
    }

    function getTokenOut(bytes memory path) internal pure returns (address tokenOut) {
        require(path.length >= 20, "Invalid path length");

        // Extract tokenOut from the last 20 bytes of the path
        // Here, we're calculating the correct offset to get the last token in the path
        assembly {
            tokenOut := div(mload(add(path, add(32, sub(mload(path), 20)))), 0x1000000000000000000000000)
        }
    }
}
