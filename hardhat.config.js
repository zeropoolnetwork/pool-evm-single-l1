require("@nomiclabs/hardhat-waffle");

require('dotenv').config()



// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const localDevnets = {
  hardhat: {
    accounts: [
      // crazy appear raise time fashion kind pattern crazy device split escape wolf
      {
        privateKey: "0x69914f67c6c8c8dcd1e265e440aaba288ba5a60d3fef274a7f31d97f5a57d1e2",
        balance: "1000000000000000000000"
      },
      {
        privateKey: "0xa4e24fa2fc0c66e22190ec939a3a034874d1f677c56b65608c649c0f8cb38b98",
        balance: "1000000000000000000000"
      },
      {
        privateKey: "0x66e837b617d2049c65c6220a2b86cf45830f4ccaf5a1cd1e1a8f95d61c19397e",
        balance: "1000000000000000000000"
      },
      {
        privateKey: "0xa0d3a779bf33f01e1f7fddfa8c2b1e2cafb7082a51c2f88a73525475f7dfa72b",
        balance: "1000000000000000000000"
      },
      // test test test test test test test test test test test junk
      {
        privateKey: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
        balance: "1000000000000000000000"
      },
      {
        privateKey: "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
        balance: "1000000000000000000000"
      },
      {
        privateKey: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
        balance: "1000000000000000000000"
      },
      {
        privateKey: "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
        balance: "1000000000000000000000"
      }
    ]
  },
  localhost: {
    url: 'http://127.0.0.1:8545/'
  },
  docker: {
    url: "http://ganache:8545",
  }
};


const networks = typeof process.env.MNEMONIC === 'undefined' ? {} : {
  xdai_testnet: {
    url: 'http://104.200.30.151:8545/',
    accounts: {
      mnemonic: process.env.MNEMONIC,
      count: 3
    },
    chainId: 0x66
  },
  sokol: {
    url: 'https://sokol.poa.network/',
    accounts: {
      mnemonic: process.env.MNEMONIC,
      count: 3
    },
    chainId: 77
  },
  aurora_testnet: {
    url: 'https://testnet.aurora.dev/',
    accounts: {
      mnemonic: process.env.MNEMONIC,
      count: 3
    },
    chainId: 1313161555
  },
  kovan: {
    url: 'https://kovan.poa.network/',
    accounts: {
      mnemonic: process.env.MNEMONIC,
      count: 3
    },
    chainId: 42
  }
};


module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.6.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ]
  },
  networks: { ...localDevnets, ...networks },
};

