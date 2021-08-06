const Pool = artifacts.require("Pool");
const OperatorManagerMock = artifacts.require("OperatorManagerMock");
const TransferVerifierMock = artifacts.require("TransferVerifierMock");
const TreeVerifierMock = artifacts.require("TreeVerifierMock");
const Token = artifacts.require("ERC20Mock");

module.exports = async function(deployer) {
    await deployer.deploy(OperatorManagerMock);
    await deployer.deploy(TransferVerifierMock);
    await deployer.deploy(TreeVerifierMock);

    await deployer.deploy(Token, "Test Token", "TEST1");
    await Token.deployed();
    const testTokenAddress = Token.address;
    await deployer.deploy(Token, "Voucher Token", "TEST2");
    await Token.deployed();
    const voucherTokenAddress = Token.address;
    
    await OperatorManagerMock.deployed();
    await TransferVerifierMock.deployed();
    await TreeVerifierMock.deployed();

    await deployer.deploy(Pool, testTokenAddress, voucherTokenAddress, "1000000000", "1000000000", "1000000000", 
        TransferVerifierMock.address, TreeVerifierMock.address, OperatorManagerMock.address, 0);
    
    await Pool.deployed();
}
