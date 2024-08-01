// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFlashLoanReceiver {
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bool);
}

contract MockPool {
    error UserDoesNotOwnToken();
    error UserDoesNotExist();

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

    mapping(address => UserData) Users;

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
    }

    function findTokenIndex(UserData storage user, address asset) internal view returns (int256) {
        for (uint256 i = 0; i < user.tokens.length; i++) {
            if (user.tokens[i].tokenAddress == asset) {
                return int256(i); // Return index as int256
            }
        }
        return -1; // Return -1 if not found
    }

    // TODO - complete below function
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external {
        uint256 premium = amount * FLASHLOAN_FEE / BPS_FACTOR;

        // mint 'amount' of 'asset' for this contract
        // transfer 'amount' to 'receiverAddress'

        IFlashLoanReceiver(receiverAddress).executeOperation(asset, amount, premium, receiverAddress, params);
    }

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external {
        UserData storage user = Users[user];
        if (!user.exists) revert UserDoesNotExist();

        int256 debtTokenIndex = findTokenIndex(user, debtAsset);
        int256 collateralTokenIndex = findTokenIndex(user, collateralAsset);

        if (debtTokenIndex == -1 || collateralTokenIndex == -1) revert UserDoesNotOwnToken();

        // TODO make function to get health factor
        // uint256 healthFactor = getHealthFactor(user);

        uint256 healthFactor = 9e17; // 0.9

        if (healthFactor < HEALTH_FACTOR_THRESHOLD) {
            // calculate debtAmount and Max collateral that can be liquidated then update user
        }
    }
}
