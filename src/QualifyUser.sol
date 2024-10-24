// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {console} from "lib/forge-std/src/Test.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPool} from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPriceOracle} from "lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import {IPoolDataProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";

contract QualifyUser {
    error NoUserAccountQualifiedForLiquidation();

    struct User {
        address id;
        address debtToken;
        address collateralToken;
    }

    struct TopProfitUserAccount {
        address userId;
        address debtToken;
        address collateralToken;
        uint256 debtToCover;
        uint256 profit;
    }

    TopProfitUserAccount public topProfitAccount;

    uint256 private constant LIQUIDATION_HF_THRESHOLD = 1e18;
    uint256 private constant MIN_HEALTH_SCORE_THRESHOLD = 1e17;
    uint256 private constant STANDARD_SCALE_FACTOR = 1e18;
    uint256 private constant BPS_FACTOR = 1e4;
    uint256 private constant CLOSE_FACTOR_HF_THRESHOLD = 95e16;

    address private immutable i_aavePoolAddress;
    address private immutable i_aaveDataProviderAddress;
    address private immutable i_aavePriceOracleAddress;

    constructor(address aavePoolAddress, address aaveDataProviderAddress, address aavePriceOracleAddress) {
        i_aavePoolAddress = aavePoolAddress;
        i_aaveDataProviderAddress = aaveDataProviderAddress;
        i_aavePriceOracleAddress = aavePriceOracleAddress;
    }

    function checkUserAccounts(User[] calldata users) external {
        uint256 userCount = users.length;
        IPool aavePool = IPool(i_aavePoolAddress);
        uint256 maxProfit = 0;
        TopProfitUserAccount memory userAccount;

        // cycle through each user account to see if
        // if health factor is in right range
        // AND profit after liquidation is sufficient hieght
        for (uint256 i = 0; i < userCount; i++) {
            address id = users[i].id;

            // get health factor
            (,,,,, uint256 healthFactor) = aavePool.getUserAccountData(id);
            // console.log("health factor =>", healthFactor);

            if (healthFactor < LIQUIDATION_HF_THRESHOLD && healthFactor > MIN_HEALTH_SCORE_THRESHOLD) {
                // if (healthFactor > MIN_HEALTH_SCORE_THRESHOLD) {
                // checkout profitability
                (uint256 profit, uint256 debtToCover) = getUserDebtToCoverAndProfit(users[i], healthFactor);

                if (profit > maxProfit) {
                    maxProfit = profit;

                    userAccount = TopProfitUserAccount({
                        userId: users[i].id,
                        debtToken: users[i].debtToken,
                        collateralToken: users[i].collateralToken,
                        debtToCover: debtToCover,
                        profit: profit
                    });
                }
            }
        }

        // save state
        topProfitAccount = userAccount;
    }

    function getUserDebtToCoverAndProfit(User calldata user, uint256 healthFactor)
        private
        view
        returns (uint256, uint256)
    {
        IPoolDataProvider poolDataProvider = IPoolDataProvider(i_aaveDataProviderAddress);
        IPriceOracle priceOracle = IPriceOracle(i_aavePriceOracleAddress);

        uint256 totalDebt = getAaveTotalDebt(user.debtToken, user.id);

        // get collateral amount, token price, and liquidation values
        (,,,,,,,, bool useAsCollateral) = poolDataProvider.getUserReserveData(user.collateralToken, user.id);

        uint256 liquidationThreshold = 5e17; // 0.5
        if (healthFactor < CLOSE_FACTOR_HF_THRESHOLD) liquidationThreshold = 1e18;

        uint256 liquidationBonus = getAaveLiquidationBonus(user.collateralToken);
        uint256 debtPrice = priceOracle.getAssetPrice(user.debtToken);

        // uint256 totalDebt = stableDebt + variableDebt;
        uint256 debtDecimalFactor = getTokenDecimalFactor(user.debtToken);

        // console.log("debt token => ", user.debtToken);
        // console.log("collateral token => ", user.collateralToken);
        // console.log("total debt =>", totalDebt);
        // console.log("debt token Price =>", debtPrice);

        /**
         * CALCULATE DEBT TO COVER - THIS WILL DETERMINE HOW MUCH COLLATERAL TO BORROW FROM FLASH FLOAN
         *
         */
        uint256 debtToCover = totalDebt * liquidationThreshold;

        debtToCover = debtToCover / STANDARD_SCALE_FACTOR;

        /**
         * CALCULATE ESTIMATED PROFIT - THIS WILL DETERMINE IF ITS WORTH LIQUIDATING ACCOUNT
         *
         */
        if (liquidationBonus > 0 && useAsCollateral) {
            uint256 profitUsd = (debtToCover * debtPrice) / debtDecimalFactor;

            profitUsd = profitUsd * liquidationBonus;

            profitUsd = profitUsd * (liquidationBonus - BPS_FACTOR);

            profitUsd = profitUsd / BPS_FACTOR;

            profitUsd = profitUsd / BPS_FACTOR;

            // console.log("debtToCover ==>", debtToCover);
            // console.log("profit (scaled by le8 ==>", profitUsd);
            return (profitUsd, debtToCover);
        } else {
            return (0, 0);
        }
    }

    function getTokenDecimalFactor(address token) private view returns (uint256) {
        uint8 decimals;
        try IERC20Metadata(token).decimals() returns (uint8 dec) {
            decimals = dec;
        } catch {
            decimals = 18;
        }
        return 10 ** decimals;
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
}
