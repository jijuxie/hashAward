const HashAward = artifacts.require("HashAward");

contract('HashAward', (accounts) => {
  it('should ', async () => {
    const HashAwardInstance = await HashAward.deployed();
    // const balance = await metaCoinInstance.getBalance.call(accounts[0]);
    //
    // assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
  });
});
