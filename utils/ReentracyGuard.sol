// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract ReentrancyGuard {
    bool private _locked;

    constructor() {
        _locked = false;
    }

    modifier noReentrancy() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
}
