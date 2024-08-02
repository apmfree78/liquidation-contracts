// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "lib/aave-v3-core/contracts/mocks/oracle/PriceOracle.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";

interface IFlashLoanReceiver {
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bool);
}

contract MockPool {
    error UserDoesNotOwnToken();
    error UserDoesNotExist();
    error HealthFactorNotQualifiedForLiquidation();
    error InsufficienFundsToPayLoanPlusPremium();
    error LoanCallbackFailed();

    struct Token {
        address tokenAddress;
        uint256 debt;
        bool useAsCollateralEnabled;
        uint256 aTokenBalance;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct UserData {
        address id;
        bool exists;
        Token[] tokens;
    }

    uint256 private constant LIQUIDATION_THRESHOLD = 7000; // set fixed 70% liquidation threshold for testing
    uint256 private constant LIQUIDATION_BONUS = 11000; // set fixed 10% liquidation bonus for testing
    uint256 private constant BPS_FACTOR = 1e4; // set fixed 10% liquidation bonus for testing
    uint256 private constant FLASHLOAN_FEE = 5; // 0.05%
    uint256 private constant STANDARD_SCALE = 1 ether;
    uint256 private constant HEALTH_FACTOR_THRESHOLD = 1e18;
    uint256 private constant MIN_HEALTH_SCORE_THRESHOLD = 1e17;
    uint256 private constant CLOSE_FACTOR_HF_THRESHOLD = 95e16;
    address private immutable i_priceOracle;

    mapping(address => UserData) Users;

    event Supply(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );
    event Borrow(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 indexed referralCode
    );
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    constructor(address priceOracleAddress) {
        i_priceOracle = priceOracleAddress;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        UserData storage user = Users[onBehalfOf];
        if (!user.exists) {
            user.id = onBehalfOf;
            user.exists = true;
        }

        int256 tokenIndex = findTokenIndex(user, asset);

        if (tokenIndex == -1) {
            Token memory token = Token({
                tokenAddress: asset,
                debt: 0,
                useAsCollateralEnabled: true, // in reality need to enable , this is for testing purpose
                aTokenBalance: amount,
                liquidationThreshold: LIQUIDATION_THRESHOLD,
                liquidationBonus: LIQUIDATION_BONUS
            });

            user.tokens.push(token);
        } else {
            user.tokens[uint256(tokenIndex)].aTokenBalance += amount;
        }
        emit Supply(asset, onBehalfOf, onBehalfOf, amount, referralCode);
    }

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external
    {
        UserData storage user = Users[onBehalfOf];
        if (!user.exists) revert UserDoesNotExist();

        int256 tokenIndex = findTokenIndex(user, asset);

        if (tokenIndex == -1) {
            Token memory token = Token({
                tokenAddress: asset,
                debt: amount,
                useAsCollateralEnabled: true, // in reality need to enable , this is for testing purpose
                aTokenBalance: 0,
                liquidationThreshold: LIQUIDATION_THRESHOLD,
                liquidationBonus: LIQUIDATION_BONUS
            });

            user.tokens.push(token);
        } else {
            user.tokens[uint256(tokenIndex)].debt += amount;
        }
        emit Borrow(asset, onBehalfOf, onBehalfOf, amount, referralCode);
    }

    function findTokenIndex(UserData storage user, address asset) internal view returns (int256) {
        for (uint256 i = 0; i < user.tokens.length; i++) {
            if (user.tokens[i].tokenAddress == asset) {
                return int256(i); // Return index as int256
            }
        }
        return -1; // Return -1 if not found
    }

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external {
        uint256 premium = amount * FLASHLOAN_FEE / BPS_FACTOR;

        IERC20(asset).transfer(receiverAddress, amount);

        bool success =
            IFlashLoanReceiver(receiverAddress).executeOperation(asset, amount, premium, receiverAddress, params);

        if (!success) revert LoanCallbackFailed();

        // make sure reciever has balance to pay loan
        if (IERC20(asset).balanceOf(receiverAddress) < amount + premium) {
            revert InsufficienFundsToPayLoanPlusPremium();
        }
        IERC20(asset).transferFrom(receiverAddress, address(this), amount + premium);
        emit FlashLoan(receiverAddress, msg.sender, asset, amount, premium, referralCode);
    }

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external {
        UserData storage _user = Users[user];
        if (!_user.exists) revert UserDoesNotExist();

        int256 debtTokenIndex = findTokenIndex(_user, debtAsset);
        int256 collateralTokenIndex = findTokenIndex(_user, collateralAsset);

        if (debtTokenIndex == -1 || collateralTokenIndex == -1) revert UserDoesNotOwnToken();

        // TODO make function to get health factor
        uint256 healthFactor = getHealthFactor(_user.id);

        if (healthFactor > MIN_HEALTH_SCORE_THRESHOLD && healthFactor < HEALTH_FACTOR_THRESHOLD) {
            // calculate Max collateral that can be liquidated then update user

            uint256 debtPrice = PriceOracle(i_priceOracle).getAssetPrice(debtAsset);
            uint256 collateralPrice = PriceOracle(i_priceOracle).getAssetPrice(collateralAsset);

            uint256 _amount = (debtPrice * debtToCover) / collateralPrice;

            uint256 maxAmountOfCollateralToLiquidate =
                (_amount * _user.tokens[uint256(collateralTokenIndex)].liquidationBonus) / BPS_FACTOR;

            // transfer funds
            IERC20(debtAsset).transferFrom(_user.id, address(this), debtToCover);
            IERC20(collateralAsset).transfer(_user.id, maxAmountOfCollateralToLiquidate);
            emit LiquidationCall(
                collateralAsset,
                debtAsset,
                user,
                debtToCover,
                maxAmountOfCollateralToLiquidate,
                msg.sender,
                receiveAToken
            );
        } else {
            revert HealthFactorNotQualifiedForLiquidation();
        }
    }

    function getHealthFactor(address userId) private view returns (uint256) {
        UserData memory user = Users[userId];
        if (!user.exists) revert UserDoesNotExist();

        uint256 totalDebt = 0;
        uint256 collateralTimesLiquidationFactor = 0;

        for (uint256 i = 0; i < user.tokens.length; i++) {
            // get price of token
            address tokenAddress = user.tokens[i].tokenAddress;
            uint256 decimalFactor = 10 ** IERC20(tokenAddress).decimals();
            uint256 price = PriceOracle(i_priceOracle).getAssetPrice(tokenAddress);

            totalDebt += user.tokens[i].debt * price / decimalFactor;

            if (user.tokens[i].useAsCollateralEnabled) {
                uint256 _amount = (user.tokens[i].aTokenBalance * price) / decimalFactor;
                collateralTimesLiquidationFactor += (_amount * user.tokens[i].liquidationThreshold) / BPS_FACTOR;
            }
        }

        if (totalDebt > 0) {
            return (collateralTimesLiquidationFactor * STANDARD_SCALE) / totalDebt;
        } else {
            return 0;
        }
    }
}
