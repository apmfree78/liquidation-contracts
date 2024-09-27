// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LiquidateUser} from "src/LiquidateUser.sol";
import {DeployLiquidateUser} from "script/DeployLiquidateUser.s.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MintableERC20} from "lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol";
import {WETH9Mocked} from "lib/aave-v3-core/contracts/mocks/tokens/WETH9Mocked.sol";
import {MockPool} from "test/mocks/MockPool.sol";
import {MockSwapRouter} from "test/mocks/MockSwapRouter.sol";
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
    uint256 private constant LIQUIDATION_BONUS = 10500; // set fixed 10% liquidation bonus for testing
    uint256 public constant STARTING_USER_BALANCE = 10000 ether;
    uint256 public constant STARTING_TOKEN_AMOUNT = 10000 ether;
    uint256 public constant SUPPLY = 10000e6;
    uint256 public constant SUPPLY_WETH = 37e17; //3.7 ETH
    uint256 public constant BORROW = 10000e6;

    address public poolAddress;
    address public dataProviderAddress;
    address public priceOracleAddress;
    address public poolAddressesProvider;
    address public swapRouterAddress;
    address payable public wethAddress;
    address public walletAddress;

    LiquidateUser liquidateUser;
    MintableERC20 public usdt_token;
    MintableERC20 public dai_token;
    WETH9Mocked public weth;
    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");

    event LiquidateAccount(
        address indexed liquidator,
        address indexed beneficiary,
        address indexed collateralToken,
        uint256 profit,
        address user
    );

    function setUp() external {
        DeployLiquidateUser deployLiquidateUser = new DeployLiquidateUser();
        HelperConfig helperConfig;
        (liquidateUser, helperConfig) = deployLiquidateUser.run();

        // set address for contracts
        (
            poolAddress,
            dataProviderAddress,
            priceOracleAddress,
            poolAddressesProvider,
            swapRouterAddress,
            wethAddress,
            walletAddress
        ) = helperConfig.activeNetworkConfig();

        // FUND USER
        vm.deal(USER, STARTING_USER_BALANCE);
        vm.deal(USER2, STARTING_USER_BALANCE);
        console.log("user 1 ", USER);
        console.log("user 2 ", USER2);

        // STEP MOCK TOKENS
        usdt_token = new MintableERC20("Tether USD", "USDT", 6);
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            address(usdt_token), 6, 0, LIQUIDATION_THRESHOLD, LIQUIDATION_BONUS, 0, true, true, true, true, false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(address(usdt_token), 1e18);
        console.log("usdt token => ", address(usdt_token));

        dai_token = new MintableERC20("Dai Stablecoin", "Dai", 18);
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            address(dai_token), 18, 0, LIQUIDATION_THRESHOLD, LIQUIDATION_BONUS, 0, true, true, true, true, false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(address(dai_token), 1e18);
        console.log("dai token => ", address(dai_token));

        // weth = new WETH9Mocked();
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            wethAddress, 18, 0, LIQUIDATION_THRESHOLD, LIQUIDATION_BONUS, 0, true, true, true, true, false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(wethAddress, 3000e18);
        console.log("weth token => ", wethAddress);

        // PROVIDER USERS WITH TOKENS
        vm.startPrank(USER);
        usdt_token.mint(STARTING_TOKEN_AMOUNT);
        usdt_token.approve(address(poolAddress), SUPPLY);

        dai_token.mint(STARTING_TOKEN_AMOUNT);
        dai_token.approve(address(poolAddress), SUPPLY);

        WETH9Mocked(wethAddress).mint(STARTING_USER_BALANCE);
        WETH9Mocked(wethAddress).approve(address(poolAddress), SUPPLY);
        vm.stopPrank();

        vm.startPrank(USER2);
        usdt_token.mint(STARTING_TOKEN_AMOUNT);
        usdt_token.approve(address(poolAddress), SUPPLY);

        dai_token.mint(STARTING_TOKEN_AMOUNT);
        dai_token.approve(address(poolAddress), SUPPLY);

        WETH9Mocked(wethAddress).mint(STARTING_USER_BALANCE);
        WETH9Mocked(wethAddress).approve(address(poolAddress), SUPPLY);
        vm.stopPrank();

        // fund mock contracts
        // tokens for pool contract
        usdt_token.mint(poolAddress, 100000 ether);
        WETH9Mocked(wethAddress).mint(poolAddress, 100000 ether);
        dai_token.mint(poolAddress, 100000 ether);

        // tokens for swap router
        usdt_token.mint(swapRouterAddress, 100000 ether);
        WETH9Mocked(wethAddress).mint(swapRouterAddress, 100000 ether);
        dai_token.mint(swapRouterAddress, 100000 ether);
    }

    function testWithSameDebtAndCollateralToken() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](1);
        user[0] = setupUser(USER, address(usdt_token), address(usdt_token), SUPPLY, BORROW);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectEmit(false, false, false, false, address(liquidateUser));

        emit LiquidateAccount(address(liquidateUser), address(0), address(0), 0, USER);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function test2UsersFirstQualifiedForLiquidationAndSecondNot() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](2);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW);
        user[1] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectEmit(false, false, false, false, address(liquidateUser));

        emit LiquidateAccount(address(liquidateUser), address(0), address(0), 0, USER);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function test2UsersSecondQualifiedForLiquidationAndFirstNot() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](2);
        user[0] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        user[1] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectEmit(false, false, false, false, address(liquidateUser));

        emit LiquidateAccount(address(liquidateUser), address(0), address(0), 0, USER);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function test2UsersBothQualifiedForLiquidation() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](2);
        user[0] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW);
        user[1] = setupUser(USER, wethAddress, address(usdt_token), 2 * SUPPLY_WETH, 2 * BORROW);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectEmit(false, false, false, false, address(liquidateUser));

        // check user account with higher profit is liquidated
        emit LiquidateAccount(address(liquidateUser), address(0), address(0), 0, USER2);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function test2UsersBothNotQualifiedForLiquidation() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](2);
        user[0] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        user[1] = setupUser(USER, wethAddress, address(usdt_token), 2 * SUPPLY_WETH, BORROW / 5);

        vm.startPrank(USER);
        vm.expectRevert(LiquidateUser.NoUserAccountQualifiedForLiquidation.selector);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function testWithDifferentDebtAndCollateralToken() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectEmit(false, false, false, false, address(liquidateUser));

        emit LiquidateAccount(address(liquidateUser), address(0), address(0), 0, USER);
        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function testLiquidateRevertsTwoUsersWithHighHealthFactor() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](2);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        user[1] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectRevert(LiquidateUser.NoUserAccountQualifiedForLiquidation.selector);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function testLiquidateRevertsWithHighHealthFactor() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectRevert(LiquidateUser.NoUserAccountQualifiedForLiquidation.selector);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function testLiquidateRevertsWithLowProfit() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH / 20, BORROW / 20);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectRevert(LiquidateUser.NoUserAccountQualifiedForLiquidation.selector);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function testLiquidateRevertsWithTooLowHealthFactor() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), 0, BORROW);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectRevert(LiquidateUser.NoUserAccountQualifiedForLiquidation.selector);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function testLiquidateRevertsWithNoDebt() public {
        LiquidateUser.User[] memory user = new LiquidateUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, 0);
        // creat aave user account
        vm.startPrank(USER);
        vm.expectRevert(LiquidateUser.NoUserAccountQualifiedForLiquidation.selector);

        liquidateUser.findAndLiquidateAccount(user);
        vm.stopPrank();
    }

    function setupUser(
        address user,
        address supplyToken,
        address borrowToken,
        uint256 supplyAmount,
        uint256 borrowAmount
    ) public returns (LiquidateUser.User memory) {
        // ADD COLLATERAL AND BORROW FROM POOL CONTRACT
        MockPool(poolAddress).supply(supplyToken, supplyAmount, user, 0);
        MockPool(poolAddress).borrow(borrowToken, borrowAmount, 1, 0, user);

        // DATA PROVIDER IS SETUP WITH USER
        MockPoolDataProvider(dataProviderAddress).setUserReserveData(
            user, supplyToken, supplyAmount, 0, 0, 0, 0, 0, 0, 0, true
        );
        MockPoolDataProvider(dataProviderAddress).setUserReserveData(
            user, borrowToken, 0, borrowAmount, 0, 0, 0, 0, 0, 0, true
        );
        LiquidateUser.User[] memory user = new LiquidateUser.User[](1);

        user[0] = LiquidateUser.User({id: USER, debtToken: address(borrowToken), collateralToken: address(supplyToken)});

        return user[0];
    }
}
