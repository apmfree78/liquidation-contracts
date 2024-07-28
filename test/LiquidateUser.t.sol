// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LiquidateUser} from "src/LiquidateUser.sol";
import {DeployLiquidateUser} from "script/DeployLiquidateUser.s.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MintableERC20} from "lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol";
import {WETH9Mocked} from "lib/aave-v3-core/contracts/mocks/tokens/WETH9Mocked.sol";
import {MockPoolInherited} from "lib/aave-v3-core/contracts/mocks/helpers/MockPool.sol";
import {PriceOracle} from "lib/aave-v3-core/contracts/mocks/oracle/PriceOracle.sol";
import {MockPoolDataProvider} from "test/mocks/MockPoolDataProvider.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract LiquidateUserTest is Test {
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant STARTING_TOKEN_AMOUNT = 100 ether;

    address public poolAddress;
    address public dataProviderAddress;
    address public priceOracleAddress;

    LiquidateUser liquidateUser;
    MintableERC20 public collateral_token;
    MintableERC20 public extra_token;
    WETH9Mocked public weth;
    address public USER = makeAddr("user");

    function setUp() external {
        DeployLiquidateUser deployLiquidateUser = new DeployLiquidateUser();
        HelperConfig helperConfig;
        (liquidateUser, helperConfig) = deployLiquidateUser.run();

        // set address for contracts
        (poolAddress, dataProviderAddress, priceOracleAddress) = helperConfig.activeNetworkConfig();

        // fund user
        vm.deal(USER, STARTING_USER_BALANCE);
        collateral_token = new MintableERC20("Tether USD", "USDT", 6);
        extra_token = new MintableERC20("Dai Stablecoin", "Dai", 18);
        weth = new WETH9Mocked();

        vm.startPrank(USER);
        collateral_token.mint(STARTING_TOKEN_AMOUNT);
        extra_token.mint(STARTING_TOKEN_AMOUNT);
        weth.mint(STARTING_USER_BALANCE);
        vm.stopPrank();
    }
}
