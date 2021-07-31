const { expect } = require("chai");
const { ethers } = require("hardhat");
const rand_bigint = require('random-bigint');

const Q_BITS = 256;
const Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583n;

function rand_bigint_hex(n) {
    const x = rand_bigint(n*8);
    const data = x.toString(16);
    return "0".repeat(2*n - data.length) + data;
}

function rand_fr_hex() {
    const x = rand_bigint(256) % Q;
    const data = x.toString(16);
    return "0".repeat(64 - data.length) + data;
}

function rand_fr_hex_list(n) {
    let a = [];
    for (let i = 0; i < n; i++) {
        a.push(rand_fr_hex());
    }
    return a.join("");
}



describe("Pool", async function() {
    it("Should perform transaction", async function () {
        const [owner] = await ethers.getSigners();

        const Pool = await ethers.getContractFactory("Pool");
        const OperatorManagerMock = await ethers.getContractFactory("OperatorManagerMock");
        const TransferVerifierMock = await ethers.getContractFactory("TransferVerifierMock");
        const TreeVerifierMock = await ethers.getContractFactory("TreeVerifierMock");
        const Token = await ethers.getContractFactory("ERC20Mock");

        const operatorManagerMock = await OperatorManagerMock.deploy();
        const transferVerifierMock = await TransferVerifierMock.deploy();
        const treeVerifierMock = await TreeVerifierMock.deploy();
        const testToken = await Token.deploy("Test Token", "TEST1");
        const voucherToken = await Token.deploy("Voucher Token", "TEST2");
        

        await operatorManagerMock.deployed();
        await transferVerifierMock.deployed();
        await treeVerifierMock.deployed();
        await testToken.deployed();
        await voucherToken.deployed();


        

        const pool = await Pool.deploy(testToken.address, voucherToken.address, "1000000000", "1000000000", "1000000000", 
            transferVerifierMock.address, treeVerifierMock.address, operatorManagerMock.address, 0);
        
        await pool.deployed();



        // inputs sample data

        const selector = Pool.interface.getSighash("transact");
        const sample_nullifier =  rand_fr_hex();
        const sample_out_commit = rand_fr_hex();
        const sample_transfer_index = "000000000000";
        const sample_enery_amount = "0000000000000000000000000000";
        const sample_token_amount = "0000000000000000";
        const sample_transact_proof = rand_fr_hex_list(8);
        const sample_root_after = rand_fr_hex();
        const sample_tree_proof = rand_fr_hex_list(8);
        const sample_tx_type = "01"; // transaction
        const sample_memo_size = "30"; // memo block size
        const sample_memo_fee = "0000000000000000"; // here is smart contract level metadata, only fee for 01 type
        const sample_memo_message = rand_bigint_hex(parseInt(sample_memo_size, 16)-sample_memo_fee.length/2); //here is encrypted tx metadata, used on client only
        




        data = [
            selector, sample_nullifier, sample_out_commit, sample_transfer_index, sample_enery_amount, sample_token_amount, sample_transact_proof,
            sample_root_after, sample_tree_proof,
            sample_tx_type,
            sample_memo_size, sample_memo_fee, sample_memo_message
        ].join("");


        await owner.sendTransaction({
            from: owner.address,
            to: pool.address,
            data
        });


    });

});
