// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {console} from "lib/forge-std/src/Test.sol";
import "lib/aave-v3-core/contracts/mocks/oracle/PriceOracle.sol";

contract MockSwapRouter {
    uint24 public constant FEE_DENOMINATOR = 1e6; // To represent fee in parts per million for precision
    uint24 public constant FEE_PERCENTAGE = 3000; // Fee percentage in basis points, example: 0.3%
    address private immutable i_priceOracle;

    mapping(address => uint256[2]) tokenData; // price , decimals

    constructor(address priceOracleAddress) {
        i_priceOracle = priceOracleAddress;
    }

    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut)
    {
        require(block.timestamp <= params.deadline, "transaction expired");

        address tokenIn = params.tokenIn;
        address tokenOut = params.tokenOut;

        uint256 inTokenDecimalFactor = 10 ** IERC20(tokenIn).decimals();
        uint256 outTokenDecimalFactor = 10 ** IERC20(tokenOut).decimals();

        uint256 inTokenPrice = PriceOracle(i_priceOracle).getAssetPrice(tokenIn);
        uint256 outTokenPrice = PriceOracle(i_priceOracle).getAssetPrice(tokenOut);

        // calculate amountOutMax
        // TODO - CHECK scaling of value , looks off
        uint256 amountOutMax = (params.amountIn * inTokenPrice) / outTokenPrice;
        amountOutMax = (amountOutMax * outTokenDecimalFactor) / inTokenDecimalFactor;

        // Calculate the fee to apply on the amount out
        uint256 feeAmount = (amountOutMax * params.fee) / FEE_DENOMINATOR;
        amountOut = amountOutMax - feeAmount;

        console.log("amount out after fee", amountOut);
        require(amountOut >= params.amountOutMinimum, "minimum token output not met");
        require(IERC20(tokenIn).balanceOf(msg.sender) >= params.amountIn, "insufficient balance for swap");

        // Transfer amountIn to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), params.amountIn);

        // Simulate the swap by sending the exact output amount to the recipient
        IERC20(tokenOut).transfer(params.recipient, amountOut);

        // Simplify the return to just use the maximum input as the amount used for the swap
        return amountOut;
    }

    // ADD exactInputSingle mock

    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn)
    {
        require(block.timestamp <= params.deadline, "transaction expired");

        address tokenIn = params.tokenIn;
        address tokenOut = params.tokenOut;

        // Calculate the fee to apply on the amount out
        uint256 feeAmount = (params.amountOut * FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 amountOutPlusFee = params.amountOut + feeAmount;
        uint256 inTokenPrice = PriceOracle(i_priceOracle).getAssetPrice(tokenIn);
        uint256 outTokenPrice = PriceOracle(i_priceOracle).getAssetPrice(tokenOut);

        uint256 inTokenDecimalFactor = 10 ** IERC20(tokenIn).decimals();
        uint256 outTokenDecimalFactor = 10 ** IERC20(tokenOut).decimals();

        // TODO - CHECK scaling of value , looks off
        uint256 _amountIn = (amountOutPlusFee * outTokenPrice) / inTokenPrice;
        _amountIn = (_amountIn * inTokenDecimalFactor) / outTokenDecimalFactor;

        console.log("amount In for collateral", _amountIn);
        require(_amountIn < params.amountInMaximum, "cannot tranfer more than amountInMaximum");
        require(IERC20(tokenIn).balanceOf(msg.sender) >= _amountIn, "insufficient balance for swap");
        // Transfer the maximum amount allowed from the caller to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        // Simulate the swap by sending the exact output amount to the recipient
        IERC20(tokenOut).transfer(params.recipient, params.amountOut);

        // Simplify the return to just use the maximum input as the amount used for the swap
        return _amountIn;
    }

    function exactOutput(ISwapRouter.ExactOutputParams calldata params) external returns (uint256 amountIn) {
        // Decode path to find tokenIn and tokenOut
        // Assume path encodes tokenIn at start and tokenOut at an offset, simplified
        // Decode the path to get tokenIn and tokenOut addresses

        address tokenIn = getTokenIn(params.path);
        address tokenOut = getTokenOut(params.path);

        // Calculate the fee to apply on the amount out
        uint256 feeAmount = (params.amountOut * FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 amountOutPlusFee = params.amountOut + feeAmount;
        uint256 inTokenPrice = PriceOracle(i_priceOracle).getAssetPrice(tokenIn);
        uint256 outTokenPrice = PriceOracle(i_priceOracle).getAssetPrice(tokenOut);

        uint256 inTokenDecimalFactor = 10 ** IERC20(tokenIn).decimals();
        uint256 outTokenDecimalFactor = 10 ** IERC20(tokenOut).decimals();

        uint256 _amountIn = (amountOutPlusFee * outTokenPrice) / inTokenPrice;
        _amountIn = (_amountIn * inTokenDecimalFactor) / outTokenDecimalFactor;

        console.log("amount In for collateral", _amountIn);
        require(_amountIn < params.amountInMaximum, "cannot tranfer more than amountInMaximum");
        // Transfer the maximum amount allowed from the caller to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        // Simulate the swap by sending the exact output amount to the recipient
        IERC20(tokenOut).transfer(params.recipient, params.amountOut);

        // Simplify the return to just use the maximum input as the amount used for the swap
        return _amountIn;
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
