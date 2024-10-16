// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {QualifyUser} from "src/QualifyUser.sol";
import {DeployQualifyUser} from "script/DeployQualifyUser.s.sol";
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

contract QualifyUserTest is Test {
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
    uint256 public constant BPS_FACTOR = 1e4;
    uint256 public constant USDT_PRICE = 1e18;
    uint256 public constant WETH_PRICE = 3000e18;
    uint256 public constant DAI_PRICE = 1e18;
    uint8 public constant DAI_DECIMALS = 18;
    uint8 public constant USDT_DECIMALS = 6;
    uint8 public constant WETH_DECIMALS = 18;

    address public poolAddress;
    address public dataProviderAddress;
    address public priceOracleAddress;
    address payable public wethAddress;

    QualifyUser qualifyUser;
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
        DeployQualifyUser deployQualifyUser = new DeployQualifyUser();
        HelperConfig helperConfig;
        (qualifyUser, helperConfig) = deployQualifyUser.run();

        // set address for contracts
        (poolAddress, dataProviderAddress, priceOracleAddress,,, wethAddress,) = helperConfig.activeNetworkConfig();

        // FUND USER
        vm.deal(USER, STARTING_USER_BALANCE);
        vm.deal(USER2, STARTING_USER_BALANCE);
        console.log("user 1 ", USER);
        console.log("user 2 ", USER2);

        // STEP MOCK TOKENS
        usdt_token = new MintableERC20("Tether USD", "USDT", 6);
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            address(usdt_token),
            USDT_DECIMALS,
            0,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS,
            0,
            true,
            true,
            true,
            true,
            false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(address(usdt_token), USDT_PRICE);
        console.log("usdt token => ", address(usdt_token));

        dai_token = new MintableERC20("Dai Stablecoin", "Dai", DAI_DECIMALS);
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            address(dai_token),
            DAI_DECIMALS,
            0,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS,
            0,
            true,
            true,
            true,
            true,
            false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(address(dai_token), DAI_PRICE);
        console.log("dai token => ", address(dai_token));

        // weth = new WETH9Mocked();
        MockPoolDataProvider(dataProviderAddress).setReserveConfigurationData(
            wethAddress, WETH_DECIMALS, 0, LIQUIDATION_THRESHOLD, LIQUIDATION_BONUS, 0, true, true, true, true, false
        );
        PriceOracle(priceOracleAddress).setAssetPrice(wethAddress, WETH_PRICE);
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
    }

    function testWithSameDebtAndCollateralToken() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](1);
        user[0] = setupUser(USER, address(usdt_token), address(usdt_token), SUPPLY, BORROW);
        // creat aave user account
        vm.startPrank(USER);
        qualifyUser.checkUserAccounts(user);
        vm.stopPrank();
    }

    function test2UsersFirstQualifiedForLiquidationAndSecondNot() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](2);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW);
        user[1] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        // creat aave user account
        vm.startPrank(USER);

        qualifyUser.checkUserAccounts(user);

        (address userId, address debtToken, address collateralToken, uint256 debtToCover, uint256 profit) =
            qualifyUser.topProfitAccount();
        assertEq(userId, USER, "User id does not match");
        assertEq(collateralToken, wethAddress, "collateral token does not match");
        assertEq(debtToken, address(usdt_token), "debt token does not match");

        (uint256 _debtToCover, uint256 profitUsd) = getDebtToCoverAndProfit(BORROW, USDT_PRICE, USDT_DECIMALS);

        assertEq(_debtToCover, debtToCover, "debtToCover does not match");
        assertEq(profitUsd, profit, "profit does not match");

        vm.stopPrank();
    }

    function test2UsersSecondQualifiedForLiquidationAndFirstNot() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](2);
        user[0] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        user[1] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW);
        // creat aave user account
        vm.startPrank(USER);
        qualifyUser.checkUserAccounts(user);

        (address userId, address debtToken, address collateralToken, uint256 debtToCover, uint256 profit) =
            qualifyUser.topProfitAccount();
        assertEq(userId, USER, "User id does not match");
        assertEq(collateralToken, wethAddress, "collateral token does not match");
        assertEq(debtToken, address(usdt_token), "debt token does not match");

        (uint256 _debtToCover, uint256 profitUsd) = getDebtToCoverAndProfit(BORROW, USDT_PRICE, USDT_DECIMALS);

        assertEq(_debtToCover, debtToCover, "debtToCover does not match");
        assertEq(profitUsd, profit, "profit does not match");

        vm.stopPrank();
    }

    function test2UsersBothQualifiedForLiquidation() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](2);
        user[0] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW);
        user[1] = setupUser(USER, wethAddress, address(usdt_token), 2 * SUPPLY_WETH, 2 * BORROW);
        // creat aave user account
        vm.startPrank(USER);
        qualifyUser.checkUserAccounts(user);

        (address userId, address debtToken, address collateralToken, uint256 debtToCover, uint256 profit) =
            qualifyUser.topProfitAccount();
        assertEq(userId, USER, "User id does not match");
        assertEq(collateralToken, wethAddress, "collateral token does not match");
        assertEq(debtToken, address(usdt_token), "debt token does not match");

        (uint256 _debtToCover, uint256 profitUsd) = getDebtToCoverAndProfit(2 * BORROW, USDT_PRICE, USDT_DECIMALS);

        assertEq(_debtToCover, debtToCover, "debtToCover does not match");
        assertEq(profitUsd, profit, "profit does not match");

        vm.stopPrank();
    }

    function test2UsersBothNotQualifiedForLiquidation() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](2);
        user[0] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        user[1] = setupUser(USER, wethAddress, address(usdt_token), 2 * SUPPLY_WETH, BORROW / 5);

        vm.startPrank(USER);
        qualifyUser.checkUserAccounts(user);

        (address userId, address debtToken, address collateralToken, uint256 debtToCover, uint256 profit) =
            qualifyUser.topProfitAccount();
        assertEq(userId, address(0), "User id does not match");
        assertEq(collateralToken, address(0), "collateral token does not match");
        assertEq(debtToken, address(0), "debt token does not match");
        assertEq(0, debtToCover, "debtToCover does not match");
        assertEq(0, profit, "profit does not match");

        vm.stopPrank();
    }

    function testWithDifferentDebtAndCollateralToken() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW);
        // creat aave user account
        vm.startPrank(USER);
        qualifyUser.checkUserAccounts(user);
        vm.stopPrank();
    }

    function testLiquidateRevertsTwoUsersWithHighHealthFactor() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](2);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        user[1] = setupUser(USER2, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        // creat aave user account
        vm.startPrank(USER);

        qualifyUser.checkUserAccounts(user);
        (address userId, address debtToken, address collateralToken, uint256 debtToCover, uint256 profit) =
            qualifyUser.topProfitAccount();
        assertEq(userId, address(0), "User id does not match");
        assertEq(collateralToken, address(0), "collateral token does not match");
        assertEq(debtToken, address(0), "debt token does not match");
        assertEq(0, debtToCover, "debtToCover does not match");
        assertEq(0, profit, "profit does not match");

        vm.stopPrank();
    }

    function testLiquidateRevertsWithHighHealthFactor() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, BORROW / 10);
        // creat aave user account
        vm.startPrank(USER);

        qualifyUser.checkUserAccounts(user);

        (address userId, address debtToken, address collateralToken, uint256 debtToCover, uint256 profit) =
            qualifyUser.topProfitAccount();
        assertEq(userId, address(0), "User id does not match");
        assertEq(collateralToken, address(0), "collateral token does not match");
        assertEq(debtToken, address(0), "debt token does not match");
        assertEq(0, debtToCover, "debtToCover does not match");
        assertEq(0, profit, "profit does not match");

        vm.stopPrank();
    }

    function testLiquidateRevertsWithTooLowHealthFactor() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), 0, BORROW);
        // creat aave user account
        vm.startPrank(USER);

        qualifyUser.checkUserAccounts(user);
        (address userId, address debtToken, address collateralToken, uint256 debtToCover, uint256 profit) =
            qualifyUser.topProfitAccount();
        assertEq(userId, address(0), "User id does not match");
        assertEq(collateralToken, address(0), "collateral token does not match");
        assertEq(debtToken, address(0), "debt token does not match");
        assertEq(0, debtToCover, "debtToCover does not match");
        assertEq(0, profit, "profit does not match");

        vm.stopPrank();
    }

    function testLiquidateRevertsWithNoDebt() public {
        QualifyUser.User[] memory user = new QualifyUser.User[](1);
        user[0] = setupUser(USER, wethAddress, address(usdt_token), SUPPLY_WETH, 0);
        // creat aave user account
        vm.startPrank(USER);

        qualifyUser.checkUserAccounts(user);
        (address userId, address debtToken, address collateralToken, uint256 debtToCover, uint256 profit) =
            qualifyUser.topProfitAccount();
        assertEq(userId, address(0), "User id does not match");
        assertEq(collateralToken, address(0), "collateral token does not match");
        assertEq(debtToken, address(0), "debt token does not match");
        assertEq(0, debtToCover, "debtToCover does not match");
        assertEq(0, profit, "profit does not match");

        vm.stopPrank();
    }

    function setupUser(
        address user,
        address supplyToken,
        address borrowToken,
        uint256 supplyAmount,
        uint256 borrowAmount
    ) public returns (QualifyUser.User memory) {
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
        QualifyUser.User[] memory user = new QualifyUser.User[](1);

        user[0] = QualifyUser.User({id: USER, debtToken: address(borrowToken), collateralToken: address(supplyToken)});

        return user[0];
    }

    function getDebtToCoverAndProfit(uint256 debt, uint256 debt_price, uint8 debt_decimals)
        public
        pure
        returns (uint256, uint256)
    {
        uint256 debtToCover = debt / 2; // liquidation factor is 0.5

        uint256 profitUsd = (debtToCover * debt_price) / 10 ** debt_decimals;

        profitUsd = profitUsd * LIQUIDATION_BONUS;

        profitUsd = profitUsd * (LIQUIDATION_BONUS - BPS_FACTOR);

        profitUsd = profitUsd / BPS_FACTOR;

        profitUsd = profitUsd / BPS_FACTOR;

        return (debtToCover, profitUsd);
    }
}
