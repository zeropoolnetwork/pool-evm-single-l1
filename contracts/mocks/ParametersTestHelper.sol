//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../Parameters.sol";

contract ParametersTestHelper is Parameters {
    uint256 public test_parameter;

    function _root() view internal virtual override returns(uint256) {
        return test_parameter;
    }
    function _root_before() view internal virtual override returns(uint256) {
        return test_parameter;
    }
    
    function set_test_parameter(uint256 t) external {
        test_parameter = t;
    }


    function test_transfer_pub() view external returns (uint256[5] memory r) {
        r = _transfer_pub();
    }
    
    function test_transfer_nullifier() pure external returns(uint256 r) {
        r = _transfer_nullifier();
    }

    function test_transfer_out_commit() pure external returns(uint256 r) {
        r = _transfer_out_commit();
    }

    function test_transfer_index() pure external returns(uint48 r) {
        r = _transfer_index();
    }

    function test_transfer_energy_amount() pure external returns(int256 r) {
        r = _transfer_energy_amount();
    } 

    function test_transfer_token_amount() pure external returns(int256 r) {
        r = _transfer_token_amount();
    }


    function test_transfer_proof() pure external returns (uint256[8] memory r) {
        r = _transfer_proof();
    }


    function test_tree_pub() view external returns (uint256[3] memory r) {
        r = _tree_pub();
    }


    function test_tree_root_after() pure external returns(uint256 r) {
        r = _tree_root_after();
    }


    function test_tree_proof() pure external returns (uint256[8] memory r) {
        r = _tree_proof();
    }

    function test_tx_type() pure external returns(uint256 r) {
        r = _tx_type();
    }

    function test_memo_data_size() pure external returns(uint256 r) {
        r = _memo_data_size();
    }

    function test_memo_message() pure external returns (bytes memory r) {
        r = _memo_message();
    }
    

    function test_memo_fee() pure external returns (uint256 r) {
        r = _memo_fee();
    }

    function test_memo_native_amount() pure external returns (uint256 r) {
        r = _memo_native_amount();
    }

    function test_memo_receiver() pure external returns (address r) {
        r = _memo_receiver();
    }


    function test_deposit_spender() pure external returns (address r) {
        r = _deposit_spender();
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
        return this.test_memo_data_size.selector;
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
    
    fallback() external {
        revert("wrong selector used");
    }


}