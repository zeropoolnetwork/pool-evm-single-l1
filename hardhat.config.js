const ethers = require('ethers');
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

function genAccounts(seedPhrase, n = 5) {
  const accounts = [];
  const parentPath = "m/44'/60'/0'/0";
  for (let i = 0; i < n; i++) {
    const path = parentPath + `/${i}`;
    const wallet = ethers.Wallet.fromMnemonic(seedPhrase, path);
    accounts.push({
      privateKey: wallet.privateKey,
      balance: "1000000000000000000000",
    });
  }

  return accounts;
}

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const numAccounts = parseInt(process.env.NUM_ACCOUNTS || '1000');

const localDevnets = {
  hardhat: {
    accounts: [
      ...genAccounts('crazy appear raise time fashion kind pattern crazy device split escape wolf', 5),
      ...genAccounts('test test test test test test test test test test test junk', numAccounts),
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

