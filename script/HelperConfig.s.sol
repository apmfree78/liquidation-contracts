// 1. Deploy mock when we are on local anvil chain
// 2. Keep Track of contract address across different chains
// Sepolia ETH/USD
// Mainnet ETH/USD

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import "test/mocks/MockPool.sol";
import "lib/aave-v3-core/contracts/mocks/oracle/PriceOracle.sol";
import "test/mocks/MockPoolDataProvider.sol";
import "test/mocks/MockSwapRouter.sol";
import "lib/aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";
import {AaveV3Ethereum} from "constants/AaveV3Ethereum.sol";
import {AaveV3Sepolia} from "constants/AaveV3Sepolia.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address poolAddress;
        address dataProviderAddress;
        address priceOracleAddress;
        address poolAddressesProvider;
        address swapRouterAddress;
        address walletAddress;
    }

    // metamask wallet address
    address private constant wallet = 0xD55b88CbedD80c73a5bdcE00A15DdD5E05330daC;

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
            poolAddress: address(AaveV3Sepolia.POOL),
            dataProviderAddress: address(AaveV3Sepolia.AAVE_PROTOCOL_DATA_PROVIDER),
            priceOracleAddress: address(AaveV3Sepolia.ORACLE),
            poolAddressesProvider: address(AaveV3Sepolia.POOL_ADDRESSES_PROVIDER),
            swapRouterAddress: 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E,
            walletAddress: wallet
        });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            poolAddress: address(AaveV3Ethereum.POOL),
            dataProviderAddress: address(AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER),
            priceOracleAddress: address(AaveV3Ethereum.ORACLE),
            poolAddressesProvider: address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
            swapRouterAddress: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45,
            walletAddress: wallet
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.poolAddress != address(0)) return activeNetworkConfig;

        string memory marketId = "anvil";

        vm.startBroadcast();
        PoolAddressesProvider provider = new PoolAddressesProvider(marketId, msg.sender);
        MockPoolDataProvider mockPoolDataProvider = new MockPoolDataProvider();
        PriceOracle priceOracle = new PriceOracle();
        MockSwapRouter mockSwapRouter = new MockSwapRouter(address(priceOracle));
        MockPool mockPool = new MockPool(address(priceOracle));
        vm.stopBroadcast();

        return NetworkConfig({
            poolAddress: address(mockPool),
            dataProviderAddress: address(mockPoolDataProvider),
            priceOracleAddress: address(priceOracle),
            poolAddressesProvider: address(provider),
            swapRouterAddress: address(mockSwapRouter),
            walletAddress: wallet
        });
    }
}
