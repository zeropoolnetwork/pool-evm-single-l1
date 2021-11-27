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
  networks: {
    hardhat: {
      accounts: {
        mnemonic: process.env.MNEMONIC,
        count: 3,
      }
    },
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
    ganache: {
      url: 'http://127.0.0.1:8545/',
      accounts: {
        mnemonic: process.env.MNEMONIC,
        count: 3
      },
    },
    docker: {
      url: "http://ganache:8545",
    }
  }
};

