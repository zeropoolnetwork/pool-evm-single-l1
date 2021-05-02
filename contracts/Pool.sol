//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/Groth16.sol";
import "./lib/Types.sol";


interface IOperatorManager {
    function operator() external view returns(address);
}

interface IParameters {
    function vk_tx() external view returns(Groth16.VerifyingKey memory);
    function vk_tree_update() external view returns(Groth16.VerifyingKey memory);    
}

interface IMintable {
    function mint(address,uint256) external returns(bool);
}

contract Pool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using TransferPub for byte[152];
    using WithdrawData for byte[60];
    using TransferData for byte[4];

    IParameters immutable public params;
    IERC20 immutable public token;
    IMintable immutable public voucher_token;



    uint256 immutable public denominator;
    IOperatorManager immutable public operatorManager;

    modifier onlyOperator() {
        require(operatorManager.operator()==msg.sender);
        _;
    }

    mapping (uint256 => bool) public nullifiers;
    mapping (uint256 => uint256) public roots;
    uint256 public txnumber;

    constructor(IParameters _params, IERC20 _token, IMintable _voucher_token, uint256 _denominator, IOperatorManager _operatorManager) {
        params=_params;
        token=_token;
        voucher_token=_voucher_token;
        denominator=_denominator;
        operatorManager=_operatorManager;
    }

    struct Signature {
        uint8 v;
        bytes32 r; 
        bytes32 s;
    }


    event Message(bytes message);



    function _verifyRoot(uint256 oldRoot, uint256 newRoot, uint256 leafIndex, uint256 leaf, Groth16.Proof memory proof) internal view returns(bool) {
        uint256[] memory inputs = new uint[](4);
        inputs[0] = oldRoot;
        inputs[1] = newRoot;
        inputs[2] = leafIndex;
        inputs[3] = leaf;
        return Groth16.verify(inputs, proof, params.vk_tree_update());
    }

    function _updateRoot(uint256 newRoot, uint256 leaf, Groth16.Proof memory proof) internal {
        uint256 leafIndex = txnumber;
        uint256 oldRoot = roots[leafIndex-1];
        require(_verifyRoot(oldRoot, newRoot, leafIndex, leaf, proof), "bad tree update proof");
        roots[leafIndex] = newRoot;
        txnumber = leafIndex+1;
    }

    function deposit(
        byte[152] memory pub, byte[4] memory data, bytes memory message, Signature memory sign, uint256 newRoot,
        Groth16.Proof memory txProof, Groth16.Proof memory treeProof
    ) onlyOperator external returns(bool) {
        require(roots[pub.txnumber()]==pub.root(), "wrong root");
        require(!nullifiers[pub.nullifier()], "existed nullifier");
        require(pub.energy_delta()==0, "voucher token deposits or withdrawals disabled");

        int64 amount = pub.token_delta() + data.fee();
        require (amount >= pub.token_delta() && data.fee()>=0 && amount >= 0, "bad token_delta or fee");
        

        bytes32 h = keccak256(abi.encodePacked(pub, data, message));
        uint256 h_reduced = Groth16.reduce(uint256(h));
        require(pub.memo() == h_reduced, "bad memo");

        address spender = ecrecover(h, sign.v, sign.r, sign.s);
        require(Groth16.verify(pub.toInputs(), txProof, params.vk_tx()), "bad tx proof");
        
        nullifiers[pub.nullifier()] = true;
        _updateRoot(newRoot, pub.out_commit(), treeProof);
        
        token.safeTransferFrom(spender, address(this), uint256(amount).mul(denominator));

        if (data.fee()>0) {
            token.safeTransfer(operatorManager.operator(), uint256(data.fee()).mul(denominator));
        }
        emit Message(message);
        return true;
    }

    function transfer(
        byte[152] memory pub, byte[4] memory data, bytes memory message, uint256 newRoot,
        Groth16.Proof memory txProof, Groth16.Proof memory treeProof
    ) onlyOperator external returns(bool) {
        require(roots[pub.txnumber()]==pub.root(), "wrong root");
        require(!nullifiers[pub.nullifier()], "existed nullifier");
        require(pub.energy_delta()==0, "voucher token deposits or withdrawals disabled");

        int64 amount = pub.token_delta() + data.fee();
        require (amount >= pub.token_delta() && data.fee()>=0 && amount == 0, "bad token_delta or fee");
        

        bytes32 h = keccak256(abi.encodePacked(pub, data, message));
        uint256 h_reduced = Groth16.reduce(uint256(h));
        require(pub.memo() == h_reduced, "bad memo");

        require(Groth16.verify(pub.toInputs(), txProof, params.vk_tx()), "bad tx proof");
        
        nullifiers[pub.nullifier()] = true;
        _updateRoot(newRoot, pub.out_commit(), treeProof);
        
        if (data.fee()>0) {
            token.safeTransfer(operatorManager.operator(), uint256(data.fee()).mul(denominator));
        }
        emit Message(message);
        return true;
    }

    function withdraw(
        byte[152] memory pub, byte[60] memory data, bytes memory message, uint256 newRoot,
        Groth16.Proof memory txProof, Groth16.Proof memory treeProof
    ) onlyOperator external payable returns(bool) {
        require(roots[pub.txnumber()]==pub.root(), "wrong root");
        require(!nullifiers[pub.nullifier()], "existed nullifier");
        require(pub.energy_delta()<=0, "voucher token deposits disabled");

        int64 amount = pub.token_delta() + data.fee();
        require (amount >= pub.token_delta() && data.fee()>=0 && amount <= 0, "bad token_delta or fee");
        
        bytes32 h = keccak256(abi.encodePacked(pub, data, message));
        uint256 h_reduced = Groth16.reduce(uint256(h));
        require(pub.memo() == h_reduced, "bad memo");

        require(Groth16.verify(pub.toInputs(), txProof, params.vk_tx()), "bad tx proof");
        
        nullifiers[pub.nullifier()] = true;
        _updateRoot(newRoot, pub.out_commit(), treeProof);

        require(data.native_amount()==msg.value, "bad native amount");

        if (msg.value > 0){
            payable(data.receiver()).transfer(msg.value);
        }
        
        if (amount < 0) {
            token.safeTransfer(data.receiver(), uint256(-amount).mul(denominator));
        }
        
        if (pub.energy_delta()<0) {
            voucher_token.mint(data.receiver(), uint256(-pub.energy_delta()));
        }

        if (data.fee()>0) {
            token.safeTransfer(operatorManager.operator(), uint256(data.fee()).mul(denominator));
        }
        emit Message(message);
        return true;
    }


}



