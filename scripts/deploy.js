const fs = require('fs');

require('dotenv').config()

async function deploy() {
  const Pool = await ethers.getContractFactory("Pool");
  const OperatorManagerMock = await ethers.getContractFactory("OperatorManagerMock");
  const TransferVerifier = await ethers.getContractFactory(
    process.env.MOCK_TX_VERIFIER === "false" ?
    "TransferVerifier" :
    "TransferVerifierMock"
  );
  const TreeVerifier = await ethers.getContractFactory(
    process.env.MOCK_TREE_VERIFIER === "false" ?
    "TreeVerifier" :
    "TreeVerifierMock"
  );
  const Token = await ethers.getContractFactory("ERC20Mock");

  const operatorManagerMock = await OperatorManagerMock.deploy();
  const transferVerifier = await TransferVerifier.deploy();
  const treeVerifier = await TreeVerifier.deploy();
  const testToken = await Token.deploy("Test Token", "TEST1");
  const voucherToken = await Token.deploy("Voucher Token", "TEST2");
  const poolId = "0";
  
  await operatorManagerMock.deployed();
  await transferVerifier.deployed();
  await treeVerifier.deployed();
  await testToken.deployed();
  await voucherToken.deployed();

  const initialRoot = "11469701942666298368112882412133877458305516134926649826543144744382391691533"
  const pool = await Pool.deploy(poolId, testToken.address, voucherToken.address, "1000000000", "1000000000", "1000000000", 
      transferVerifier.address, treeVerifier.address, operatorManagerMock.address, initialRoot);

  await pool.deployed();


  const data = JSON.stringify({ pool: pool.address, token: testToken.address });
  //fs.writeFileSync('addresses.json', data);

  return {
    pool,
    Pool,
  };
}

module.exports = deploy;
