//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IOperatorManager {
    function operator() external view returns(address);
}
