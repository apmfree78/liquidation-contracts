// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {console} from "lib/forge-std/src/Test.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/safeERC20.sol";
import {IPool} from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPriceOracle} from "lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import {IFlashLoanSimpleReceiver} from "lib/aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IPoolDataProvider, IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "utils/ReentracyGuard.sol";

using SafeERC20 for IERC20;

contract LiquidateUser is IFlashLoanSimpleReceiver, ReentrancyGuard {
    error NoCollateralToken();
    error InsufficientBalanceToPayLoan();
    error NotEnoughDebtTokenToCoverLiquidation();
    error NoUserAccountQualifiedForLiquidation();

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
    uint256 private constant PROFIT_THRESHOLD = 50e18; // TODO - update to $100??
    uint256 private constant STANDARD_SCALE_FACTOR = 1e18;
    uint256 private constant BPS_FACTOR = 1e4;
    uint256 private constant CLOSE_FACTOR_HF_THRESHOLD = 95e16;
    uint24 private constant FEE_DENOMINATOR = 1e6; // To represent fee in parts per million for precision
    uint24 private constant FEE_PERCENTAGE = 3000; // Fee percentage in basis points, example: 0.3%
    uint24 private constant MAX_SLIPPAGE_TOLERANCE = 10000; // Fee percentage in basis points, example: 0.3%

    address private immutable i_aavePoolAddress;
    address private immutable i_aaveDataProviderAddress;
    address private immutable i_aavePriceOracleAddress;
    address private immutable i_aavePoolAddressProviderAddress;
    address private immutable i_swapRouterAddress;
    address private immutable i_wethAddress; // send profit here at end
    address private immutable i_walletAddress; // send profit here at end

    constructor(
        address aavePoolAddress,
        address aaveDataProviderAddress,
        address aavePriceOracleAddress,
        address aavePoolAddressProviderAddress,
        address swapRouterAddress,
        address wethAddress,
        address walletAddress
    ) {
        i_aavePoolAddress = aavePoolAddress;
        i_aaveDataProviderAddress = aaveDataProviderAddress;
        i_aavePriceOracleAddress = aavePriceOracleAddress;
        i_aavePoolAddressProviderAddress = aavePoolAddressProviderAddress;
        i_swapRouterAddress = swapRouterAddress;
        i_wethAddress = wethAddress;
        i_walletAddress = walletAddress;
    }

    event LiquidateAccount(
        address indexed liquidator,
        address indexed beneficiary,
        address indexed collateralToken,
        uint256 profit,
        address user
    );

    function findAndLiquidateAccount(User[] calldata users) external payable noReentrancy {
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

            // send tip to MINER
            uint256 tip_amount = address(this).balance;
            block.coinbase.transfer(tip_amount);
        } else {
            revert NoUserAccountQualifiedForLiquidation();
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
        IERC20 collateralToken = IERC20(collateralTokenAddress);

        if (collateralTokenAddress != asset) {
            console.log("swapping collateral token debt token to pay off debt");
            swapCollateralForDebtTokenToRepayLoan(collateralTokenAddress, asset, amount + premium);
        }

        console.log("collateral token balance AFTER swap => ", collateralToken.balanceOf(address(this)));
        // TODO - if collateral is not WETH then convert collateral to WETH
        uint256 amountToSwapToETH = collateralToken.balanceOf(address(this));

        if (collateralTokenAddress == asset) amountToSwapToETH -= amount + premium;

        console.log("swapping collateral token for WETH");
        swapCollateralForWETH(collateralTokenAddress, amountToSwapToETH);

        console.log("transfering remaining tokens (above what is owned) to wallet");
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

        // get precise amountIn account for fees and slippage
        uint256 amountIn = getAmountInWithSlippage(collateralTokenAddress, debtTokenAddress, loanRepaymentAmount);

        if (amountIn > amountInMax) {
            // value too big
            amountIn = amountInMax;
        }

        ISwapRouter.ExactOutputSingleParams memory swapParams = ISwapRouter.ExactOutputSingleParams({
            tokenIn: collateralTokenAddress,
            tokenOut: debtTokenAddress,
            fee: uint24(3000),
            recipient: address(this),
            deadline: block.timestamp + 300, // TODO - should i set deadline?
            amountOut: loanRepaymentAmount,
            amountInMaximum: amountIn,
            sqrtPriceLimitX96: 0
        });

        // token swap
        collateralToken.approve(address(swapRouter), amountInMax);
        swapRouter.exactOutputSingle(swapParams);

        // check swap was a successful
        console.log("token swap successful");
        if (debtToken.balanceOf(address(this)) < loanRepaymentAmount) {
            revert InsufficientBalanceToPayLoan();
        }
    }

    function swapCollateralForWETH(address collateralTokenAddress, uint256 amountIn) private {
        IERC20 collateralToken = IERC20(collateralTokenAddress);
        ISwapRouter swapRouter = ISwapRouter(i_swapRouterAddress);

        if (collateralTokenAddress == i_wethAddress) return; // no swap necessary!

        // sanity check , contract should now have a positive balance of collateral token
        if (amountIn == 0) revert NoCollateralToken();

        uint256 amountOutMin = getAmountOutSlippage(collateralTokenAddress, i_wethAddress, amountIn);

        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: collateralTokenAddress,
            tokenOut: i_wethAddress,
            fee: uint24(3000),
            recipient: address(this),
            deadline: block.timestamp + 300, // TODO - should i set deadline?
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        // token swap
        collateralToken.approve(address(swapRouter), amountIn);
        swapRouter.exactInputSingle(swapParams);
    }

    function liquidateAccount(AccountToLiquidation memory account) private {
        IPool aavePool = IPool(i_aavePoolAddress);
        IERC20 debtToken = IERC20(account.user.debtToken);

        // if account fitting all criteria found , lets liquidate
        if (debtToken.balanceOf(address(this)) >= account.debtToCover) {
            // submit account for liquidation,
            debtToken.approve(address(aavePool), account.debtToCover * 3); // this cover loan repayment with aave too
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
        IERC20 wethToken = IERC20(i_wethAddress);

        uint256 debtAmount = debtToken.balanceOf(address(this));
        uint256 wethAmount = wethToken.balanceOf(address(this));

        if (wethAmount > 0) {
            wethToken.safeTransfer(i_walletAddress, wethAmount);
            console.log("profit taken of amount WETH", wethAmount);
        }

        uint256 collateralAmount = collateralToken.balanceOf(address(this));

        if (collateralAmount > 0 && collateralTokenAddress != debtTokenAddress) {
            collateralToken.safeTransfer(i_walletAddress, collateralAmount);
            console.log("profit taken of amount (collateral Token)", collateralAmount);
        }

        if (debtAmount > repaymentAmount) {
            uint256 remainingBalance = debtAmount - repaymentAmount;
            console.log("remaining balance", remainingBalance);
            debtToken.safeTransfer(i_walletAddress, remainingBalance);

            uint256 debtBalance = debtToken.balanceOf(address(this));
            if (debtBalance < repaymentAmount) revert InsufficientBalanceToPayLoan();

            console.log("profit taken of amount (outstading debt token)", remainingBalance);
        }
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

        uint256 liquidationThreshold = 1e18; // 0.5
        if (healthFactor < CLOSE_FACTOR_HF_THRESHOLD) liquidationThreshold = 5e17;

        uint256 liquidationBonus = getAaveLiquidationBonus(user.collateralToken);
        uint256 debtPrice = priceOracle.getAssetPrice(user.debtToken);

        // uint256 totalDebt = stableDebt + variableDebt;
        uint256 debtDecimalFactor = getTokenDecimalFactor(user.debtToken);

        console.log("debt token => ", user.debtToken);
        console.log("collateral token => ", user.collateralToken);
        console.log("total debt =>", totalDebt);
        console.log("debt token Price =>", debtPrice);

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

            return (profitUsd, debtToCover);
        } else {
            return (0, 0);
        }
    }

    function getAmountInWithSlippage(address tokenIn, address tokenOut, uint256 amountOut)
        private
        view
        returns (uint256)
    {
        IPriceOracle priceOracle = IPriceOracle(i_aavePriceOracleAddress);

        // Calculate the fee to apply on the amount out
        uint256 inTokenPrice = priceOracle.getAssetPrice(tokenIn);
        uint256 outTokenPrice = priceOracle.getAssetPrice(tokenOut);

        uint256 inTokenDecimalFactor = getTokenDecimalFactor(tokenIn);
        uint256 outTokenDecimalFactor = getTokenDecimalFactor(tokenOut);

        // exact amount in required including fee
        uint256 _amountIn = (amountOut * outTokenPrice) / inTokenPrice;
        _amountIn = (_amountIn * inTokenDecimalFactor) / outTokenDecimalFactor;

        // adding 1% slippage
        uint256 splippageTolerance = (MAX_SLIPPAGE_TOLERANCE * _amountIn) / FEE_DENOMINATOR;
        _amountIn = _amountIn + splippageTolerance;

        return _amountIn;
    }

    function getAmountOutSlippage(address tokenIn, address tokenOut, uint256 amountIn) private view returns (uint256) {
        IPriceOracle priceOracle = IPriceOracle(i_aavePriceOracleAddress);

        // Calculate the fee to apply on the amount out
        uint256 inTokenPrice = priceOracle.getAssetPrice(tokenIn);
        uint256 outTokenPrice = priceOracle.getAssetPrice(tokenOut);

        uint256 inTokenDecimalFactor = getTokenDecimalFactor(tokenIn);
        uint256 outTokenDecimalFactor = getTokenDecimalFactor(tokenOut);

        // exact amount in required including fee
        uint256 _amountOut = (amountIn * inTokenPrice) / outTokenPrice;
        _amountOut = (_amountOut * outTokenDecimalFactor) / inTokenDecimalFactor;

        // adding 1% slippage
        uint256 splippageTolerance = (MAX_SLIPPAGE_TOLERANCE * _amountOut) / FEE_DENOMINATOR;
        _amountOut = _amountOut - splippageTolerance;

        return _amountOut;
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

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(i_aavePoolAddressProviderAddress);
    }

    function POOL() external view returns (IPool) {
        return IPool(i_aavePoolAddress);
    }
}
