// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import "lib/aave-v3-core/contracts/interfaces/IPriceOracle.sol";
import "lib/aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";

library AaveV3Ethereum {
    // https://etherscan.io/address/0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);

    // https://etherscan.io/address/0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2
    IPool internal constant POOL = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    // https://etherscan.io/address/0x34339f94350EC5274ea44d0C37DAe9e968c44081
    address internal constant POOL_IMPL = 0x34339f94350EC5274ea44d0C37DAe9e968c44081;

    // https://etherscan.io/address/0x64b761D848206f447Fe2dd461b0c635Ec39EbB27
    // IPoolConfigurator internal constant POOL_CONFIGURATOR =
    //     IPoolConfigurator(0x64b761D848206f447Fe2dd461b0c635Ec39EbB27);

    // https://etherscan.io/address/0x419226e0Ad27f3B2019123f7246a364622b018e5
    address internal constant POOL_CONFIGURATOR_IMPL = 0x419226e0Ad27f3B2019123f7246a364622b018e5;

    // https://etherscan.io/address/0x54586bE62E3c3580375aE3723C145253060Ca0C2
    IPriceOracle internal constant ORACLE = IPriceOracle(0x54586bE62E3c3580375aE3723C145253060Ca0C2);

    // https://etherscan.io/address/0x20e074F62EcBD8BC5E38211adCb6103006113A22
    IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IPoolDataProvider(0x41393e5e337606dc3821075Af65AeE84D7688CBD);

    // https://etherscan.io/address/0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0
    // IACLManager internal constant ACL_MANAGER = IACLManager(0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0);

    // https://etherscan.io/address/0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A
    address internal constant ACL_ADMIN = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;

    // https://etherscan.io/address/0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
    // ICollector internal constant COLLECTOR = ICollector(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c);

    // https://etherscan.io/address/0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb
    address internal constant DEFAULT_INCENTIVES_CONTROLLER = 0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb;

    // https://etherscan.io/address/0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d
    address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d;

    // https://etherscan.io/address/0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6
    address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 = 0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6;

    // https://etherscan.io/address/0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57
    address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 = 0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57;

    // https://etherscan.io/address/0x223d844fc4B006D67c0cDbd39371A9F73f69d974
    address internal constant EMISSION_MANAGER = 0x223d844fc4B006D67c0cDbd39371A9F73f69d974;

    // https://etherscan.io/address/0x82dcCF206Ae2Ab46E2099e663F70DeE77caE7778
    address internal constant CAPS_PLUS_RISK_STEWARD = 0x82dcCF206Ae2Ab46E2099e663F70DeE77caE7778;

    // https://etherscan.io/address/0x2eE68ACb6A1319de1b49DC139894644E424fefD6
    address internal constant FREEZING_STEWARD = 0x2eE68ACb6A1319de1b49DC139894644E424fefD6;

    // https://etherscan.io/address/0x8761e0370f94f68Db8EaA731f4fC581f6AD0Bd68
    address internal constant DEBT_SWAP_ADAPTER = 0x8761e0370f94f68Db8EaA731f4fC581f6AD0Bd68;

    // https://etherscan.io/address/0x21714092D90c7265F52fdfDae068EC11a23C6248
    address internal constant DELEGATION_AWARE_A_TOKEN_IMPL_REV_1 = 0x21714092D90c7265F52fdfDae068EC11a23C6248;

    // https://etherscan.io/address/0x8689b8aDD004A9fD2320031b7d3f5aF1f7F41e17
    address internal constant CONFIG_ENGINE = 0x8689b8aDD004A9fD2320031b7d3f5aF1f7F41e17;

    // https://etherscan.io/address/0xbaA999AC55EAce41CcAE355c77809e68Bb345170
    address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY = 0xbaA999AC55EAce41CcAE355c77809e68Bb345170;

    // https://etherscan.io/address/0x02e7B8511831B1b02d9018215a0f8f500Ea5c6B3
    address internal constant REPAY_WITH_COLLATERAL_ADAPTER = 0x02e7B8511831B1b02d9018215a0f8f500Ea5c6B3;

    // https://etherscan.io/address/0x411D79b8cC43384FDE66CaBf9b6a17180c842511
    address internal constant STATIC_A_TOKEN_FACTORY = 0x411D79b8cC43384FDE66CaBf9b6a17180c842511;

    // https://etherscan.io/address/0xADC0A53095A0af87F3aa29FE0715B5c28016364e
    address internal constant SWAP_COLLATERAL_ADAPTER = 0xADC0A53095A0af87F3aa29FE0715B5c28016364e;

    // https://etherscan.io/address/0x379c1EDD1A41218bdbFf960a9d5AD2818Bf61aE8
    address internal constant UI_GHO_DATA_PROVIDER = 0x379c1EDD1A41218bdbFf960a9d5AD2818Bf61aE8;

    // https://etherscan.io/address/0x162A7AC02f547ad796CA549f757e2b8d1D9b10a6
    address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x162A7AC02f547ad796CA549f757e2b8d1D9b10a6;

    // https://etherscan.io/address/0x5c5228aC8BC1528482514aF3e27E692495148717
    address internal constant UI_POOL_DATA_PROVIDER = 0x5c5228aC8BC1528482514aF3e27E692495148717;

    // https://etherscan.io/address/0xC7be5307ba715ce89b152f3Df0658295b3dbA8E2
    address internal constant WALLET_BALANCE_PROVIDER = 0xC7be5307ba715ce89b152f3Df0658295b3dbA8E2;

    // https://etherscan.io/address/0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9
    address internal constant WETH_GATEWAY = 0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9;

    // https://etherscan.io/address/0x78F8Bd884C3D738B74B420540659c82f392820e0
    address internal constant WITHDRAW_SWAP_ADAPTER = 0x78F8Bd884C3D738B74B420540659c82f392820e0;

    // https://etherscan.io/address/0xE28E2c8d240dd5eBd0adcab86fbD79df7a052034
    address internal constant SAVINGS_DAI_TOKEN_WRAPPER = 0xE28E2c8d240dd5eBd0adcab86fbD79df7a052034;
}

library AaveV3EthereumAssets {
    // https://etherscan.io/address/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address internal constant WETH_UNDERLYING = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint8 internal constant WETH_DECIMALS = 18;

    // https://etherscan.io/address/0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8
    address internal constant WETH_A_TOKEN = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    // https://etherscan.io/address/0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE
    address internal constant WETH_V_TOKEN = 0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;

    // https://etherscan.io/address/0x102633152313C81cD80419b6EcF66d14Ad68949A
    address internal constant WETH_S_TOKEN = 0x102633152313C81cD80419b6EcF66d14Ad68949A;

    // https://etherscan.io/address/0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    address internal constant WETH_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant WETH_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x252231882FB38481497f3C767469106297c8d93b
    address internal constant WETH_STATA_TOKEN = 0x252231882FB38481497f3C767469106297c8d93b;

    // https://etherscan.io/address/0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
    address internal constant wstETH_UNDERLYING = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    uint8 internal constant wstETH_DECIMALS = 18;

    // https://etherscan.io/address/0x0B925eD163218f6662a35e0f0371Ac234f9E9371
    address internal constant wstETH_A_TOKEN = 0x0B925eD163218f6662a35e0f0371Ac234f9E9371;

    // https://etherscan.io/address/0xC96113eED8cAB59cD8A66813bCB0cEb29F06D2e4
    address internal constant wstETH_V_TOKEN = 0xC96113eED8cAB59cD8A66813bCB0cEb29F06D2e4;

    // https://etherscan.io/address/0x39739943199c0fBFe9E5f1B5B160cd73a64CB85D
    address internal constant wstETH_S_TOKEN = 0x39739943199c0fBFe9E5f1B5B160cd73a64CB85D;

    // https://etherscan.io/address/0xB4aB0c94159bc2d8C133946E7241368fc2F2a010
    address internal constant wstETH_ORACLE = 0xB4aB0c94159bc2d8C133946E7241368fc2F2a010;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant wstETH_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x322AA5F5Be95644d6c36544B6c5061F072D16DF5
    address internal constant wstETH_STATA_TOKEN = 0x322AA5F5Be95644d6c36544B6c5061F072D16DF5;

    // https://etherscan.io/address/0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    address internal constant WBTC_UNDERLYING = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    uint8 internal constant WBTC_DECIMALS = 8;

    // https://etherscan.io/address/0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8
    address internal constant WBTC_A_TOKEN = 0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8;

    // https://etherscan.io/address/0x40aAbEf1aa8f0eEc637E0E7d92fbfFB2F26A8b7B
    address internal constant WBTC_V_TOKEN = 0x40aAbEf1aa8f0eEc637E0E7d92fbfFB2F26A8b7B;

    // https://etherscan.io/address/0xA1773F1ccF6DB192Ad8FE826D15fe1d328B03284
    address internal constant WBTC_S_TOKEN = 0xA1773F1ccF6DB192Ad8FE826D15fe1d328B03284;

    // https://etherscan.io/address/0x230E0321Cf38F09e247e50Afc7801EA2351fe56F
    address internal constant WBTC_ORACLE = 0x230E0321Cf38F09e247e50Afc7801EA2351fe56F;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant WBTC_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address internal constant USDC_UNDERLYING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint8 internal constant USDC_DECIMALS = 6;

    // https://etherscan.io/address/0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c
    address internal constant USDC_A_TOKEN = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;

    // https://etherscan.io/address/0x72E95b8931767C79bA4EeE721354d6E99a61D004
    address internal constant USDC_V_TOKEN = 0x72E95b8931767C79bA4EeE721354d6E99a61D004;

    // https://etherscan.io/address/0xB0fe3D292f4bd50De902Ba5bDF120Ad66E9d7a39
    address internal constant USDC_S_TOKEN = 0xB0fe3D292f4bd50De902Ba5bDF120Ad66E9d7a39;

    // https://etherscan.io/address/0x736bF902680e68989886e9807CD7Db4B3E015d3C
    address internal constant USDC_ORACLE = 0x736bF902680e68989886e9807CD7Db4B3E015d3C;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant USDC_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x73edDFa87C71ADdC275c2b9890f5c3a8480bC9E6
    address internal constant USDC_STATA_TOKEN = 0x73edDFa87C71ADdC275c2b9890f5c3a8480bC9E6;

    // https://etherscan.io/address/0x6B175474E89094C44Da98b954EedeAC495271d0F
    address internal constant DAI_UNDERLYING = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    uint8 internal constant DAI_DECIMALS = 18;

    // https://etherscan.io/address/0x018008bfb33d285247A21d44E50697654f754e63
    address internal constant DAI_A_TOKEN = 0x018008bfb33d285247A21d44E50697654f754e63;

    // https://etherscan.io/address/0xcF8d0c70c850859266f5C338b38F9D663181C314
    address internal constant DAI_V_TOKEN = 0xcF8d0c70c850859266f5C338b38F9D663181C314;

    // https://etherscan.io/address/0x413AdaC9E2Ef8683ADf5DDAEce8f19613d60D1bb
    address internal constant DAI_S_TOKEN = 0x413AdaC9E2Ef8683ADf5DDAEce8f19613d60D1bb;

    // https://etherscan.io/address/0xaEb897E1Dc6BbdceD3B9D551C71a8cf172F27AC4
    address internal constant DAI_ORACLE = 0xaEb897E1Dc6BbdceD3B9D551C71a8cf172F27AC4;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant DAI_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xaf270C38fF895EA3f95Ed488CEACe2386F038249
    address internal constant DAI_STATA_TOKEN = 0xaf270C38fF895EA3f95Ed488CEACe2386F038249;

    // https://etherscan.io/address/0x514910771AF9Ca656af840dff83E8264EcF986CA
    address internal constant LINK_UNDERLYING = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    uint8 internal constant LINK_DECIMALS = 18;

    // https://etherscan.io/address/0x5E8C8A7243651DB1384C0dDfDbE39761E8e7E51a
    address internal constant LINK_A_TOKEN = 0x5E8C8A7243651DB1384C0dDfDbE39761E8e7E51a;

    // https://etherscan.io/address/0x4228F8895C7dDA20227F6a5c6751b8Ebf19a6ba8
    address internal constant LINK_V_TOKEN = 0x4228F8895C7dDA20227F6a5c6751b8Ebf19a6ba8;

    // https://etherscan.io/address/0x63B1129ca97D2b9F97f45670787Ac12a9dF1110a
    address internal constant LINK_S_TOKEN = 0x63B1129ca97D2b9F97f45670787Ac12a9dF1110a;

    // https://etherscan.io/address/0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c
    address internal constant LINK_ORACLE = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant LINK_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
    address internal constant AAVE_UNDERLYING = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    uint8 internal constant AAVE_DECIMALS = 18;

    // https://etherscan.io/address/0xA700b4eB416Be35b2911fd5Dee80678ff64fF6C9
    address internal constant AAVE_A_TOKEN = 0xA700b4eB416Be35b2911fd5Dee80678ff64fF6C9;

    // https://etherscan.io/address/0xBae535520Abd9f8C85E58929e0006A2c8B372F74
    address internal constant AAVE_V_TOKEN = 0xBae535520Abd9f8C85E58929e0006A2c8B372F74;

    // https://etherscan.io/address/0x268497bF083388B1504270d0E717222d3A87D6F2
    address internal constant AAVE_S_TOKEN = 0x268497bF083388B1504270d0E717222d3A87D6F2;

    // https://etherscan.io/address/0x547a514d5e3769680Ce22B2361c10Ea13619e8a9
    address internal constant AAVE_ORACLE = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant AAVE_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xBe9895146f7AF43049ca1c1AE358B0541Ea49704
    address internal constant cbETH_UNDERLYING = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;

    uint8 internal constant cbETH_DECIMALS = 18;

    // https://etherscan.io/address/0x977b6fc5dE62598B08C85AC8Cf2b745874E8b78c
    address internal constant cbETH_A_TOKEN = 0x977b6fc5dE62598B08C85AC8Cf2b745874E8b78c;

    // https://etherscan.io/address/0x0c91bcA95b5FE69164cE583A2ec9429A569798Ed
    address internal constant cbETH_V_TOKEN = 0x0c91bcA95b5FE69164cE583A2ec9429A569798Ed;

    // https://etherscan.io/address/0x82bE6012cea6D147B968eBAea5ceEcF6A5b4F493
    address internal constant cbETH_S_TOKEN = 0x82bE6012cea6D147B968eBAea5ceEcF6A5b4F493;

    // https://etherscan.io/address/0x6243d2F41b4ec944F731f647589E28d9745a2674
    address internal constant cbETH_ORACLE = 0x6243d2F41b4ec944F731f647589E28d9745a2674;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant cbETH_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xdAC17F958D2ee523a2206206994597C13D831ec7
    address internal constant USDT_UNDERLYING = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint8 internal constant USDT_DECIMALS = 6;

    // https://etherscan.io/address/0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a
    address internal constant USDT_A_TOKEN = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;

    // https://etherscan.io/address/0x6df1C1E379bC5a00a7b4C6e67A203333772f45A8
    address internal constant USDT_V_TOKEN = 0x6df1C1E379bC5a00a7b4C6e67A203333772f45A8;

    // https://etherscan.io/address/0x822Fa72Df1F229C3900f5AD6C3Fa2C424D691622
    address internal constant USDT_S_TOKEN = 0x822Fa72Df1F229C3900f5AD6C3Fa2C424D691622;

    // https://etherscan.io/address/0xC26D4a1c46d884cfF6dE9800B6aE7A8Cf48B4Ff8
    address internal constant USDT_ORACLE = 0xC26D4a1c46d884cfF6dE9800B6aE7A8Cf48B4Ff8;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant USDT_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x862c57d48becB45583AEbA3f489696D22466Ca1b
    address internal constant USDT_STATA_TOKEN = 0x862c57d48becB45583AEbA3f489696D22466Ca1b;

    // https://etherscan.io/address/0xae78736Cd615f374D3085123A210448E74Fc6393
    address internal constant rETH_UNDERLYING = 0xae78736Cd615f374D3085123A210448E74Fc6393;

    uint8 internal constant rETH_DECIMALS = 18;

    // https://etherscan.io/address/0xCc9EE9483f662091a1de4795249E24aC0aC2630f
    address internal constant rETH_A_TOKEN = 0xCc9EE9483f662091a1de4795249E24aC0aC2630f;

    // https://etherscan.io/address/0xae8593DD575FE29A9745056aA91C4b746eee62C8
    address internal constant rETH_V_TOKEN = 0xae8593DD575FE29A9745056aA91C4b746eee62C8;

    // https://etherscan.io/address/0x1d1906f909CAe494c7441604DAfDDDbD0485A925
    address internal constant rETH_S_TOKEN = 0x1d1906f909CAe494c7441604DAfDDDbD0485A925;

    // https://etherscan.io/address/0x5AE8365D0a30D67145f0c55A08760C250559dB64
    address internal constant rETH_ORACLE = 0x5AE8365D0a30D67145f0c55A08760C250559dB64;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant rETH_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x5f98805A4E8be255a32880FDeC7F6728C6568bA0
    address internal constant LUSD_UNDERLYING = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

    uint8 internal constant LUSD_DECIMALS = 18;

    // https://etherscan.io/address/0x3Fe6a295459FAe07DF8A0ceCC36F37160FE86AA9
    address internal constant LUSD_A_TOKEN = 0x3Fe6a295459FAe07DF8A0ceCC36F37160FE86AA9;

    // https://etherscan.io/address/0x33652e48e4B74D18520f11BfE58Edd2ED2cEc5A2
    address internal constant LUSD_V_TOKEN = 0x33652e48e4B74D18520f11BfE58Edd2ED2cEc5A2;

    // https://etherscan.io/address/0x37A6B708FDB1483C231961b9a7F145261E815fc3
    address internal constant LUSD_S_TOKEN = 0x37A6B708FDB1483C231961b9a7F145261E815fc3;

    // https://etherscan.io/address/0x9eCdfaCca946614cc32aF63F3DBe50959244F3af
    address internal constant LUSD_ORACLE = 0x9eCdfaCca946614cc32aF63F3DBe50959244F3af;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant LUSD_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xDBf5E36569798D1E39eE9d7B1c61A7409a74F23A
    address internal constant LUSD_STATA_TOKEN = 0xDBf5E36569798D1E39eE9d7B1c61A7409a74F23A;

    // https://etherscan.io/address/0xD533a949740bb3306d119CC777fa900bA034cd52
    address internal constant CRV_UNDERLYING = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    uint8 internal constant CRV_DECIMALS = 18;

    // https://etherscan.io/address/0x7B95Ec873268a6BFC6427e7a28e396Db9D0ebc65
    address internal constant CRV_A_TOKEN = 0x7B95Ec873268a6BFC6427e7a28e396Db9D0ebc65;

    // https://etherscan.io/address/0x1b7D3F4b3c032a5AE656e30eeA4e8E1Ba376068F
    address internal constant CRV_V_TOKEN = 0x1b7D3F4b3c032a5AE656e30eeA4e8E1Ba376068F;

    // https://etherscan.io/address/0x90D9CD005E553111EB8C9c31Abe9706a186b6048
    address internal constant CRV_S_TOKEN = 0x90D9CD005E553111EB8C9c31Abe9706a186b6048;

    // https://etherscan.io/address/0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f
    address internal constant CRV_ORACLE = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant CRV_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2
    address internal constant MKR_UNDERLYING = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

    uint8 internal constant MKR_DECIMALS = 18;

    // https://etherscan.io/address/0x8A458A9dc9048e005d22849F470891b840296619
    address internal constant MKR_A_TOKEN = 0x8A458A9dc9048e005d22849F470891b840296619;

    // https://etherscan.io/address/0x6Efc73E54E41b27d2134fF9f98F15550f30DF9B1
    address internal constant MKR_V_TOKEN = 0x6Efc73E54E41b27d2134fF9f98F15550f30DF9B1;

    // https://etherscan.io/address/0x0496372BE7e426D28E89DEBF01f19F014d5938bE
    address internal constant MKR_S_TOKEN = 0x0496372BE7e426D28E89DEBF01f19F014d5938bE;

    // https://etherscan.io/address/0xec1D1B3b0443256cc3860e24a46F108e699484Aa
    address internal constant MKR_ORACLE = 0xec1D1B3b0443256cc3860e24a46F108e699484Aa;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant MKR_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
    address internal constant SNX_UNDERLYING = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;

    uint8 internal constant SNX_DECIMALS = 18;

    // https://etherscan.io/address/0xC7B4c17861357B8ABB91F25581E7263E08DCB59c
    address internal constant SNX_A_TOKEN = 0xC7B4c17861357B8ABB91F25581E7263E08DCB59c;

    // https://etherscan.io/address/0x8d0de040e8aAd872eC3c33A3776dE9152D3c34ca
    address internal constant SNX_V_TOKEN = 0x8d0de040e8aAd872eC3c33A3776dE9152D3c34ca;

    // https://etherscan.io/address/0x478E1ec1A2BeEd94c1407c951E4B9e22d53b2501
    address internal constant SNX_S_TOKEN = 0x478E1ec1A2BeEd94c1407c951E4B9e22d53b2501;

    // https://etherscan.io/address/0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699
    address internal constant SNX_ORACLE = 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant SNX_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xba100000625a3754423978a60c9317c58a424e3D
    address internal constant BAL_UNDERLYING = 0xba100000625a3754423978a60c9317c58a424e3D;

    uint8 internal constant BAL_DECIMALS = 18;

    // https://etherscan.io/address/0x2516E7B3F76294e03C42AA4c5b5b4DCE9C436fB8
    address internal constant BAL_A_TOKEN = 0x2516E7B3F76294e03C42AA4c5b5b4DCE9C436fB8;

    // https://etherscan.io/address/0x3D3efceb4Ff0966D34d9545D3A2fa2dcdBf451f2
    address internal constant BAL_V_TOKEN = 0x3D3efceb4Ff0966D34d9545D3A2fa2dcdBf451f2;

    // https://etherscan.io/address/0xB368d45aaAa07ee2c6275Cb320D140b22dE43CDD
    address internal constant BAL_S_TOKEN = 0xB368d45aaAa07ee2c6275Cb320D140b22dE43CDD;

    // https://etherscan.io/address/0xdF2917806E30300537aEB49A7663062F4d1F2b5F
    address internal constant BAL_ORACLE = 0xdF2917806E30300537aEB49A7663062F4d1F2b5F;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant BAL_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
    address internal constant UNI_UNDERLYING = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    uint8 internal constant UNI_DECIMALS = 18;

    // https://etherscan.io/address/0xF6D2224916DDFbbab6e6bd0D1B7034f4Ae0CaB18
    address internal constant UNI_A_TOKEN = 0xF6D2224916DDFbbab6e6bd0D1B7034f4Ae0CaB18;

    // https://etherscan.io/address/0xF64178Ebd2E2719F2B1233bCb5Ef6DB4bCc4d09a
    address internal constant UNI_V_TOKEN = 0xF64178Ebd2E2719F2B1233bCb5Ef6DB4bCc4d09a;

    // https://etherscan.io/address/0x2FEc76324A0463c46f32e74A86D1cf94C02158DC
    address internal constant UNI_S_TOKEN = 0x2FEc76324A0463c46f32e74A86D1cf94C02158DC;

    // https://etherscan.io/address/0x553303d460EE0afB37EdFf9bE42922D8FF63220e
    address internal constant UNI_ORACLE = 0x553303d460EE0afB37EdFf9bE42922D8FF63220e;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant UNI_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32
    address internal constant LDO_UNDERLYING = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    uint8 internal constant LDO_DECIMALS = 18;

    // https://etherscan.io/address/0x9A44fd41566876A39655f74971a3A6eA0a17a454
    address internal constant LDO_A_TOKEN = 0x9A44fd41566876A39655f74971a3A6eA0a17a454;

    // https://etherscan.io/address/0xc30808705C01289A3D306ca9CAB081Ba9114eC82
    address internal constant LDO_V_TOKEN = 0xc30808705C01289A3D306ca9CAB081Ba9114eC82;

    // https://etherscan.io/address/0xa0a5bF5781Aeb548db9d4226363B9e89287C5FD2
    address internal constant LDO_S_TOKEN = 0xa0a5bF5781Aeb548db9d4226363B9e89287C5FD2;

    // https://etherscan.io/address/0xb01e6C9af83879B8e06a092f0DD94309c0D497E4
    address internal constant LDO_ORACLE = 0xb01e6C9af83879B8e06a092f0DD94309c0D497E4;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant LDO_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72
    address internal constant ENS_UNDERLYING = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;

    uint8 internal constant ENS_DECIMALS = 18;

    // https://etherscan.io/address/0x545bD6c032eFdde65A377A6719DEF2796C8E0f2e
    address internal constant ENS_A_TOKEN = 0x545bD6c032eFdde65A377A6719DEF2796C8E0f2e;

    // https://etherscan.io/address/0xd180D7fdD4092f07428eFE801E17BC03576b3192
    address internal constant ENS_V_TOKEN = 0xd180D7fdD4092f07428eFE801E17BC03576b3192;

    // https://etherscan.io/address/0x7617d02E311CdE347A0cb45BB7DF2926BBaf5347
    address internal constant ENS_S_TOKEN = 0x7617d02E311CdE347A0cb45BB7DF2926BBaf5347;

    // https://etherscan.io/address/0x5C00128d4d1c2F4f652C267d7bcdD7aC99C16E16
    address internal constant ENS_ORACLE = 0x5C00128d4d1c2F4f652C267d7bcdD7aC99C16E16;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant ENS_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x111111111117dC0aa78b770fA6A738034120C302
    address internal constant ONE_INCH_UNDERLYING = 0x111111111117dC0aa78b770fA6A738034120C302;

    uint8 internal constant ONE_INCH_DECIMALS = 18;

    // https://etherscan.io/address/0x71Aef7b30728b9BB371578f36c5A1f1502a5723e
    address internal constant ONE_INCH_A_TOKEN = 0x71Aef7b30728b9BB371578f36c5A1f1502a5723e;

    // https://etherscan.io/address/0xA38fCa8c6Bf9BdA52E76EB78f08CaA3BE7c5A970
    address internal constant ONE_INCH_V_TOKEN = 0xA38fCa8c6Bf9BdA52E76EB78f08CaA3BE7c5A970;

    // https://etherscan.io/address/0x4b62bFAff61AB3985798e5202D2d167F567D0BCD
    address internal constant ONE_INCH_S_TOKEN = 0x4b62bFAff61AB3985798e5202D2d167F567D0BCD;

    // https://etherscan.io/address/0xc929ad75B72593967DE83E7F7Cda0493458261D9
    address internal constant ONE_INCH_ORACLE = 0xc929ad75B72593967DE83E7F7Cda0493458261D9;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant ONE_INCH_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x853d955aCEf822Db058eb8505911ED77F175b99e
    address internal constant FRAX_UNDERLYING = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    uint8 internal constant FRAX_DECIMALS = 18;

    // https://etherscan.io/address/0xd4e245848d6E1220DBE62e155d89fa327E43CB06
    address internal constant FRAX_A_TOKEN = 0xd4e245848d6E1220DBE62e155d89fa327E43CB06;

    // https://etherscan.io/address/0x88B8358F5BC87c2D7E116cCA5b65A9eEb2c5EA3F
    address internal constant FRAX_V_TOKEN = 0x88B8358F5BC87c2D7E116cCA5b65A9eEb2c5EA3F;

    // https://etherscan.io/address/0x219640546c0DFDDCb9ab3bcdA89B324e0a376367
    address internal constant FRAX_S_TOKEN = 0x219640546c0DFDDCb9ab3bcdA89B324e0a376367;

    // https://etherscan.io/address/0x45D270263BBee500CF8adcf2AbC0aC227097b036
    address internal constant FRAX_ORACLE = 0x45D270263BBee500CF8adcf2AbC0aC227097b036;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant FRAX_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xEE66abD4D0f9908A48E08AE354B0f425De3e237E
    address internal constant FRAX_STATA_TOKEN = 0xEE66abD4D0f9908A48E08AE354B0f425De3e237E;

    // https://etherscan.io/address/0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f
    address internal constant GHO_UNDERLYING = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;

    uint8 internal constant GHO_DECIMALS = 18;

    // https://etherscan.io/address/0x00907f9921424583e7ffBfEdf84F92B7B2Be4977
    address internal constant GHO_A_TOKEN = 0x00907f9921424583e7ffBfEdf84F92B7B2Be4977;

    // https://etherscan.io/address/0x786dBff3f1292ae8F92ea68Cf93c30b34B1ed04B
    address internal constant GHO_V_TOKEN = 0x786dBff3f1292ae8F92ea68Cf93c30b34B1ed04B;

    // https://etherscan.io/address/0x3f3DF7266dA30102344A813F1a3D07f5F041B5AC
    address internal constant GHO_S_TOKEN = 0x3f3DF7266dA30102344A813F1a3D07f5F041B5AC;

    // https://etherscan.io/address/0xD110cac5d8682A3b045D5524a9903E031d70FCCd
    address internal constant GHO_ORACLE = 0xD110cac5d8682A3b045D5524a9903E031d70FCCd;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant GHO_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xD33526068D116cE69F19A9ee46F0bd304F21A51f
    address internal constant RPL_UNDERLYING = 0xD33526068D116cE69F19A9ee46F0bd304F21A51f;

    uint8 internal constant RPL_DECIMALS = 18;

    // https://etherscan.io/address/0xB76CF92076adBF1D9C39294FA8e7A67579FDe357
    address internal constant RPL_A_TOKEN = 0xB76CF92076adBF1D9C39294FA8e7A67579FDe357;

    // https://etherscan.io/address/0x8988ECA19D502fd8b9CCd03fA3bD20a6f599bc2A
    address internal constant RPL_V_TOKEN = 0x8988ECA19D502fd8b9CCd03fA3bD20a6f599bc2A;

    // https://etherscan.io/address/0x41e330fd8F7eA31E2e8F02cC0C9392D1403597B4
    address internal constant RPL_S_TOKEN = 0x41e330fd8F7eA31E2e8F02cC0C9392D1403597B4;

    // https://etherscan.io/address/0x4E155eD98aFE9034b7A5962f6C84c86d869daA9d
    address internal constant RPL_ORACLE = 0x4E155eD98aFE9034b7A5962f6C84c86d869daA9d;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant RPL_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x83F20F44975D03b1b09e64809B757c47f942BEeA
    address internal constant sDAI_UNDERLYING = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;

    uint8 internal constant sDAI_DECIMALS = 18;

    // https://etherscan.io/address/0x4C612E3B15b96Ff9A6faED838F8d07d479a8dD4c
    address internal constant sDAI_A_TOKEN = 0x4C612E3B15b96Ff9A6faED838F8d07d479a8dD4c;

    // https://etherscan.io/address/0x8Db9D35e117d8b93C6Ca9b644b25BaD5d9908141
    address internal constant sDAI_V_TOKEN = 0x8Db9D35e117d8b93C6Ca9b644b25BaD5d9908141;

    // https://etherscan.io/address/0x48Bc45f084988bC01933EA93EeFfEBC0416534f6
    address internal constant sDAI_S_TOKEN = 0x48Bc45f084988bC01933EA93EeFfEBC0416534f6;

    // https://etherscan.io/address/0x29081f7aB5a644716EfcDC10D5c926c5fEe9F72B
    address internal constant sDAI_ORACLE = 0x29081f7aB5a644716EfcDC10D5c926c5fEe9F72B;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant sDAI_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6
    address internal constant STG_UNDERLYING = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;

    uint8 internal constant STG_DECIMALS = 18;

    // https://etherscan.io/address/0x1bA9843bD4327c6c77011406dE5fA8749F7E3479
    address internal constant STG_A_TOKEN = 0x1bA9843bD4327c6c77011406dE5fA8749F7E3479;

    // https://etherscan.io/address/0x655568bDd6168325EC7e58Bf39b21A856F906Dc2
    address internal constant STG_V_TOKEN = 0x655568bDd6168325EC7e58Bf39b21A856F906Dc2;

    // https://etherscan.io/address/0xc3115D0660b93AeF10F298886ae22E3Dd477E482
    address internal constant STG_S_TOKEN = 0xc3115D0660b93AeF10F298886ae22E3Dd477E482;

    // https://etherscan.io/address/0x7A9f34a0Aa917D438e9b6E630067062B7F8f6f3d
    address internal constant STG_ORACLE = 0x7A9f34a0Aa917D438e9b6E630067062B7F8f6f3d;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant STG_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202
    address internal constant KNC_UNDERLYING = 0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202;

    uint8 internal constant KNC_DECIMALS = 18;

    // https://etherscan.io/address/0x5b502e3796385E1e9755d7043B9C945C3aCCeC9C
    address internal constant KNC_A_TOKEN = 0x5b502e3796385E1e9755d7043B9C945C3aCCeC9C;

    // https://etherscan.io/address/0x253127Ffc04981cEA8932F406710661c2f2c3fD2
    address internal constant KNC_V_TOKEN = 0x253127Ffc04981cEA8932F406710661c2f2c3fD2;

    // https://etherscan.io/address/0xdfEE0C9eA1309cB9611F33972E72a72166fcF548
    address internal constant KNC_S_TOKEN = 0xdfEE0C9eA1309cB9611F33972E72a72166fcF548;

    // https://etherscan.io/address/0xf8fF43E991A81e6eC886a3D281A2C6cC19aE70Fc
    address internal constant KNC_ORACLE = 0xf8fF43E991A81e6eC886a3D281A2C6cC19aE70Fc;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant KNC_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0
    address internal constant FXS_UNDERLYING = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

    uint8 internal constant FXS_DECIMALS = 18;

    // https://etherscan.io/address/0x82F9c5ad306BBa1AD0De49bB5FA6F01bf61085ef
    address internal constant FXS_A_TOKEN = 0x82F9c5ad306BBa1AD0De49bB5FA6F01bf61085ef;

    // https://etherscan.io/address/0x68e9f0aD4e6f8F5DB70F6923d4d6d5b225B83b16
    address internal constant FXS_V_TOKEN = 0x68e9f0aD4e6f8F5DB70F6923d4d6d5b225B83b16;

    // https://etherscan.io/address/0x61dFd349140C239d3B61fEe203Efc811b518a317
    address internal constant FXS_S_TOKEN = 0x61dFd349140C239d3B61fEe203Efc811b518a317;

    // https://etherscan.io/address/0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f
    address internal constant FXS_ORACLE = 0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant FXS_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E
    address internal constant crvUSD_UNDERLYING = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;

    uint8 internal constant crvUSD_DECIMALS = 18;

    // https://etherscan.io/address/0xb82fa9f31612989525992FCfBB09AB22Eff5c85A
    address internal constant crvUSD_A_TOKEN = 0xb82fa9f31612989525992FCfBB09AB22Eff5c85A;

    // https://etherscan.io/address/0x028f7886F3e937f8479efaD64f31B3fE1119857a
    address internal constant crvUSD_V_TOKEN = 0x028f7886F3e937f8479efaD64f31B3fE1119857a;

    // https://etherscan.io/address/0xb55C604075D79486b8A329c396Fc711Be54B5330
    address internal constant crvUSD_S_TOKEN = 0xb55C604075D79486b8A329c396Fc711Be54B5330;

    // https://etherscan.io/address/0x02AeE5b225366302339748951E1a924617b8814F
    address internal constant crvUSD_ORACLE = 0x02AeE5b225366302339748951E1a924617b8814F;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant crvUSD_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x848107491E029AFDe0AC543779c7790382f15929
    address internal constant crvUSD_STATA_TOKEN = 0x848107491E029AFDe0AC543779c7790382f15929;

    // https://etherscan.io/address/0x6c3ea9036406852006290770BEdFcAbA0e23A0e8
    address internal constant PYUSD_UNDERLYING = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8;

    uint8 internal constant PYUSD_DECIMALS = 6;

    // https://etherscan.io/address/0x0C0d01AbF3e6aDfcA0989eBbA9d6e85dD58EaB1E
    address internal constant PYUSD_A_TOKEN = 0x0C0d01AbF3e6aDfcA0989eBbA9d6e85dD58EaB1E;

    // https://etherscan.io/address/0x57B67e4DE077085Fd0AF2174e9c14871BE664546
    address internal constant PYUSD_V_TOKEN = 0x57B67e4DE077085Fd0AF2174e9c14871BE664546;

    // https://etherscan.io/address/0x5B393DB4c72B1Bd82CE2834F6485d61b137Bc7aC
    address internal constant PYUSD_S_TOKEN = 0x5B393DB4c72B1Bd82CE2834F6485d61b137Bc7aC;

    // https://etherscan.io/address/0x150bAe7Ce224555D39AfdBc6Cb4B8204E594E022
    address internal constant PYUSD_ORACLE = 0x150bAe7Ce224555D39AfdBc6Cb4B8204E594E022;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant PYUSD_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x00F2a835758B33f3aC53516Ebd69f3dc77B0D152
    address internal constant PYUSD_STATA_TOKEN = 0x00F2a835758B33f3aC53516Ebd69f3dc77B0D152;

    // https://etherscan.io/address/0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee
    address internal constant weETH_UNDERLYING = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;

    uint8 internal constant weETH_DECIMALS = 18;

    // https://etherscan.io/address/0xBdfa7b7893081B35Fb54027489e2Bc7A38275129
    address internal constant weETH_A_TOKEN = 0xBdfa7b7893081B35Fb54027489e2Bc7A38275129;

    // https://etherscan.io/address/0x77ad9BF13a52517AD698D65913e8D381300c8Bf3
    address internal constant weETH_V_TOKEN = 0x77ad9BF13a52517AD698D65913e8D381300c8Bf3;

    // https://etherscan.io/address/0xBad6eF8e76E26F39e985474aD0974FDcabF85d37
    address internal constant weETH_S_TOKEN = 0xBad6eF8e76E26F39e985474aD0974FDcabF85d37;

    // https://etherscan.io/address/0xf112aF6F0A332B815fbEf3Ff932c057E570b62d3
    address internal constant weETH_ORACLE = 0xf112aF6F0A332B815fbEf3Ff932c057E570b62d3;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant weETH_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xf1C9acDc66974dFB6dEcB12aA385b9cD01190E38
    address internal constant osETH_UNDERLYING = 0xf1C9acDc66974dFB6dEcB12aA385b9cD01190E38;

    uint8 internal constant osETH_DECIMALS = 18;

    // https://etherscan.io/address/0x927709711794F3De5DdBF1D176bEE2D55Ba13c21
    address internal constant osETH_A_TOKEN = 0x927709711794F3De5DdBF1D176bEE2D55Ba13c21;

    // https://etherscan.io/address/0x8838eefF2af391863E1Bb8b1dF563F86743a8470
    address internal constant osETH_V_TOKEN = 0x8838eefF2af391863E1Bb8b1dF563F86743a8470;

    // https://etherscan.io/address/0x48Fa27f511F40d16f9E7C913e9388d52d95bC6d2
    address internal constant osETH_S_TOKEN = 0x48Fa27f511F40d16f9E7C913e9388d52d95bC6d2;

    // https://etherscan.io/address/0x0A2AF898cEc35197e6944D9E0F525C2626393442
    address internal constant osETH_ORACLE = 0x0A2AF898cEc35197e6944D9E0F525C2626393442;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant osETH_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x4c9EDD5852cd905f086C759E8383e09bff1E68B3
    address internal constant USDe_UNDERLYING = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;

    uint8 internal constant USDe_DECIMALS = 18;

    // https://etherscan.io/address/0x4F5923Fc5FD4a93352581b38B7cD26943012DECF
    address internal constant USDe_A_TOKEN = 0x4F5923Fc5FD4a93352581b38B7cD26943012DECF;

    // https://etherscan.io/address/0x015396E1F286289aE23a762088E863b3ec465145
    address internal constant USDe_V_TOKEN = 0x015396E1F286289aE23a762088E863b3ec465145;

    // https://etherscan.io/address/0x43Cc8AD0c223b38D9c04802bB184A2D97e497D38
    address internal constant USDe_S_TOKEN = 0x43Cc8AD0c223b38D9c04802bB184A2D97e497D38;

    // https://etherscan.io/address/0x55B6C4D3E8A27b8A1F5a263321b602e0fdEEcC17
    address internal constant USDe_ORACLE = 0x55B6C4D3E8A27b8A1F5a263321b602e0fdEEcC17;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant USDe_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0xA35b1B31Ce002FBF2058D22F30f95D405200A15b
    address internal constant ETHx_UNDERLYING = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;

    uint8 internal constant ETHx_DECIMALS = 18;

    // https://etherscan.io/address/0x1c0E06a0b1A4c160c17545FF2A951bfcA57C0002
    address internal constant ETHx_A_TOKEN = 0x1c0E06a0b1A4c160c17545FF2A951bfcA57C0002;

    // https://etherscan.io/address/0x08a8Dc81AeA67F84745623aC6c72CDA3967aab8b
    address internal constant ETHx_V_TOKEN = 0x08a8Dc81AeA67F84745623aC6c72CDA3967aab8b;

    // https://etherscan.io/address/0xBDfa7DE5CF7a7DdE4F023Cac842BF520fcF5395C
    address internal constant ETHx_S_TOKEN = 0xBDfa7DE5CF7a7DdE4F023Cac842BF520fcF5395C;

    // https://etherscan.io/address/0xD6270dAabFe4862306190298C2B48fed9e15C847
    address internal constant ETHx_ORACLE = 0xD6270dAabFe4862306190298C2B48fed9e15C847;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant ETHx_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;

    // https://etherscan.io/address/0x9D39A5DE30e57443BfF2A8307A4256c8797A3497
    address internal constant sUSDe_UNDERLYING = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;

    uint8 internal constant sUSDe_DECIMALS = 18;

    // https://etherscan.io/address/0x4579a27aF00A62C0EB156349f31B345c08386419
    address internal constant sUSDe_A_TOKEN = 0x4579a27aF00A62C0EB156349f31B345c08386419;

    // https://etherscan.io/address/0xeFFDE9BFA8EC77c14C364055a200746d6e12BeD6
    address internal constant sUSDe_V_TOKEN = 0xeFFDE9BFA8EC77c14C364055a200746d6e12BeD6;

    // https://etherscan.io/address/0xc9335dE638f4C96a8330b2FFc44353Bab58774e3
    address internal constant sUSDe_S_TOKEN = 0xc9335dE638f4C96a8330b2FFc44353Bab58774e3;

    // https://etherscan.io/address/0xb37aE8aBa6C0C1Bf2c509fc06E11aa4AF29B665A
    address internal constant sUSDe_ORACLE = 0xb37aE8aBa6C0C1Bf2c509fc06E11aa4AF29B665A;

    // https://etherscan.io/address/0x847A3364Cc5fE389283bD821cfC8A477288D9e82
    address internal constant sUSDe_INTEREST_RATE_STRATEGY = 0x847A3364Cc5fE389283bD821cfC8A477288D9e82;
}

library AaveV3EthereumEModes {
    uint8 internal constant NONE = 0;

    uint8 internal constant ETH_CORRELATED = 1;
}

library AaveV3EthereumExternalLibraries {
    // https://etherscan.io/address/0x6DA8d7EF0625e965dafc393793C048096392d4a5
    address internal constant FLASHLOAN_LOGIC = 0x6DA8d7EF0625e965dafc393793C048096392d4a5;

    // https://etherscan.io/address/0x41717de714Db8630F02Dea8f6A39C73A5b5C7df1
    address internal constant BORROW_LOGIC = 0x41717de714Db8630F02Dea8f6A39C73A5b5C7df1;

    // https://etherscan.io/address/0xca2385754bCa5d632F5160B560352aBd12029685
    address internal constant BRIDGE_LOGIC = 0xca2385754bCa5d632F5160B560352aBd12029685;

    // https://etherscan.io/address/0x12959a64470Dd003590Bb1EcFC436dddE7608724
    address internal constant E_MODE_LOGIC = 0x12959a64470Dd003590Bb1EcFC436dddE7608724;

    // https://etherscan.io/address/0x72c272aE914EC11AFe1e74A0016e0A91c1A6014e
    address internal constant LIQUIDATION_LOGIC = 0x72c272aE914EC11AFe1e74A0016e0A91c1A6014e;

    // https://etherscan.io/address/0x55D552EFbc8aEB87AffCEa8630B43a33BA24D975
    address internal constant POOL_LOGIC = 0x55D552EFbc8aEB87AffCEa8630B43a33BA24D975;

    // https://etherscan.io/address/0x9336943ecd91C201D9ED5A21562b34Aef710052f
    address internal constant SUPPLY_LOGIC = 0x9336943ecd91C201D9ED5A21562b34Aef710052f;
}
