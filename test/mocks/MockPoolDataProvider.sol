// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";

// Mock implementation of the interface
contract MockPoolDataProvider {
    struct ReserveData {
        uint256 currentATokenBalance;
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        uint256 principalStableDebt;
        uint256 scaledVariableDebt;
        uint256 stableBorrowRate;
        uint256 liquidityRate;
        uint40 stableRateLastUpdated;
        bool usageAsCollateralEnabled;
    }

    struct ReserveConfiguration {
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 reserveFactor;
        bool usageAsCollateralEnabled;
        bool borrowingEnabled;
        bool stableBorrowRateEnabled;
        bool isActive;
        bool isFrozen;
    }

    mapping(address => mapping(address => ReserveData)) public reserveData;
    mapping(address => ReserveConfiguration) public reserveConfiguration;

    // Function to set user account data
    function setUserReserveData(
        address user,
        address asset,
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    ) public {
        reserveData[user][asset] = ReserveData({
            currentATokenBalance: currentATokenBalance,
            currentStableDebt: currentStableDebt,
            currentVariableDebt: currentVariableDebt,
            principalStableDebt: principalStableDebt,
            scaledVariableDebt: scaledVariableDebt,
            stableBorrowRate: stableBorrowRate,
            liquidityRate: liquidityRate,
            stableRateLastUpdated: stableRateLastUpdated,
            usageAsCollateralEnabled: usageAsCollateralEnabled
        });
    }

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        )
    {
        ReserveData memory data = reserveData[user][asset];
        return (
            data.currentATokenBalance,
            data.currentStableDebt,
            data.currentVariableDebt,
            data.principalStableDebt,
            data.scaledVariableDebt,
            data.stableBorrowRate,
            data.liquidityRate,
            data.stableRateLastUpdated,
            data.usageAsCollateralEnabled
        );
    }

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        )
    {
        ReserveConfiguration memory data = reserveConfiguration[asset];

        return (
            data.decimals,
            data.ltv,
            data.liquidationThreshold,
            data.liquidationBonus,
            data.reserveFactor,
            data.usageAsCollateralEnabled,
            data.borrowingEnabled,
            data.stableBorrowRateEnabled,
            data.isActive,
            data.isFrozen
        );
    }

    function setReserveConfigurationData(
        address asset,
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    ) external {
        reserveConfiguration[asset] = ReserveConfiguration({
            decimals: decimals,
            ltv: ltv,
            liquidationThreshold: liquidationThreshold,
            liquidationBonus: liquidationBonus,
            reserveFactor: reserveFactor,
            usageAsCollateralEnabled: usageAsCollateralEnabled,
            borrowingEnabled: borrowingEnabled,
            stableBorrowRateEnabled: stableBorrowRateEnabled,
            isActive: isActive,
            isFrozen: isFrozen
        });
    }
}
