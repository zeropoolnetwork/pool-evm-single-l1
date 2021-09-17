//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract Parameters {
    uint256 constant Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    bytes32 constant S_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function dataload(uint256 from, uint256 n) pure internal returns (bytes memory r) {
        r = new bytes(n);
        assembly {
            calldatacopy(add(r, 32), from, n)
        }
    }

    function transfer_pub(uint256 root) pure internal returns (uint256[5] memory r) {
        r[0] = root;
        r[1] = transfer_nullifier();
        r[2] = transfer_out_commit();
        uint256 t;
        assembly {
            t:=calldataload(58)
        }
        r[3] = t & 0xffffffffffffffffffffffffffffffffffffffffffff;
        r[4] = memo_hash();
    }

    // struct TransferPub {
    //     uint256 root;            // --skip
    //     uint256 nullifier;       // 4           
    //     uint256 out_commit;      // 36
    //     uint48 index;            // 42
    //     int64 energy_amount;     // 50
    //     int64 token_amount;      // 58
    //     uint256 memo;            // --skip
    // }


    function transfer_nullifier() pure internal returns(uint256 r) {
        assembly {
            r:=calldataload(4)
        }
    }

    function transfer_out_commit() pure internal returns(uint256 r) {
        assembly {
            r:=calldataload(36)
        }
    }

    function transfer_index() pure internal returns(uint48 r) {
        uint256 t;
        assembly {
            t:=calldataload(42)
        }
        r = uint48(t);
    }

    function transfer_energy_amount() pure internal returns(int256 r) {
        uint256 t;
        assembly {
            t:=calldataload(50)
        }
        r = int256(int64(uint64(t)));
    } 

    function transfer_token_amount() pure internal returns(int256 r) {
        uint256 t;
        assembly {
            t:=calldataload(58)
        }
        r = int256(int64(uint64(t)));
    }


    function transfer_proof() pure internal returns (uint256[8] memory r) {
        assembly {
            calldatacopy(r, 90, 256)
        }
    }


    function tree_pub(uint256 root_before) pure internal returns (uint256[3] memory r) {
        r[0] = root_before;
        r[1] = tree_root_after();
        r[2] = transfer_out_commit();
    }

    // struct TreePub {
    //     uint256 root_before,  --- skip
    //     uint256 root_after,   // 352
    //     uint256 leaf          --- skip
    // }


    function tree_root_after() pure internal returns(uint256 r) {
        assembly {
            r:=calldataload(346)
        }
    }


    function tree_proof() pure internal returns (uint256[8] memory r) {
        assembly {
            calldatacopy(r, 378, 256)
        }
    }

    function tx_type() pure internal returns(uint256 r) {
        r = uint256(uint8(msg.data[634]));
    }

    function memo_size() pure internal returns(uint256 r) {
        uint256 t;
        assembly {
            t:= calldataload(605)
        }
        r = t & 0xffff;
    }

    function memo_hash() pure internal returns (uint256 r) {
        r = uint256(keccak256(dataload(637, memo_size()))) % Q;
    }

    function memo_message() pure internal returns (bytes memory r) {
        uint256 t = tx_type();
        uint256 fixed_size;
        if ( t ==0 || t == 1) {
            fixed_size = 8;
        } else if (t==2) { 
            fixed_size = 36;
        } else revert();    
        r = dataload(637+fixed_size, memo_size()-fixed_size);
    }
    

    function memo_fee() pure internal returns (uint256 r) {
        assembly {
            r := calldataload(613)
        }
        r &= 0xffffffffffffffff;
    }

    function memo_native_amount() pure internal returns (uint256 r) {
        assembly {
            r := calldataload(621)
        }
        r &= 0xffffffffffffffff;
    }

    function memo_receiver() pure internal returns (address r) {
        uint256 t;
        assembly {
            t := calldataload(641)
        }
        r = address(uint160(t));
    }


    function deposit_spender() pure internal returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint t = 643 + memo_size();
        assembly {
            r := calldataload(t)
            s := calldataload(add(t, 32))
        }
        v = 27 + uint8(uint256(s)>>255);
        s = s & S_MASK;
        return ecrecover(bytes32(transfer_out_commit()), v, r, s);
    }
}
