//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Parameters.sol";


interface ITransferVerifier {
    function verifyProof(
        uint256[5] memory input,
        uint256[8] memory p
    ) external view returns (bool);
}

interface ITreeVerifier {
    function verifyProof(
        uint256[3] memory input,
        uint256[8] memory p
    ) external view returns (bool);
}

interface IOperatorManager {
    function operator() external view returns(address);
}

interface IMintable {
    function mint(address,uint256) external returns(bool);
}

contract Pool is Parameters {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 immutable public token;
    IMintable immutable public voucher_token;



    uint256 immutable public denominator;
    uint256 immutable public energy_denominator;
    uint256 immutable public native_denominator;

    ITransferVerifier immutable public transfer_verifier;
    ITreeVerifier immutable public tree_verifier;

    
    IOperatorManager immutable public operatorManager;

    modifier onlyOperator() {
        require(operatorManager.operator()==msg.sender);
        _;
    }

    mapping (uint256 => bool) public nullifiers;
    mapping (uint256 => uint256) public roots;
    uint256 public transfer_num;

    constructor(IERC20 _token, IMintable _voucher_token, uint256 _denominator, uint256 _energy_denominator, uint256 _native_denominator, 
        ITransferVerifier _transfer_verifier, ITreeVerifier _tree_verifier, IOperatorManager _operatorManager, uint256 first_root) {
        token=_token;
        voucher_token=_voucher_token;
        denominator=_denominator;
        energy_denominator=_energy_denominator;
        native_denominator=_native_denominator;
        transfer_verifier=_transfer_verifier;
        tree_verifier=_tree_verifier;
        operatorManager=_operatorManager;
        roots[0] = first_root;
    }

    event Message(bytes message);



    function transact() external payable returns(bool) {
        // Transfer part
        require(transfer_verifier.verifyProof(transfer_pub(roots[transfer_index()]), transfer_proof()), "bad transfer proof"); 
        require(!nullifiers[transfer_nullifier()],"doublespend detected");
        uint256 _transfer_num = transfer_num;
        require(transfer_index() <= _transfer_num, "transfer index out of bounds");

        uint256 fee = memo_fee();
        int256 token_amount = transfer_token_amount() + int256(fee);
        int256 energy_amount = transfer_energy_amount();

        if (tx_type()==0) { // Deposit
            require(token_amount>=0 && energy_amount==0 && msg.value == 0, "incorrect deposit amounts");
            token.safeTransferFrom(deposit_spender(), address(this), uint256(token_amount).mul(denominator));
        } else if (tx_type()==1) { // Transfer 
            require(token_amount==0 && energy_amount==0 && msg.value == 0, "incorrect transfer amounts");

        } else if (tx_type()==2) { // Withdraw
            require(token_amount<=0 && energy_amount<=0 && msg.value == memo_native_amount().mul(native_denominator), "incorrect transfer amounts");

            if (token_amount<0) {
                token.safeTransfer(memo_receiver(), uint256(-token_amount).mul(denominator));
            }

            if (energy_amount<0) {
                require(address(voucher_token)!=address(0), "no voucher token");
                voucher_token.mint(memo_receiver(), uint256(-energy_amount).mul(energy_denominator));
            }

            if (msg.value > 0) {
                payable(memo_receiver()).transfer(msg.value);
            }

        } else revert("Incorrect transaction type");

        if (fee>0) {
            token.safeTransfer(operatorManager.operator(), fee.mul(denominator));
        }

        nullifiers[transfer_nullifier()] = true;


        // Tree part
        require(tree_verifier.verifyProof(tree_pub(roots[_transfer_num]), tree_proof()), "bad tree proof");
        roots[_transfer_num+1] = tree_root_after();
        transfer_num = _transfer_num+1;
    
        emit Message(memo_message());
        return true;
    }
    

}

