//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IOperatorManager {
    function operator() external view returns(address);
}
