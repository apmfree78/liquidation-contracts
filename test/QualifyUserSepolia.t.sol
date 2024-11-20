// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {QualifyUser} from "src/QualifyUser.sol";
import {DeployQualifyUser} from "script/DeployQualifyUser.s.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";

contract QualifyUserSepoliaTest is Test {
    address public constant USDT_ADDRESS = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
    address public constant WETH_ADDRESS = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
    address private testUser = 0xD55b88CbedD80c73a5bdcE00A15DdD5E05330daC;

    QualifyUser qualifyUser;
    QualifyUser.User[] public sepoliaUsers;

    function setUp() external {
        DeployQualifyUser deployQualifyUser = new DeployQualifyUser();
        (qualifyUser,) = deployQualifyUser.run();

        sepoliaUsers.push(QualifyUser.User({id: testUser, debtToken: USDT_ADDRESS, collateralToken: WETH_ADDRESS}));
    }

    function testWithSameDebtAndCollateralToken() public view {
        QualifyUser.TopProfitUserAccount memory topProfitUserAccount = qualifyUser.checkUserAccounts(sepoliaUsers);
        console.log("user id =>", topProfitUserAccount.userId);
        console.log("collateral token =>", topProfitUserAccount.collateralToken);
        console.log("debt token =>", topProfitUserAccount.debtToken);
        console.log("profit =>", topProfitUserAccount.profit);
    }
}
