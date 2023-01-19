//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

interface IPoolDenominator {
    function denominator() external view returns (uint256);
}


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

    event DepositCreate(uint256 indexed id, address indexed owner, bytes10 receiver_d, bytes32 receiver_p, uint64 denominated_amount, uint64 expired);
    event DepositReleaseExpired(uint256 indexed id);
    event DepositSpend(uint256 indexed id);
    

    // size 98 bytes
    struct Deposit {
        uint64 id;             // offset 0
        address owner;          // offset 8
        bytes10 receiver_d;     // offset 40
        bytes32 receiver_p;     // offset 50
        uint64 denominated_amount;  // offset 82
        uint64 expired;        // offset 90
    }

    uint256 internal constant DEPOSIT_SIZE = 98;
    uint256 internal constant ID_OFFSET = 0;
    uint256 internal constant DENOMINATED_AMOUNT_OFFSET = 82;
    uint256 internal constant EXPIRED_OFFSET = 90;
    uint256 internal constant RECEIVER_OFFSET = 40;
    uint256 internal constant RECEIVER_AND_AMOUNT_SIZE = 50;

    uint256 internal constant UINT64_MASK = 0xffffffffffffffff000000000000000000000000000000000000000000000000;
    uint256 internal constant UINT64_SHIFT = 192;

    uint256 public constant EXPIRATION_TIME = 1 days;
    uint256 public constant MAX_DEPOSITS_IN_BATCH = 128;

    address public immutable token;
    address public immutable pool;
    uint256 public immutable denominator;


    mapping(bytes32=>bool) public deposits;
    uint64 public depositCount;

    constructor(address _token, address _pool) {
        token = _token;
        pool = _pool;
        denominator = IPoolDenominator(_pool).denominator();
    }

    function _depositHash(Deposit memory d) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(d.id, d.owner, d.denominated_amount, d.expired, d.receiver_d, d.receiver_p));
    }

    function _depositCreate(address owner, bytes10 receiver_d, bytes32 receiver_p, uint256 amount) internal {
        if (amount < uint256(denominator)) revert DepositEmpty();
        uint64 _depositCount = depositCount;
        uint64 denominated_amount = (amount/denominator).toUint64();
        uint64 _expired = uint64(block.timestamp+EXPIRATION_TIME);
        Deposit memory _deposit = Deposit(_depositCount, owner, receiver_d, receiver_p, denominated_amount, _expired);
        deposits[_depositHash(_deposit)] = true;
        depositCount=_depositCount+1;
        emit DepositCreate(_depositCount, owner, receiver_d, receiver_p, denominated_amount, _expired);
    }

    function _depositReleaseExpired(Deposit memory d) internal {
        if (uint256(d.expired) > block.timestamp) revert DepositNotExpired();
        if (d.owner != msg.sender) revert DepositWrongOwner();
        bytes32 h = _depositHash(d);
        if (!deposits[h]) revert DepositSpent();
        deposits[h] = false;
        emit DepositReleaseExpired(d.id);
    }

    function _depositSpend(Deposit memory d) internal {
        if (uint256(d.expired) <= block.timestamp) revert DepositExpired();
        bytes32 h = _depositHash(d);
        if (!deposits[h]) revert DepositSpent();
        deposits[h] = false;
        emit DepositSpend(d.id);
    }

    function _depositSpendEx(bytes calldata d, uint256 index) internal {
        if (deposit_expired_at(d, index) <= block.timestamp) revert DepositExpired();
        bytes32 h = deposit_hash_at(d, index);
        uint64 id = deposit_id_at(d, index);
        
        if (!deposits[h]) revert DepositSpent();
        deposits[h] = false;
        emit DepositSpend(id);
    }


    function deposit(bytes10 receiver_d, bytes32 receiver_p, uint256 amount) external {
        _depositCreate(msg.sender, receiver_d, receiver_p, amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function depositWithPermit(uint256 amount, bytes10 receiver_d, bytes32 receiver_p, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        _depositCreate(msg.sender, receiver_d, receiver_p, amount);
        IERC20Permit(token).permit(msg.sender, address(this), amount, deadline, v, r, s);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function releaseExpired(Deposit memory _deposit) external {
        _depositReleaseExpired(_deposit);
        IERC20(token).safeTransfer(msg.sender, _deposit.denominated_amount*denominator);
    }

    function deposit_expired_at(bytes calldata d, uint256 index) internal pure returns (uint64) {
        uint256 _expired;
        assembly {
            _expired := shr(UINT64_SHIFT, mload(add(d.offset, add(mul(DEPOSIT_SIZE, index), EXPIRED_OFFSET))))
        }
        return uint64(_expired);
    }

    function deposit_id_at(bytes calldata d, uint256 index) internal pure returns (uint64) {
        uint256 _id;
        assembly {
            _id := shr(UINT64_SHIFT, mload(add(d.offset, add(mul(DEPOSIT_SIZE, index), ID_OFFSET))))
        }
        return uint64(_id);
    }

    function deposit_denominated_amount_at(bytes calldata d, uint256 index) internal pure returns (uint64) {
        uint256 _denominated_amount;
        assembly {
            _denominated_amount := shr(UINT64_SHIFT, mload(add(d.offset, add(mul(DEPOSIT_SIZE, index), DENOMINATED_AMOUNT_OFFSET))))
        }
        return uint64(_denominated_amount);
    }

    function deposit_hash_at(bytes calldata d, uint256 index) internal pure returns(bytes32) {
        return keccak256(d[index*DEPOSIT_SIZE:(index+1)*DEPOSIT_SIZE]);
    }

    function spendMassDeposits(bytes calldata d) external returns(bytes32) {
        if (msg.sender != pool) revert OnlyPool();
        uint256 deposits_length;
        {
            uint256 d_len = d.length;
            if (d_len % DEPOSIT_SIZE != 0) revert IncorrectData();
            deposits_length = d_len/DEPOSIT_SIZE;
            if (deposits_length==0 || deposits_length > MAX_DEPOSITS_IN_BATCH) revert IncorrectData();
        }

        uint64 _amount;
        for (uint256 i=0; i<deposits_length; i++) {
            _depositSpendEx(d, i);
            _amount += deposit_denominated_amount_at(d, i);
        }

        bytes memory deposit_blob = new bytes(RECEIVER_AND_AMOUNT_SIZE*MAX_DEPOSITS_IN_BATCH);

        assembly {
            let deposit_blob_ptr := add(deposit_blob, 32)
            let first_receiver_ptr := add(d.offset, RECEIVER_OFFSET)
            for {let i := 0} lt(i, deposits_length) {i := add(i, 1)} {
                calldatacopy(add(deposit_blob_ptr, mul(i, RECEIVER_AND_AMOUNT_SIZE)), add(first_receiver_ptr, mul(i, DEPOSIT_SIZE)), RECEIVER_AND_AMOUNT_SIZE)
            }
        }

        IERC20(token).safeTransfer(pool, _amount*denominator);
        return keccak256(deposit_blob);
    }

}