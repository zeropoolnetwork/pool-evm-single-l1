//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleOperatorManager {
    address immutable public operator;

    constructor(address _operatpr) {
        operator = _operatpr;
    }
}