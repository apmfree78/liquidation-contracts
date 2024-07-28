// 1. Deploy mock when we are on local anvil chain
// 2. Keep Track of contract address across different chains
// Sepolia ETH/USD
// Mainnet ETH/USD

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {LiquidateUser} from "src/LiquidateUser.sol";

contract DeployLiquidateUser is Script {
    function run() external returns (LiquidateUser, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address poolAddress, address dataProviderAddress, address priceOracleAddress) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        LiquidateUser liquidateUser = new LiquidateUser(poolAddress, dataProviderAddress, priceOracleAddress);
        vm.stopBroadcast();

        return (liquidateUser, helperConfig);
    }
}
