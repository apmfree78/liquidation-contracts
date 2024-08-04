// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {console} from "lib/forge-std/src/Test.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {IPool} from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPriceOracle} from "lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import {IFlashLoanSimpleReceiver} from "lib/aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IPoolDataProvider, IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "utils/ReentracyGuard.sol";

contract LiquidateUser is IFlashLoanSimpleReceiver, ReentrancyGuard {
    error NoCollateralToken();
    error InsufficientBalanceToPayLoan();
    error NotEnoughDebtTokenToCoverLiquidation();

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
    uint256 private constant STANDARD_SCALE_FACTOR = 1e18;
    uint256 private constant BPS_FACTOR = 1e4;
    uint256 private constant CLOSE_FACTOR_HF_THRESHOLD = 95e16;

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

    event LiquidateAccount(
        address indexed liquidator,
        address indexed beneficiary,
        address indexed collateralToken,
        uint256 profit,
        address user
    );

    function findAndLiquidateAccount(User[] calldata users) external noReentrancy {
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
            (,,,,, uint256 healthFactor) = aavePool.getUserAccountData(id);
            console.log("health factor =>", healthFactor);

            if (healthFactor < LIQUIDATION_THRESHOLD && healthFactor > MIN_HEALTH_SCORE_THRESHOLD) {
                // checkout profitability
                (uint256 profit, uint256 debtToCover) = getUserDebtToCoverAndProfit(users[i], healthFactor);

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
            console.log("profit => ", maxProfit);
            console.log("debt to Cover => ", topProfitAccount.debtToCover);
            bytes memory params = abi.encode(topProfitAccount.user.collateralToken, topProfitAccount.user.id);
            aavePool.flashLoanSimple(
                address(this), topProfitAccount.user.debtToken, topProfitAccount.debtToCover, params, 0
            );

            console.log("flashloan successfully executed and liquidation successful!");
            emit LiquidateAccount(
                address(this),
                i_walletAddress,
                topProfitAccount.user.collateralToken,
                maxProfit,
                topProfitAccount.user.id
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

        console.log("liquidating account!");
        liquidateAccount(account);

        // now that account is liquidated need to swap the collateral token recieved for
        // debt token (asset) in amount of amount + premium
        IERC20 debtToken = IERC20(asset);
        IERC20 collateralToken = IERC20(collateralTokenAddress);
        console.log("debt token balanc before swap => ", debtToken.balanceOf(address(this)));

        // TODO - UPDATE THIS PLEASE!!!
        if (collateralTokenAddress != asset) {
            console.log("swapping collateral token debt token to pay off debt");
            swapCollateralForDebtTokenToRepayLoan(collateralTokenAddress, asset, amount + premium);
        }

        console.log("collateral token balance AFTER swap => ", collateralToken.balanceOf(address(this)));
        console.log("transfering remaining collateral token to liquidator wallet");
        transferProfitToWallet(collateralTokenAddress, asset, amount + premium);
        return true;
    }

    function swapCollateralForDebtTokenToRepayLoan(
        address collateralTokenAddress,
        address debtTokenAddress,
        uint256 loanRepaymentAmount
    ) private {
        IERC20 debtToken = IERC20(debtTokenAddress);
        IERC20 collateralToken = IERC20(collateralTokenAddress);
        ISwapRouter swapRouter = ISwapRouter(i_swapRouterAddress);

        // sanity check , contract should now have a positive balance of collateral token
        if (collateralToken.balanceOf(address(this)) == 0) revert NoCollateralToken();

        // need amount + premium of debtToken to pay off loan, use uniswap to get this amount
        uint256 amountInMax = collateralToken.balanceOf(address(this));
        bytes memory path = abi.encodePacked(collateralTokenAddress, uint24(3000), debtTokenAddress);

        // TODO - CHECK the values you are submitting , should
        ISwapRouter.ExactOutputParams memory swapParams = ISwapRouter.ExactOutputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp + 300,
            amountOut: loanRepaymentAmount,
            amountInMaximum: amountInMax
        });

        // token swap
        collateralToken.approve(address(swapRouter), amountInMax);
        swapRouter.exactOutput(swapParams);

        // check swap was a successful
        console.log("token swap successful");
        if (debtToken.balanceOf(address(this)) < loanRepaymentAmount) {
            revert InsufficientBalanceToPayLoan();
        }
    }

    function liquidateAccount(AccountToLiquidation memory account) private {
        IPool aavePool = IPool(i_aavePoolAddress);
        IERC20 debtToken = IERC20(account.user.debtToken);

        // if account fitting all criteria found , lets liquidate
        if (debtToken.balanceOf(address(this)) >= account.debtToCover) {
            console.log("debt Token balance =>", debtToken.balanceOf(address(this)));
            // submit account for liquidation,
            debtToken.approve(address(aavePool), account.debtToCover * 3);
            aavePool.liquidationCall(
                account.user.collateralToken, account.user.debtToken, account.user.id, account.debtToCover, false
            );

            console.log("debt Token balance after liquidation =>", debtToken.balanceOf(address(this)));
            console.log("Liqudation executed!");
        } else {
            console.log("Not enough tokens to cover the liqudation");
            revert NotEnoughDebtTokenToCoverLiquidation();
        }
    }

    function transferProfitToWallet(address collateralTokenAddress, address debtTokenAddress, uint256 repaymentAmount)
        private
    {
        IERC20 debtToken = IERC20(debtTokenAddress);
        IERC20 collateralToken = IERC20(collateralTokenAddress);

        uint256 collateralAmount = collateralToken.balanceOf(address(this));
        uint256 debtAmount = debtToken.balanceOf(address(this));

        if (collateralTokenAddress != debtTokenAddress) {
            // collateralToken.approve(address(this), collateralAmount);
            collateralToken.transfer(i_walletAddress, collateralAmount);
            console.log("profit taken of amount (collateral Token)", collateralAmount);
        }

        if (debtAmount > repaymentAmount) {
            uint256 remainingBalance = debtAmount - repaymentAmount;
            console.log("remaining balance", remainingBalance);
            // debtToken.approve(address(this), remainingBalance);
            debtToken.transfer(i_walletAddress, remainingBalance);

            uint256 debtBalance = debtToken.balanceOf(address(this));
            if (debtBalance < repaymentAmount) revert InsufficientBalanceToPayLoan();

            console.log("profit taken of amount (outstading debt token)", remainingBalance);
        }
    }

    // TODO - THIS IS WRONG LIQUIDATION THRESHOLD -- FIX
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
        uint256 debtDecimalFactor = getTokenDecimalFactorFromAave(user.debtToken);

        console.log("debt token => ", user.debtToken);
        console.log("collateral token => ", user.collateralToken);
        console.log("totaldebt =>", totalDebt);
        console.log("user as Collateral =>", useAsCollateral);
        console.log("liquidationThreshold =>", liquidationThreshold);
        console.log("liquidationBonus =>", liquidationBonus);
        console.log("collateral Price =>", debtPrice);
        console.log("debt debtDecimalFactor =>", debtDecimalFactor);

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

            // console.log("profitUSD => ", profitUsd);
            // console.log("debt to Cover => ", debtToCover);
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
