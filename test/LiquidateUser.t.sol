// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LiquidateUser} from "src/LiquidateUser.sol";
import {DeployLiquidateUser} from "script/DeployLiquidateUser.s.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MintableERC20} from "lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol";
import {WETH9Mocked} from "lib/aave-v3-core/contracts/mocks/tokens/WETH9Mocked.sol";
import {MockPool} from "test/mocks/MockPool.sol";
import {PriceOracle} from "lib/aave-v3-core/contracts/mocks/oracle/PriceOracle.sol";
import {MockPoolDataProvider} from "test/mocks/MockPoolDataProvider.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import "lib/aave-v3-core/contracts/interfaces/IPool.sol";

contract LiquidateUserTest is Test {
    struct Users {
        address id;
        address debtToken;
        address collateralToken;
    }

    uint256 private constant LIQUIDATION_THRESHOLD = 7000; // set fixed 70% liquidation threshold for testing
    uint256 private constant LIQUIDATION_BONUS = 11000; // set fixed 10% liquidation bonus for testing
    uint256 public constant STARTING_USER_BALANCE = 10000 ether;
    uint256 public constant STARTING_TOKEN_AMOUNT = 10000 ether;
    uint256 public constant SUPPLY = 10000e6;
    uint256 public constant BORROW = 10000e6;

    address public poolAddress;
    address public dataProviderAddress;
    address public priceOracleAddress;
    address public poolAddressesProvider;
    address public swapRouterAddress;
    address public walletAddress;

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
        (poolAddress, dataProviderAddress, priceOracleAddress, poolAddressesProvider, swapRouterAddress, walletAddress)
        = helperConfig.activeNetworkConfig();

        // FUND USER
        vm.deal(USER, STARTING_USER_BALANCE);

        // STEP MOCK TOKENS
        collateral_token = new MintableERC20("Tether USD", "USDT", 6);
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            address(collateral_token), 6, 0, LIQUIDATION_THRESHOLD, LIQUIDATION_BONUS, 0, true, true, true, true, false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(address(collateral_token), 1e18);
        console.log("collateral token => ", address(collateral_token));

        extra_token = new MintableERC20("Dai Stablecoin", "Dai", 18);
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            address(extra_token), 18, 0, LIQUIDATION_THRESHOLD, LIQUIDATION_BONUS, 0, true, true, true, true, false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(address(extra_token), 1e18);
        console.log("extra token => ", address(extra_token));

        weth = new WETH9Mocked();
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            address(weth), 18, 0, LIQUIDATION_THRESHOLD, LIQUIDATION_BONUS, 0, true, true, true, true, false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(address(weth), 3000e18);
        console.log("weth token => ", address(weth));

        // PROVIDER USERS WITH TOKENS
        vm.startPrank(USER);
        collateral_token.mint(STARTING_TOKEN_AMOUNT);
        collateral_token.approve(address(poolAddress), SUPPLY);

        extra_token.mint(STARTING_TOKEN_AMOUNT);
        extra_token.approve(address(poolAddress), SUPPLY);

        weth.mint(STARTING_USER_BALANCE);
        weth.approve(address(poolAddress), SUPPLY);
        vm.stopPrank();

        // ADD COLLATERAL AND BORROW FROM POOL CONTRACT
        MockPool(poolAddress).supply(address(collateral_token), SUPPLY, USER, 0);
        MockPool(poolAddress).borrow(address(collateral_token), BORROW, 1, 0, USER);

        // MAKE SURE DATA PROVIDER IS SETUP WITH USER
        MockPoolDataProvider(dataProviderAddress).setUserReserveData(
            USER, address(collateral_token), SUPPLY, BORROW, 0, 0, 0, 0, 0, 0, true
        );
        MockPoolDataProvider(dataProviderAddress).setUserReserveData(
            USER, address(extra_token), 0, 0, 0, 0, 0, 0, 0, 0, true
        );
        MockPoolDataProvider(dataProviderAddress).setUserReserveData(USER, address(weth), 0, 0, 0, 0, 0, 0, 0, 0, true);

        // fund mock contracts
        // tokesn for pool contract
        collateral_token.mint(poolAddress, 100000 ether);
        weth.mint(poolAddress, 100000 ether);
        extra_token.mint(poolAddress, 100000 ether);

        // tokens for swap router
        collateral_token.mint(swapRouterAddress, 100000 ether);
        weth.mint(swapRouterAddress, 100000 ether);
        extra_token.mint(swapRouterAddress, 100000 ether);
    }

    function testContractIsBeingCallSuccessfully() public {
        // creat aave user account
        vm.startPrank(USER);

        LiquidateUser.User[] memory user = new LiquidateUser.User[](1);

        user[0] = LiquidateUser.User({
            id: USER,
            debtToken: address(collateral_token),
            collateralToken: address(collateral_token)
        });

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }
}
