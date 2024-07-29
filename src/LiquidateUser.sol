// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {console} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/interfaces/IERC20.sol";
import "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import "lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import {IPoolDataProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";

contract LiquidateUser {
    struct User {
        address id;
        address debtToken;
        address collateralToken;
    }

    uint256 private constant LIQUIDATION_THRESHOLD = 1e18;
    uint256 private constant PROFIT_THRESHOLD = 50e18;
    address private immutable i_aavePoolAddress;
    address private immutable i_aaveDataProviderAddress;
    address private immutable i_aavePriceOracleAddress;

    constructor(address aavePoolAddress, address aaveDataProviderAddress, address aavePriceOracleAddress) {
        i_aavePoolAddress = aavePoolAddress;
        i_aaveDataProviderAddress = aaveDataProviderAddress;
        i_aavePriceOracleAddress = aavePriceOracleAddress;
    }

    function liquidateUserAccounts(User[] calldata users) external {
        uint256 userCount = users.length;
        IPool aavePool = IPool(i_aavePoolAddress);

        for (uint256 i = 0; i < userCount; i++) {
            address id = users[i].id;
            address debtTokenAddress = users[i].debtToken;
            address collateralTokenAddress = users[i].collateralToken;
            IERC20 debtToken = IERC20(debtTokenAddress);

            // get health factor
            (,,, uint256 liquidationThreshold,, uint256 healthFactor) = aavePool.getUserAccountData(id);
            console.log("health factor =>", healthFactor);

            if (healthFactor < LIQUIDATION_THRESHOLD) {
                // checkout profitability
                (uint256 profit, uint256 debtToCover) = getUserDebtToCoverAndProfit(users[i], liquidationThreshold);

                if (profit > PROFIT_THRESHOLD) {
                    // sender has sufficient balance to cover liquidation call
                    if (debtToken.balanceOf(msg.sender) > debtToCover) {
                        // submit account for liquidation,
                        console.log("liquidating account");
                        aavePool.liquidationCall(collateralTokenAddress, debtTokenAddress, id, type(uint256).max, false);
                    }
                }
            }
        }
    }

    function getUserDebtToCoverAndProfit(User calldata user, uint256 liquidationThreshold)
        private
        view
        returns (uint256, uint256)
    {
        IPoolDataProvider poolDataProvider = IPoolDataProvider(i_aaveDataProviderAddress);
        IPriceOracle priceOracle = IPriceOracle(i_aavePriceOracleAddress);
        uint256 standardScaleFactor = 10 ** 18;
        uint256 bpsFactor = 10 ** 4;

        // get debt amount
        (, uint256 stableDebt, uint256 variableDebt,,,,,,) =
            poolDataProvider.getUserReserveData(user.debtToken, user.id);

        (uint256 debtDecimals,,,,,,,,,) = poolDataProvider.getReserveConfigurationData(user.debtToken);

        // get collateral amount, token price, and liquidation values
        (uint256 aTokenBalance,,,,,,,, bool useAsCollateral) =
            poolDataProvider.getUserReserveData(user.collateralToken, user.id);

        (uint256 collateralDecimals,,, uint256 liquidationBonus,,,,,,) =
            poolDataProvider.getReserveConfigurationData(user.collateralToken);
        uint256 collateralPrice = priceOracle.getAssetPrice(user.collateralToken);

        uint256 totalDebt = stableDebt + variableDebt;
        uint256 debtDecimalFactor = 10 ** debtDecimals;
        uint256 collateralDecimalFactor = 10 ** collateralDecimals;

        /**
         * CALCULATE DEBT TO COVER - THIS WILL DETERMINE HOW MUCH COLLATERAL TO BORROW FROM FLASH FLOAN
         *
         */
        uint256 debtToCover = totalDebt * liquidationThreshold;

        debtToCover = debtToCover / debtDecimalFactor;

        debtToCover = debtToCover * collateralPrice;

        // final scaled debtToCover value
        debtToCover = debtToCover / standardScaleFactor;

        /**
         * CALCULATE ESTIMATED PROFIT - THIS WILL DETERMINE IF ITS WORTH LIQUIDATING ACCOUNT
         *
         */
        if (liquidationBonus > 0 && useAsCollateral) {
            uint256 profitUsd = debtToCover * aTokenBalance;

            profitUsd = profitUsd / collateralDecimalFactor;

            profitUsd = profitUsd * liquidationBonus;

            profitUsd = profitUsd * (liquidationBonus - bpsFactor);

            profitUsd = profitUsd / bpsFactor;

            profitUsd = profitUsd / bpsFactor;

            return (profitUsd, debtToCover);
        } else {
            return (0, 0);
        }
    }
}
