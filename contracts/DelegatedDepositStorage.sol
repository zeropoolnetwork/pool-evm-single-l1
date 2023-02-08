//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./interfaces/IPoolDenominator.sol";

contract DelegatedDepositStorage {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    error DepositNotExpired();
    error DepositExpired();
    error DepositWrongOwner();
    error DepositSpent();
    error DepositEmpty();
    error IncorrectData();

    error OnlyPool();

    event DepositCreate(uint64 indexed id, address indexed owner, bytes10 receiver_d, bytes32 receiver_p, uint64 denominated_amount, uint64 denominated_fee, uint64 expired);
    event DepositReleaseExpired(uint64 indexed id);
    event DepositSpend(uint64 indexed id);
    
    struct Deposit {
        address owner;          
        bytes10 receiver_d;     
        bytes32 receiver_p;     
        uint64 denominated_amount;  
        uint64 denominated_fee;
        uint64 expired;       
    }

    struct DepositMemo {        // size 58 bytes
        uint64 id;                  // offset 0
        bytes10 receiver_d;         // offset 8
        bytes32 receiver_p;         // offset 18
        uint64 denominated_amount;  // offset 50
    }

    uint256 internal constant DEPOSIT_MEMO_SIZE = 58;
    uint256 internal constant DEPOSIT_ZK_SIZE = 50;

    uint256 internal constant DEPOSIT_MEMO_ID_OFFSET = 0;
    uint256 internal constant DEPOSIT_MEMO_RECEIVER_D_OFFSET = 8;
    uint256 internal constant DEPOSIT_MEMO_RECEIVER_P_OFFSET = 18;
    uint256 internal constant DEPOSIT_MEMO_DENOMINATED_AMOUNT_OFFSET = 50;
    


    uint256 public constant EXPIRATION_TIME = 1 days;
    uint256 public constant MAX_DEPOSITS_IN_BATCH = 16;

    address public immutable token;
    address public immutable pool;
    uint256 public immutable denominator;


    mapping(uint64=>Deposit) public deposits;
    uint64 public depositCount;

    constructor(address _token, address _pool) {
        token = _token;
        pool = _pool;
        denominator = IPoolDenominator(_pool).denominator();
    }

    // function _depositHash(Deposit memory d) internal pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(d.id, d.owner, d.receiver_d, d.receiver_p, d.denominated_amount, d.denominated_fee, d.expired));
    // }

    function _depositCreate(address owner, bytes10 receiver_d, bytes32 receiver_p, uint256 amount, uint256 fee) internal returns(uint64) {
        if (amount < uint256(denominator)) revert DepositEmpty();
        uint64 _depositCount = depositCount;
        uint64 denominated_amount = (amount/denominator).toUint64();
        uint64 denominated_fee = (fee/denominator).toUint64();
        uint64 _expired = uint64(block.timestamp+EXPIRATION_TIME);
        deposits[_depositCount] = Deposit(owner, receiver_d, receiver_p, denominated_amount, denominated_fee, _expired);
        depositCount=_depositCount+1;
        emit DepositCreate(_depositCount, owner, receiver_d, receiver_p, denominated_amount, denominated_fee, _expired);
        return _depositCount;
    }

    function _depositReleaseExpired(uint64 id) internal returns(uint64) {
        Deposit memory d = deposits[id];
        if (uint256(d.expired) > block.timestamp) revert DepositNotExpired();
        if (d.owner == address(0)) revert DepositSpent();
        if (d.owner != msg.sender) revert DepositWrongOwner();
        
        deposits[id].owner = address(0);
        emit DepositReleaseExpired(id);
        return d.denominated_amount+d.denominated_fee;
    }


    function _depositSpendEx(bytes calldata d, uint256 index) internal returns(uint64, uint64){
        uint64 id = deposit_id_at(d, index);
        bytes10 receiver_d = deposit_receiver_d_at(d, index);
        bytes32 receiver_p = deposit_receiver_p_at(d, index);
        uint64 denominated_amount = deposit_denominated_amount_at(d, index);
        Deposit memory _deposit = deposits[id];
        
        if (_deposit.expired <= block.timestamp) revert DepositExpired();
        if (_deposit.receiver_d != receiver_d || _deposit.receiver_p != receiver_p || _deposit.denominated_amount != denominated_amount) revert IncorrectData();
        if (_deposit.owner == address(0)) revert DepositSpent();

        deposits[id].owner = address(0);
        emit DepositSpend(id);

        return (_deposit.denominated_amount, _deposit.denominated_fee);
    }


    function deposit(bytes10 receiver_d, bytes32 receiver_p, uint256 amount, uint256 fee) external returns(uint64 id){
        id = _depositCreate(msg.sender, receiver_d, receiver_p, amount, fee);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount+fee);
    }

    function depositWithPermit(bytes10 receiver_d, bytes32 receiver_p, uint256 amount, uint256 fee, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns(uint64 id){
        id = _depositCreate(msg.sender, receiver_d, receiver_p, amount, fee);
        IERC20Permit(token).permit(msg.sender, address(this), amount+fee, deadline, v, r, s);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function releaseExpired(uint64 id) external {
        IERC20(token).safeTransfer(msg.sender, _depositReleaseExpired(id)*denominator);
    }


    function deposit_id_at(bytes calldata d, uint256 index) internal pure returns (uint64) {
        bytes8 _id;
        assembly {
            _id := calldataload(add(d.offset, add(mul(DEPOSIT_MEMO_SIZE, index), DEPOSIT_MEMO_ID_OFFSET)))
        }
        return uint64(_id);
    }

    function deposit_receiver_d_at(bytes calldata d, uint256 index) internal pure returns (bytes10) {
        bytes10 _receiver_d;
        assembly {
            _receiver_d := calldataload(add(d.offset, add(mul(DEPOSIT_MEMO_SIZE, index), DEPOSIT_MEMO_RECEIVER_D_OFFSET)))
        }
        return _receiver_d;
    }

    function deposit_receiver_p_at(bytes calldata d, uint256 index) internal pure returns (bytes32) {
        bytes32 _receiver_p;
        assembly {
            _receiver_p := calldataload(add(d.offset, add(mul(DEPOSIT_MEMO_SIZE, index), DEPOSIT_MEMO_RECEIVER_P_OFFSET)))
        }
        return _receiver_p;
    }


    function deposit_denominated_amount_at(bytes calldata d, uint256 index) internal pure returns (uint64) {
        bytes8 _denominated_amount;
        assembly {
            _denominated_amount := calldataload(add(d.offset, add(mul(DEPOSIT_MEMO_SIZE, index), DEPOSIT_MEMO_DENOMINATED_AMOUNT_OFFSET)))
        }
        return uint64(_denominated_amount);
    }

    function bn256reduce(uint256 x) internal pure returns (uint256) {
        return x % 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function spendMassDeposits(uint256 out_commitment_hash, bytes calldata d) external returns(uint256, uint256, uint256) {
        if (msg.sender != pool) revert OnlyPool()
        ;
        uint256 deposits_length;
        {
            uint256 t = d.length;
            if (t % DEPOSIT_MEMO_SIZE != 0) revert IncorrectData();
            deposits_length = t/DEPOSIT_MEMO_SIZE;
            if (deposits_length==0 || deposits_length > MAX_DEPOSITS_IN_BATCH) revert IncorrectData();
        }

        uint64 _amount=0;
        uint64 _fee=0;
        for (uint256 i=0; i<deposits_length; i++) {
            (uint64 a, uint64 f) = _depositSpendEx(d, i);
            _amount += a;
            _fee += f;
        }

        bytes memory deposit_blob = new bytes(DEPOSIT_ZK_SIZE*MAX_DEPOSITS_IN_BATCH+32);

        assembly {
            mstore(add(deposit_blob, 32), out_commitment_hash)
            let deposit_blob_ptr := add(deposit_blob, 64)
            let first_deposit_zk_ptr := add(d.offset, DEPOSIT_MEMO_RECEIVER_D_OFFSET)
            for {let i := 0} lt(i, deposits_length) {i := add(i, 1)} {
                calldatacopy(add(deposit_blob_ptr, mul(i, DEPOSIT_ZK_SIZE)), add(first_deposit_zk_ptr, mul(i, DEPOSIT_MEMO_SIZE)), DEPOSIT_ZK_SIZE)
            }
        }

        uint256 total_amount = _amount+_fee;

        IERC20(token).safeTransfer(pool, total_amount*denominator);     
        return (total_amount, _fee, bn256reduce(uint256(keccak256(deposit_blob))));
    }

}