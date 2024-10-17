// 1. Deploy mock when we are on local anvil chain
// 2. Keep Track of contract address across different chains
// Sepolia ETH/USD
// Mainnet ETH/USD

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {LiquidateQualifiedUser} from "src/LiquidateQualifiedUser.sol";

contract DeployLiquidateQualifiedUser is Script {
    function run() external returns (LiquidateQualifiedUser, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address poolAddress,
            ,
            address priceOracleAddress,
            address poolAddressesProvider,
            address swapRouterAddress,
            address payable wethAddress,
            address walletAddress
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        LiquidateQualifiedUser liquidateUser = new LiquidateQualifiedUser(
            poolAddress, priceOracleAddress, poolAddressesProvider, swapRouterAddress, wethAddress, walletAddress
        );
        vm.stopBroadcast();

        return (liquidateUser, helperConfig);
    }
}
