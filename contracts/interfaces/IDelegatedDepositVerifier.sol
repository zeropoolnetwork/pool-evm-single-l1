//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegatedDepositVerifier {
    function verifyProof(
        uint256[1] memory input,
        uint256[8] memory p
    ) external view returns (bool);
}
