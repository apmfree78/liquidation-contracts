// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {console} from "lib/forge-std/src/Test.sol";

contract MockSwapRouter {
    uint24 public constant FEE_DENOMINATOR = 1e6; // To represent fee in parts per million for precision
    uint24 public constant FEE_PERCENTAGE = 3000; // Fee percentage in basis points, example: 0.3%

    mapping(address => uint256) tokenPrice;

    function exactOutput(ISwapRouter.ExactOutputParams calldata params) external returns (uint256 amountIn) {
        // Decode path to find tokenIn and tokenOut
        // Assume path encodes tokenIn at start and tokenOut at an offset, simplified
        // Decode the path to get tokenIn and tokenOut addresses

        address tokenIn = getTokenIn(params.path);
        address tokenOut = getTokenOut(params.path);

        // Calculate the fee to apply on the amount out
        uint256 feeAmount = (params.amountOut * FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 amountOutPlusFee = params.amountOut + feeAmount;

        uint256 amountIn = (amountOutPlusFee * tokenPrice[tokenOut]) / tokenPrice[tokenIn];

        // Transfer the maximum amount allowed from the caller to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Simulate the swap by sending the exact output amount to the recipient
        IERC20(tokenOut).transfer(params.recipient, params.amountOut);

        // Simplify the return to just use the maximum input as the amount used for the swap
        return amountIn;
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

    function getTokenPrice(address token) public view returns (uint256) {
        return tokenPrice[token];
    }

    function setTokenPrice(address token, uint256 price) public {
        tokenPrice[token] = price;
    }
}
