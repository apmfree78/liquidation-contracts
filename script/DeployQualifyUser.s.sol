// 1. Deploy mock when we are on local anvil chain
// 2. Keep Track of contract address across different chains
// Sepolia ETH/USD
// Mainnet ETH/USD

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {QualifyUser} from "src/QualifyUser.sol";

contract DeployQualifyUser is Script {
    function run() external returns (QualifyUser, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // (address poolAddress, address dataProviderAddress, address priceOracleAddress,,,,) =
        //     helperConfig.activeNetworkConfig();
        // HelperConfig.NetworkConfig memory config = helperConfig.activeNetworkConfig();
        // Assign struct fields to local variables
        address poolAddress = helperConfig.poolAddress;
        address dataProviderAddress = helperConfig.dataProviderAddress;
        address priceOracleAddress = helperConfig.priceOracleAddress;
        address[] memory pricedInEth = helperConfig.pricedInEth;

        vm.startBroadcast();
        QualifyUser qualifyUser = new QualifyUser(poolAddress, dataProviderAddress, priceOracleAddress);
        vm.stopBroadcast();

        return (qualifyUser, helperConfig);
    }
}
