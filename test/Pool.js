const { expect } = require("chai");
const { ethers } = require("hardhat");
const rand_bigint = require('random-bigint');
const deploy = require("../scripts/deploy")

const R = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;

function rand_bigint_hex(n) {
    const x = rand_bigint(n*8);
    const data = x.toString(16);
    return "0".repeat(2*n - data.length) + data;
}

function rand_fr_hex() {
    const x = rand_bigint(256) % R;
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

function bigint_to_n_byte_hex(x, n) {
    const data = BigInt(x).toString(16);
    return "0x"+ "0".repeat(2*n - data.length) + data;
}

process.env["MOCK_TX_VERIFIER"] = "true";
process.env["MOCK_TREE_VERIFIER"] = "true";
process.env["MOCK_DELEGATED_DEPOSIT_VERIFIER"] = "true";


describe("Pool", async function() {
    it("Should perform transaction", async function () {
        const [,, relayer] = await ethers.getSigners();

        const { pool, Pool } = await deploy();

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
        const sample_tx_type = "0001"; // transaction
        const sample_memo_size = "0030"; // memo block size
        const sample_memo_fee = "0000000000000000"; // here is smart contract level metadata, only fee for 01 type
        const sample_memo_message = rand_bigint_hex(parseInt(sample_memo_size, 16)-sample_memo_fee.length/2); //here is encrypted tx metadata, used on client only

        data = [
            selector, sample_nullifier, sample_out_commit, sample_transfer_index, sample_enery_amount, sample_token_amount, sample_transact_proof,
            sample_root_after, sample_tree_proof,
            sample_tx_type,
            sample_memo_size, sample_memo_fee, sample_memo_message
        ].join("");


        await relayer.sendTransaction({
            from: relayer.address,
            to: pool.address,
            data
        });


    });

    it("Should perform delegated deposit", async function () {
        const N_DEPOSITS = 10;
        const [deployer,, relayer, user] = await ethers.getSigners();
        const DepositCreate = new ethers.utils.Interface(["event DepositCreate(uint64 indexed id, address indexed owner, bytes10 receiver_d, bytes32 receiver_p, uint64 denominated_amount, uint64 denominated_fee, uint64 expired)"]);
        

        const { pool, Pool} = await deploy();
        const provider = pool.provider;

        const MintableToken = await ethers.getContractFactory("MintableToken");
        const DelegatedDepositStorage = await ethers.getContractFactory("DelegatedDepositStorage");

        
        const token = MintableToken.attach(await pool.token());
        const delegatedDepositStorage = DelegatedDepositStorage.attach(await pool.dds());

        await token.connect(deployer).mint(user.address, ethers.utils.parseEther("1000"));
        await token.connect(user).approve(delegatedDepositStorage.address, ethers.utils.parseEther("1000"));

        let makeRandomDeposit = async () => {
            const receiver_d = "0x"+rand_bigint_hex(10);
            const receiver_p = "0x"+rand_fr_hex();
            const amount = ethers.utils.parseEther("10");
            const fee = ethers.utils.parseEther("0.1");

            let tx = await delegatedDepositStorage.connect(user).deposit(receiver_d, receiver_p, amount, fee);
            let receipt = await provider.getTransactionReceipt(tx.hash);
            let args = DepositCreate.parseLog(receipt.logs[0]).args;

            let deposit = {
              id: bigint_to_n_byte_hex(args.id, 8),
              owner: args.owner,
              receiver_d: args.receiver_d,
              receiver_p: args.receiver_p,
              denominated_amount: bigint_to_n_byte_hex(args.denominated_amount, 8),
              denominated_fee: bigint_to_n_byte_hex(args.denominated_fee, 8),
              expired: bigint_to_n_byte_hex(args.expired, 8)
            };

            let flatten = "0x"+deposit.id.substring(2) + 
                deposit.owner.substring(2) + 
                deposit.receiver_d.substring(2) + 
                deposit.receiver_p.substring(2) + 
                deposit.denominated_amount.substring(2) + 
                deposit.denominated_fee.substring(2) + 
                deposit.expired.substring(2);

            deposit.flatten = flatten;
            return deposit;

        }

        let deposits = [];

        for (let i = 0; i < N_DEPOSITS; i++) {
            deposits.push(await makeRandomDeposit());
        }

        let fee = 0n;
        let transfer_token_amount = 0n;
        let sample_memo_message = "ffffffff"+rand_fr_hex();

        for (let i = 0; i < N_DEPOSITS; i++) {
            fee += BigInt(deposits[i].denominated_fee);
            transfer_token_amount += BigInt(deposits[i].denominated_amount);
            sample_memo_message += deposits[i].flatten.substring(2);
        }

        


        const selector = Pool.interface.getSighash("transact");
        const sample_nullifier =  rand_fr_hex();
        const sample_out_commit = rand_fr_hex();
        const sample_transfer_index = "000000000000";
        const sample_enery_amount = "0000000000000000000000000000";
        const sample_token_amount = bigint_to_n_byte_hex(transfer_token_amount, 8).substring(2);
        const sample_transact_proof = rand_fr_hex_list(8);
        const sample_root_after = rand_fr_hex();
        const sample_tree_proof = rand_fr_hex_list(8);
        const sample_tx_type = "0004"; // delegated deposit
        const sample_memo_size = bigint_to_n_byte_hex(sample_memo_message.length/2+256+8, 2).substring(2); // memo block size
        const sample_memo_fee = bigint_to_n_byte_hex(fee, 8).substring(2);
        const sample_memo_delegated_deposit_proof = rand_fr_hex_list(8);


        data = [
            selector, sample_nullifier, sample_out_commit, sample_transfer_index, sample_enery_amount, sample_token_amount, sample_transact_proof,
            sample_root_after, sample_tree_proof,
            sample_tx_type,
            sample_memo_size, sample_memo_fee, sample_memo_delegated_deposit_proof, sample_memo_message
        ].join("");

        console.log(pool.address, await delegatedDepositStorage.pool());

        await relayer.sendTransaction({
            from: relayer.address,
            to: pool.address,
            data
        });


        

    });

});
