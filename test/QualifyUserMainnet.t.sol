// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {QualifyUser} from "src/QualifyUser.sol";
import {DeployQualifyUser} from "script/DeployQualifyUser.s.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";

contract QualifyUserMainnetTest is Test {
    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private testUser = 0xD55b88CbedD80c73a5bdcE00A15DdD5E05330daC;

    QualifyUser qualifyUser;
    QualifyUser.User[] public mainnetUsers;

    function setUp() external {
        DeployQualifyUser deployQualifyUser = new DeployQualifyUser();
        (qualifyUser,) = deployQualifyUser.run();

        mainnetUsers.push(QualifyUser.User({id: testUser, debtToken: USDT_ADDRESS, collateralToken: WETH_ADDRESS}));
    }

    function testWithSameDebtAndCollateralToken() public {
        qualifyUser.checkUserAccounts(mainnetUsers);
    }
}
