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

contract QualifyUserSepoliaTest is Test {
    struct Users {
        address id;
        address debtToken;
        address collateralToken;
    }

    uint256 private constant LIQUIDATION_HF_THRESHOLD = 1e18;
    uint256 private constant CLOSE_FACTOR_HF_THRESHOLD = 95e16;
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
    address public constant USDT_ADDRESS = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
    address public constant WETH_ADDRESS = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;

    address private testUser = 0xD55b88CbedD80c73a5bdcE00A15DdD5E05330daC;
    address public poolAddress;
    address public dataProviderAddress;
    address public priceOracleAddress;
    address payable public wethAddress;

    QualifyUser qualifyUser;
    QualifyUser.User[] public sepoliaUsers;
    MintableERC20 public usdt_token;
    MintableERC20 public dai_token;
    WETH9Mocked public weth;

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

        sepoliaUsers.push(QualifyUser.User({id: testUser, debtToken: USDT_ADDRESS, collateralToken: WETH_ADDRESS}));
    }

    function testWithSameDebtAndCollateralToken() public {
        qualifyUser.checkUserAccounts(sepoliaUsers);
    }
}
