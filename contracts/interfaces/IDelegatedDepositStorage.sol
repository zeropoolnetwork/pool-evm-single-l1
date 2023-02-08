//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegatedDepositStorage {
    function deposit(bytes10 receiver_d, bytes32 receiver_p, uint256 amount, uint256 fee) external returns(uint64);
    function depositWithPermit(bytes10 receiver_d, bytes32 receiver_p, uint256 amount, uint256 fee, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns(uint64);
    function releaseExpired(uint64 id) external;
    function spendMassDeposits(uint256 out_commitment_hash, bytes calldata d) external returns(uint256, uint256, uint256);
}