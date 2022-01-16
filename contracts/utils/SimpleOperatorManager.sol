//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract SimpleOperatorManager {
    address immutable public operator;

    constructor(address _operatpr) {
        operator = _operatpr;
    }
}