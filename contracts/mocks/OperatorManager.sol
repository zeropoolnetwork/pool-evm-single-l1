//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OperatorManagerMock is Ownable {
    function operator() external view returns(address) {
        return owner();
    }
}