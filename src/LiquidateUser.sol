// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import "lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";

contract LiquidateUser {
    struct Users {
        address id;
        address debtToken;
        address collateralToken;
    }

    uint256 private constant LIQUIDATION_THRESHOLD = 1e18;
    address private immutable i_aavePoolAddress;
    address private immutable i_aaveDataProviderAddress;
    address private immutable i_aavePriceOracleAddress;

    constructor(address aavePoolAddress, address aaveDataProviderAddress, address aavePriceOracleAddress) {
        i_aavePoolAddress = aavePoolAddress;
        i_aaveDataProviderAddress = aaveDataProviderAddress;
        i_aavePriceOracleAddress = aavePriceOracleAddress;
    }

    function liquidateUserAccounts(Users[] calldata users) external {
        uint256 userCount = users.length;
        IPool aavePool = IPool(i_aavePoolAddress);

        for (uint256 i = 0; i < userCount; i++) {
            address id = users[i].id;
            address debtToken = users[i].debtToken;
            address collateralToken = users[i].collateralToken;

            // get health factor
            (,,,,, uint256 healthFactor) = aavePool.getUserAccountData(id);

            if (healthFactor < LIQUIDATION_THRESHOLD) {
                // TODO - checkout profitability
                // TODO - check if user has funds to liquidate OR get flash loan to cover it
                // submit account for liquidation,
                aavePool.liquidationCall(collateralToken, debtToken, id, type(uint256).max, false);
            }
        }
    }
}
