// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {console} from "lib/forge-std/src/Test.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {IPool} from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPriceOracle} from "lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import {IFlashLoanSimpleReceiver} from "lib/aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IPoolDataProvider, IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract LiquidateUser is IFlashLoanSimpleReceiver {
    error NoCollateralToken();
    error InsufficientBalanceToPayLoan();

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
    uint256 private constant MIN_HEALTH_SCORE_THRESHOLD = 1e17;
    uint256 private constant PROFIT_THRESHOLD = 50e18;
    address private immutable i_aavePoolAddress;
    address private immutable i_aaveDataProviderAddress;
    address private immutable i_aavePriceOracleAddress;
    address private immutable i_aavePoolAddressProviderAddress;
    address private immutable i_swapRouterAddress;
    address private immutable i_walletAddress; // send profit here at end

    constructor(
        address aavePoolAddress,
        address aaveDataProviderAddress,
        address aavePriceOracleAddress,
        address aavePoolAddressProviderAddress,
        address swapRouterAddress,
        address walletAddress
    ) {
        i_aavePoolAddress = aavePoolAddress;
        i_aaveDataProviderAddress = aaveDataProviderAddress;
        i_aavePriceOracleAddress = aavePriceOracleAddress;
        i_aavePoolAddressProviderAddress = aavePoolAddressProviderAddress;
        i_swapRouterAddress = swapRouterAddress;
        i_walletAddress = walletAddress;
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

            if (healthFactor < LIQUIDATION_THRESHOLD && healthFactor > MIN_HEALTH_SCORE_THRESHOLD) {
                // checkout profitability
                (uint256 profit, uint256 debtToCover) = getUserDebtToCoverAndProfit(users[i], liquidationThreshold);

                if (profit > PROFIT_THRESHOLD && profit > maxProfit) {
                    maxProfit = profit;

                    topProfitAccount = AccountToLiquidation({user: users[i], debtToCover: debtToCover});
                    // sender has sufficient balance to cover liquidation call
                }
            }
        }

        // check that we found a valid and profitable account to liquidate
        if (topProfitAccount.user.id != address(0)) {
            // FLASH LOAN for DebtToken amount of DebtToCover
            bytes memory params = abi.encode(topProfitAccount.user.collateralToken, topProfitAccount.user.id);
            aavePool.flashLoanSimple(
                address(this), topProfitAccount.user.debtToken, topProfitAccount.debtToCover, params, 0
            );
        }
    }

    // this function gets called as callback when aavePool.flashLoanSimple(..) is run
    function executeOperation(address asset, uint256 amount, uint256 premium, address, bytes calldata params)
        external
        returns (bool)
    {
        (address collateralTokenAddress, address userId) = abi.decode(params, (address, address));

        AccountToLiquidation memory account = AccountToLiquidation({
            user: User({id: userId, debtToken: asset, collateralToken: collateralTokenAddress}),
            debtToCover: amount
        });

        liquidateAccount(account);

        // now that account is liquidated need to swap the collateral token recieved for
        // debt token (asset) in amount of amount + premium
        swapCollateralForDebtTokenToRepayLoan(collateralTokenAddress, asset, amount + premium);

        transferProfitToWallet(collateralTokenAddress, asset, amount + premium);
        return true;
    }

    function swapCollateralForDebtTokenToRepayLoan(
        address collateralTokenAddress,
        address debtTokenAddress,
        uint256 debtAmount
    ) private {
        IERC20 debtToken = IERC20(debtTokenAddress);
        IERC20 collateralToken = IERC20(collateralTokenAddress);
        ISwapRouter swapRouter = ISwapRouter(i_swapRouterAddress);

        // sanity check , contract should now have a positive balance of collateral token
        if (collateralToken.balanceOf(address(this)) == 0) revert NoCollateralToken();

        // need amount + premium of debtToken to pay off loan, use uniswap to get this amount
        uint256 loanRepaymentAmount = debtAmount;
        uint256 amountInMax = collateralToken.balanceOf(address(this));

        ISwapRouter.ExactOutputSingleParams memory swapParams = ISwapRouter.ExactOutputSingleParams({
            tokenIn: collateralTokenAddress,
            tokenOut: debtTokenAddress,
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp + 300,
            amountOut: loanRepaymentAmount,
            amountInMaximum: amountInMax,
            sqrtPriceLimitX96: 0
        });

        // token swap
        collateralToken.approve(address(swapRouter), amountInMax);
        swapRouter.exactOutputSingle(swapParams);

        // check swap was a successful
        if (debtToken.balanceOf(address(this)) >= loanRepaymentAmount) {
            revert InsufficientBalanceToPayLoan();
        }
    }

    function liquidateAccount(AccountToLiquidation memory account) private {
        IPool aavePool = IPool(i_aavePoolAddress);
        IERC20 debtToken = IERC20(account.user.debtToken);

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

    function transferProfitToWallet(address collateralTokenAddress, address debtTokenAddress, uint256 repaymentAmount)
        private
    {
        IERC20 debtToken = IERC20(debtTokenAddress);
        IERC20 collateralToken = IERC20(collateralTokenAddress);

        uint256 collateralAmount = collateralToken.balanceOf(address(this));
        uint256 debtAmount = collateralToken.balanceOf(address(this));

        collateralToken.transfer(i_walletAddress, collateralAmount);

        if (debtAmount > repaymentAmount) {
            uint256 remainingBalance = debtAmount - repaymentAmount;
            debtToken.transfer(i_walletAddress, remainingBalance);
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

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(i_aavePoolAddressProviderAddress);
    }

    function POOL() external view returns (IPool) {
        return IPool(i_aavePoolAddress);
    }
}
