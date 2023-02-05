//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DelegatedDepositVerifierMock {
    function verifyProof(
        uint256[1] memory,
        uint256[8] memory
    ) external pure returns(bool){
        return true;
    }
}