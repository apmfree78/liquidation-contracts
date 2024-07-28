// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Define the interface
interface IPoolDataProvider {
    function getReserveData(address asset) external view returns (uint256 liquidityRate);
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

// Mock implementation of the interface
contract MockPoolDataProvider is IPoolDataProvider {
    mapping(address => uint256) public liquidityRates;
    mapping(address => uint256[6]) public userAccountData;

    // Function to set liquidity rates for different assets
    function setLiquidityRate(address asset, uint256 rate) public {
        liquidityRates[asset] = rate;
    }

    // Function returning liquidity rate for a given asset
    function getReserveData(address asset) external view override returns (uint256 liquidityRate) {
        return liquidityRates[asset];
    }

    // Function to set user account data
    function setUserAccountData(
        address user,
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    ) public {
        userAccountData[user] =
            [totalCollateralETH, totalDebtETH, availableBorrowsETH, currentLiquidationThreshold, ltv, healthFactor];
    }

    // Function returning user account data
    function getUserAccountData(address user)
        external
        view
        override
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        uint256[6] memory data = userAccountData[user];
        return (data[0], data[1], data[2], data[3], data[4], data[5]);
    }
}
