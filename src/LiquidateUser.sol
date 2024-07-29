// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {console} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/interfaces/IERC20.sol";
import "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import "lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import "lib/aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IPoolDataProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";

contract LiquidateUser is IFlashLoanSimpleReceiver {
    struct User {
        address id;
        address debtToken;
        address collateralToken;
    }

    struct AccountToLiquidation {
        User user;
        uint256 debtToCover;
    }

    uint256 private constant LIQUIDATION_THRESHOLD = 1e18;
    uint256 private constant PROFIT_THRESHOLD = 50e18;
    address private immutable i_aavePoolAddress;
    address private immutable i_aaveDataProviderAddress;
    address private immutable i_aavePriceOracleAddress;
    address private immutable i_aavePoolAddressProvider;

    constructor(
        address aavePoolAddress,
        address aaveDataProviderAddress,
        address aavePriceOracleAddress,
        address aavePoolAddressProvider
    ) {
        i_aavePoolAddress = aavePoolAddress;
        i_aaveDataProviderAddress = aaveDataProviderAddress;
        i_aavePriceOracleAddress = aavePriceOracleAddress;
        i_aavePoolAddressProvider = aavePoolAddressProvider;
    }

    function findAndLiquidateAccount(User[] calldata users) external {
        uint256 userCount = users.length;
        IPool aavePool = IPool(i_aavePoolAddress);
        uint256 maxProfit = 0;
        AccountToLiquidation memory topProfitAccount;

        // cycle through each user account to see if
        // if health factor is in right range
        // AND profit after liquidation is sufficient hieght
        for (uint256 i = 0; i < userCount; i++) {
            address id = users[i].id;

            // get health factor
            (,,, uint256 liquidationThreshold,, uint256 healthFactor) = aavePool.getUserAccountData(id);
            console.log("health factor =>", healthFactor);

            if (healthFactor < LIQUIDATION_THRESHOLD) {
                // checkout profitability
                (uint256 profit, uint256 debtToCover) = getUserDebtToCoverAndProfit(users[i], liquidationThreshold);

                if (profit > PROFIT_THRESHOLD && profit > maxProfit) {
                    maxProfit = profit;

                    topProfitAccount = AccountToLiquidation({user: users[i], debtToCover: debtToCover});
                    // sender has sufficient balance to cover liquidation call
                }
            }
        }

        liquidateAccount(topProfitAccount);
    }

    function liquidateAccount(AccountToLiquidation memory account) private {
        if (account.user.id != address(0)) {
            IPool aavePool = IPool(i_aavePoolAddress);
            IERC20 debtToken = IERC20(account.user.debtToken);

            // TODO - ADD FLASH LOAN

            // if account fitting all criteria found , lets liquidate
            if (debtToken.balanceOf(address(this)) > account.debtToCover) {
                // submit account for liquidation,
                console.log("liquidating account");

                debtToken.approve(address(aavePool), account.debtToCover);

                aavePool.liquidationCall(
                    account.user.collateralToken, account.user.debtToken, account.user.id, account.debtToCover, false
                );
                console.log("Liqudation executed!");
            } else {
                console.log("Not enough tokens to cover the liqudation");
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

        uint256 totalDebt = getAaveTotalDebt(user.debtToken, user.id);

        // get collateral amount, token price, and liquidation values
        (uint256 aTokenBalance,,,,,,,, bool useAsCollateral) =
            poolDataProvider.getUserReserveData(user.collateralToken, user.id);

        uint256 liquidationBonus = getAaveLiquidationBonus(user.collateralToken);
        uint256 collateralPrice = priceOracle.getAssetPrice(user.collateralToken);

        // uint256 totalDebt = stableDebt + variableDebt;
        uint256 debtDecimalFactor = getTokenDecimalFactorFromAave(user.debtToken);
        uint256 collateralDecimalFactor = getTokenDecimalFactorFromAave(user.collateralToken);

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

    function getTokenDecimalFactorFromAave(address token) private view returns (uint256) {
        IPoolDataProvider poolDataProvider = IPoolDataProvider(i_aaveDataProviderAddress);
        (uint256 debtDecimals,,,,,,,,,) = poolDataProvider.getReserveConfigurationData(token);
        return 10 ** debtDecimals;
    }

    function getAaveLiquidationBonus(address token) private view returns (uint256) {
        IPoolDataProvider poolDataProvider = IPoolDataProvider(i_aaveDataProviderAddress);
        (,,, uint256 liquidationBonus,,,,,,) = poolDataProvider.getReserveConfigurationData(token);
        return liquidationBonus;
    }

    function getAaveTotalDebt(address token, address user) private view returns (uint256) {
        IPoolDataProvider poolDataProvider = IPoolDataProvider(i_aaveDataProviderAddress);
        (, uint256 stableDebt, uint256 variableDebt,,,,,,) = poolDataProvider.getUserReserveData(token, user);
        return stableDebt + variableDebt;
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bool)
    {}

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(i_aavePoolAddressProvider);
    }

    function POOL() external view returns (IPool) {
        return IPool(i_aavePoolAddress);
    }
}
