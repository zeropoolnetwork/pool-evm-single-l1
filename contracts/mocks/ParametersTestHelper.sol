//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "../Parameters.sol";

contract ParametersTestHelper is Parameters {

    function test_transfer_pub(uint256 root) pure external returns (uint256[5] memory r) {
        r = transfer_pub(root);
    }
    
    function test_transfer_nullifier() pure external returns(uint256 r) {
        r = transfer_nullifier();
    }

    function test_transfer_out_commit() pure internal returns(uint256 r) {
        r = transfer_out_commit();
    }

    function test_transfer_index() pure internal returns(uint48 r) {
        r = transfer_index();
    }

    function test_transfer_energy_amount() pure internal returns(int256 r) {
        r = transfer_energy_amount();
    } 

    function test_transfer_token_amount() pure internal returns(int256 r) {
        r = transfer_token_amount();
    }


    function test_transfer_proof() pure internal returns (uint256[8] memory r) {
        r=transfer_proof();
    }


    function test_tree_pub(uint256 root_before) pure internal returns (uint256[3] memory r) {
        r = tree_pub(root_before);
    }


    function test_tree_root_after() pure internal returns(uint256 r) {
        r = tree_root_after();
    }


    function test_tree_proof() pure internal returns (uint256[8] memory r) {
        r = tree_proof();
    }

    function test_tx_type() pure internal returns(uint256 r) {
        r = tx_type();
    }

    function test_memo_size() pure internal returns(uint256 r) {
        r = memo_size();
    }

    function test_memo_hash() pure internal returns (uint256 r) {
        r = memo_hash();
    }

    function test_memo_message() pure internal returns (bytes memory r) {
        r = memo_message();
    }
    

    function test_memo_fee() pure internal returns (uint256 r) {
        r = memo_fee();
    }

    function test_memo_native_amount() pure internal returns (uint256 r) {
        r = memo_native_amount();
    }
    }

    function test_memo_receiver() pure internal returns (address r) {
        r = memo_receiver();
    }


    function test_deposit_spender() pure internal returns (address) {
        r = deposit_spender();
    }


    function test_transfer_pub_selector() pure external returns(bytes4) {
        return this.test_transfer_pub.selector;
    }

    function test_transfer_nullifier_selector() pure external returns(bytes4) {
        return this.test_transfer_nullifier.selector;
    }

    function test_transfer_out_commit_selector() pure external returns(bytes4) {
        return this.test_transfer_out_commit.selector;
    }

    function test_transfer_index_selector() pure external returns(bytes4) {
        return this.test_transfer_index.selector;
    }

    function test_transfer_energy_amount_selector() pure external returns(bytes4) {
        return this.test_transfer_energy_amount.selector;
    }

    function test_transfer_token_amount_selector() pure external returns(bytes4) {
        return this.test_transfer_token_amount.selector;
    }

    function test_transfer_proof_selector() pure external returns(bytes4) {
        return this.test_transfer_proof.selector;
    }

    function test_tree_pub_selector() pure external returns(bytes4) {
        return this.test_tree_pub.selector;
    }

    function test_tree_root_after_selector() pure external returns(bytes4) {
        return this.test_tree_root_after.selector;
    }

    function test_tree_proof_selector() pure external returns(bytes4) {
        return this.test_tree_proof.selector;
    }

    function test_tx_type_selector() pure external returns(bytes4) {
        return this.test_tx_type.selector;
    }

    function test_memo_size_selector() pure external returns(bytes4) {
        return this.test_memo_size.selector;
    }

    function test_memo_hash_selector() pure external returns(bytes4) {
        return this.test_memo_hash.selector;
    }

    function test_memo_message_selector() pure external returns(bytes4) {
        return this.test_memo_message.selector;
    }

    function test_memo_fee_selector() pure external returns(bytes4) {
        return this.test_memo_fee.selector;
    }

    function test_memo_native_amount_selector() pure external returns(bytes4) {
        return this.test_memo_native_amount.selector;
    }

    function test_memo_receiver_selector() pure external returns(bytes4) {
        return this.test_memo_receiver.selector;
    }

    function test_deposit_spender_selector() pure external returns(bytes4) {
        return this.test_deposit_spender.selector;
    }

    fallback() external payable {
        revert("fallback not supported");
    }
}