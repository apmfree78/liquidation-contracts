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
import {WETH9Mocked} from "lib/aave-v3-core/contracts/mocks/tokens/WETH9Mocked.sol";
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
        address payable wethAddress;
        address walletAddress;
        address[] pricedInEth;
    }

    // chainlink oracles priced in eth ==> "wstETH", "rETH", "cbETH", "LDO", "weETH", "ETHx"
    address private constant WSTETH_MAINNET = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address private constant RETH_MAINNET = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address private constant CBETH_MAINNET = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address private constant LDO_MAINNET = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
    address private constant WEETH_MAINNET = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address private constant ETHX_MAINNET = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;

    // metamask wallet address
    address private constant wallet = 0xD55b88CbedD80c73a5bdcE00A15DdD5E05330daC;

    address[] private pricedInEthAddresses;

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

    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        // chainlink oracles priced in eth ==> "wstETH", "rETH", "cbETH", "LDO", "weETH", "ETHx"

        setPricedInEthValues();
        return NetworkConfig({
            poolAddress: address(AaveV3Sepolia.POOL),
            dataProviderAddress: address(AaveV3Sepolia.AAVE_PROTOCOL_DATA_PROVIDER),
            priceOracleAddress: address(AaveV3Sepolia.ORACLE),
            poolAddressesProvider: address(AaveV3Sepolia.POOL_ADDRESSES_PROVIDER),
            swapRouterAddress: 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E,
            wethAddress: payable(0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c),
            walletAddress: wallet,
            pricedInEth: pricedInEthAddresses
        });
    }

    function getMainnetConfig() public returns (NetworkConfig memory) {
        setPricedInEthValues();
        return NetworkConfig({
            poolAddress: address(AaveV3Ethereum.POOL),
            dataProviderAddress: address(AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER),
            priceOracleAddress: address(AaveV3Ethereum.ORACLE),
            poolAddressesProvider: address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
            swapRouterAddress: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45,
            wethAddress: payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
            walletAddress: wallet,
            pricedInEth: pricedInEthAddresses
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.poolAddress != address(0)) return activeNetworkConfig;

        setPricedInEthValues();
        string memory marketId = "anvil";

        vm.startBroadcast();
        PoolAddressesProvider provider = new PoolAddressesProvider(marketId, msg.sender);
        MockPoolDataProvider mockPoolDataProvider = new MockPoolDataProvider();
        PriceOracle priceOracle = new PriceOracle();
        MockSwapRouter mockSwapRouter = new MockSwapRouter(address(priceOracle));
        WETH9Mocked weth = new WETH9Mocked();
        MockPool mockPool = new MockPool(address(priceOracle));
        vm.stopBroadcast();

        return NetworkConfig({
            poolAddress: address(mockPool),
            dataProviderAddress: address(mockPoolDataProvider),
            priceOracleAddress: address(priceOracle),
            poolAddressesProvider: address(provider),
            swapRouterAddress: address(mockSwapRouter),
            wethAddress: payable(address(weth)),
            walletAddress: wallet,
            pricedInEth: pricedInEthAddresses
        });
    }

    function setPricedInEthValues() private {
        delete pricedInEthAddresses;
        pricedInEthAddresses.push(WSTETH_MAINNET);
        pricedInEthAddresses.push(RETH_MAINNET);
        pricedInEthAddresses.push(CBETH_MAINNET);
        pricedInEthAddresses.push(LDO_MAINNET);
        pricedInEthAddresses.push(WEETH_MAINNET);
        pricedInEthAddresses.push(ETHX_MAINNET);
    }
}
