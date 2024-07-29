// 1. Deploy mock when we are on local anvil chain
// 2. Keep Track of contract address across different chains
// Sepolia ETH/USD
// Mainnet ETH/USD

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import "lib/aave-v3-core/contracts/mocks/helpers/MockPool.sol";
import "lib/aave-v3-core/contracts/mocks/oracle/PriceOracle.sol";
import "test/mocks/MockPoolDataProvider.sol";
import "lib/aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address poolAddress;
        address dataProviderAddress;
        address priceOracleAddress;
        address poolAddressesProvider;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            poolAddress: 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951,
            dataProviderAddress: 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31,
            priceOracleAddress: 0x2da88497588bf89281816106C7259e31AF45a663,
            poolAddressesProvider: 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A
        });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            poolAddress: 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2,
            dataProviderAddress: 0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3,
            priceOracleAddress: 0x54586bE62E3c3580375aE3723C145253060Ca0C2,
            poolAddressesProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.poolAddress != address(0)) return activeNetworkConfig;

        string memory marketId = "anvil";

        vm.startBroadcast();
        PoolAddressesProvider provider = new PoolAddressesProvider(marketId, msg.sender);
        MockPoolInherited mockPool = new MockPoolInherited(provider);
        MockPoolDataProvider mockPoolDataProvider = new MockPoolDataProvider();
        PriceOracle priceOracle = new PriceOracle();
        vm.stopBroadcast();

        return NetworkConfig({
            poolAddress: address(mockPool),
            dataProviderAddress: address(mockPoolDataProvider),
            priceOracleAddress: address(priceOracle),
            poolAddressesProvider: address(provider)
        });
    }
}
