const fs = require('fs');
const { ethers } = require('hardhat');
const { getContractAddress } = require('@ethersproject/address')

require('dotenv').config()

async function deploy() {
  const [deployer, proxyAdmin, relayer] = await ethers.getSigners();
  let nonce = await deployer.getTransactionCount();

  const Pool = await ethers.getContractFactory("Pool");
  const SimpleOperatorManager = await ethers.getContractFactory("SimpleOperatorManager");
  const MintableToken = await ethers.getContractFactory("MintableToken");
  const ZeroPoolProxy = await ethers.getContractFactory("ZeroPoolProxy");
  
  const TransferVerifier = await ethers.getContractFactory(
    process.env.MOCK_TX_VERIFIER === "true" ?
    "TransferVerifierMock" :
    "TransferVerifier"
  );
  const TreeVerifier = await ethers.getContractFactory(
    process.env.MOCK_TREE_VERIFIER === "true" ?
    "TreeUpdateVerifierMock" :
    "TreeUpdateVerifier"
  );



  const simpleOperatorManager = await SimpleOperatorManager.deploy(relayer.address, {nonce: nonce++});
  await simpleOperatorManager.deployed();
  const transferVerifier = await TransferVerifier.deploy({nonce: nonce++});
  await transferVerifier.deployed();
  const treeVerifier = await TreeVerifier.deploy({nonce: nonce++});
  await treeVerifier.deployed();

  const poolId = "0";
  let tokenAddress, voucherTokenAddress, poolAddress, poolProxyAddress;



  let deploy_tokens = async () => {};
  
  let custom_token_nonce = nonce+2;

  if (process.env.TOKEN_ADDRESS) {
    tokenAddress = process.env.TOKEN_ADDRESS;
  } else {
    deploy_tokens = ((prev) => async () => {
      await prev();
      const token = await MintableToken.deploy("Token", "TOKEN", "0x0000000000000000000000000000000000000000", {nonce: nonce++});
      await token.deployed();
      console.log(`Token deployed at ${token.address}`);
    })(deploy_tokens);


    tokenAddress = getContractAddress({
      from: deployer.address,
      nonce: custom_token_nonce
    })
    custom_token_nonce+=1;
  }

  if (process.env.VOUCHER_TOKEN_ADDRESS) {
    voucherTokenAddress = process.env.VOUCHER_TOKEN_ADDRESS;
  } else {
    deploy_tokens = ((prev) => async () => {
      await prev();
      const voucherToken = await MintableToken.deploy("Voucher Token", "VOUCHER", poolProxyAddress, {nonce: nonce++});
      await voucherToken.deployed();
      console.log(`Voucher token deployed at ${voucherToken.address}`);
    })(deploy_tokens);

    voucherTokenAddress = getContractAddress({
      from: deployer.address,
      nonce: custom_token_nonce
    })
  }

  const initialRoot = "11469701942666298368112882412133877458305516134926649826543144744382391691533"
  const pool = await Pool.deploy(poolId, tokenAddress, voucherTokenAddress, "1000000000", "1000000000", "1000000000", 
      transferVerifier.address, treeVerifier.address, simpleOperatorManager.address, initialRoot, {nonce: nonce++});

  await pool.deployed();
  console.log(`Pool implementation deployed at ${pool.address}`);
  poolAddress = pool.address;

  const zeroPoolProxy = await ZeroPoolProxy.deploy(poolAddress, proxyAdmin.address, "0x8129fc1c", {nonce: nonce++});
  await zeroPoolProxy.deployed();
  console.log(`Pool proxy deployed at ${zeroPoolProxy.address}`);
  poolProxyAddress = zeroPoolProxy.address;

  await deploy_tokens();

  const poolProxified = new ethers.Contract(zeroPoolProxy.address, Pool.interface, relayer);

  const data = JSON.stringify({ proxy: zeroPoolProxy.address, pool: pool.address, token: tokenAddress, voucher: voucherTokenAddress });
  fs.writeFileSync('addresses.json', data);


  return {
    pool:poolProxified,
    Pool
  };
}

module.exports = deploy;
