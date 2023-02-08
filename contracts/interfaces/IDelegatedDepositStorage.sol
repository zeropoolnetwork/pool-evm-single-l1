//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegatedDepositStorage {
    struct Deposit {
        uint64 id;           
        address owner;          
        bytes10 receiver_d;     
        bytes32 receiver_p;     
        uint64 denominated_amount;  
        uint64 denominated_fee; 
        uint64 expired;    
    }

    function deposit(bytes10 receiver_d, bytes32 receiver_p, uint256 amount, uint256 fee) external;
    function depositWithPermit(bytes10 receiver_d, bytes32 receiver_p, uint256 amount, uint256 fee, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function releaseExpired(Deposit memory _deposit) external;
    function spendMassDeposits(uint256 out_commitment_hash, bytes calldata d) external returns(uint256, uint256, uint256);

}