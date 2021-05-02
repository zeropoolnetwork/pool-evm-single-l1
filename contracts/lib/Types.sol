// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;


library TransferPub {
    // struct TransferPub {
    //     uint256 root;            // 0
    //     uint256 nullifier;       // 32           
    //     uint256 out_commit;      // 64
    //     uint32 txnumber;         // 68
    //     int96 energy_delta;      // 80
    //     int64 token_delta;       // 88
    //     uint256 memo;            // 120
    // }

    function root(byte[152] memory data) pure internal returns(uint256) {
        uint256 res;
        assembly {
            res := mload(data)
        }
        return res;
    }

    function nullifier(byte[152] memory data) pure internal returns(uint256) {
        uint256 res;
        assembly {
            res := mload(add(data, 32))
        }
        return res;
    }

    function out_commit(byte[152] memory data) pure internal returns(uint256) {
        uint256 res;
        assembly {
            res := mload(add(data, 64))
        }
        return res;
    }

    function txnumber(byte[152] memory data) pure internal returns(uint32) {
        uint256 res;
        assembly {
            res := mload(add(data, 68))
        }
        return uint32(res);
    }

    function energy_delta(byte[152] memory data) pure internal returns(int96) {
        uint256 res;
        assembly {
            res := mload(add(data, 80))
        }
        return int96(uint96(res));
    } 

    function token_delta(byte[152] memory data) pure internal returns(int64) {
        uint256 res;
        assembly {
            res := mload(add(data, 88))
        }
        return int64(uint64(res));
    }


    function delta(byte[152] memory data) pure internal returns(uint256) {
        uint256 res;
        assembly {
            res := mload(add(data, 88))
        }
        return res&0xffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function memo(byte[152] memory data) pure internal returns(uint256) {
        uint256 res;
        assembly {
            res := mload(add(data, 120))
        }
        return res;
    }

    function toInputs(byte[152] memory data) internal pure returns(uint[] memory) {
        uint256[] memory inputs = new uint[](5);
        inputs[0] = root(data);
        inputs[1] = nullifier(data);
        inputs[2] = out_commit(data);
        inputs[3] = delta(data); 
        inputs[4] = memo(data);
        return inputs;
    }    

}

library WithdrawData {
// struct WithdrawData {
//     int64 fee;              // -24
//     address receiver;       // -4 
//     uint256 native_amount;  // 28
// }

    function fee(byte[60] memory data) pure internal returns(int64) {
        uint256 res;
        assembly {
            res := mload(sub(data, 24))
        }
        return int64(uint64(res));
    }

    function receiver(byte[60] memory data) pure internal returns(address) {
        uint256 res;
        assembly {
            res := mload(sub(data, 4))
        }
        return address(uint160(res));
    }

    function native_amount(byte[60] memory data) pure internal returns(uint256) {
        uint256 res;
        assembly {
            res := mload(add(data, 28))
        }
        return res;  
    }
}

library TransferData {
// struct TransferData {
//     int64 fee;              // -24
// }
    function fee(byte[4] memory data) pure internal returns(int64) {
        uint256 res;
        assembly {
            res := mload(sub(data, 24))
        }
        return int64(uint64(res));
    }
}