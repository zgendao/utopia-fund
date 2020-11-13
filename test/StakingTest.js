const stakingContract = artifacts.require("Staking");
const tokenContract = artifacts.require("StakingToken");

contract("StakingToken", (accounts) => {
    let tokenInstance;
    before("before", async () => 
        tokenInstance = await tokenContract.new("StakingToken", "STK"));
    it("should be able to mint STK to an address with minter role", async () => {
        const result = await tokenInstance.mint(accounts[1], 12, { from: accounts[0] });
        let balance = await tokenInstance.balanceOf(accounts[1]);
        assert.equal(result.receipt.status, true);
        assert.equal(balance.toString(), "12");
    });
    it("should fail to mint STK to an address without minter role", async () => {
        try {
            await tokenInstance.mint(accounts[1], 10, { from: accounts[2] });
            throw null;
        } catch (error) {
            assert(error, "expected an error but did not get one");
        }
        let balance = await tokenInstance.balanceOf(accounts[1]);
        assert.equal(balance.toString(), "12");
    });
    it("should be able to burn STK from an address", async () => {
        const result = await tokenInstance.burn(accounts[1], 8);
        let balance = await tokenInstance.balanceOf(accounts[1]);
        assert.equal(result.receipt.status, true);
        assert.equal(balance.toString(), "4");
    });
});

contract("Staking", (accounts) => {
    let stakingContractInstance;
    before("before", async () => {
        stakingContractInstance = await stakingContract.new("StakingToken", "STK");
    });
    context("using STK tokens", async () => {
        it("is called StakingToken", async () => {
            assert.equal(await stakingContractInstance.name(), "StakingToken");
        });
        it("has symbol STK", async () => {
            assert.equal(await stakingContractInstance.symbol(), "STK");
        });
        it("should be able to create STK stakes", async () => {
            await stakingContractInstance.mint(accounts[1], 12000);
            const result = await stakingContractInstance.createStkStake(9000, {from: accounts[1]});
            let stake = await stakingContractInstance.getStkStakeOf(accounts[1]);
            let balance = await stakingContractInstance.balanceOf(accounts[1]);
            assert.equal(result.receipt.status, true);
            assert.equal(stake.toString(), "9000");
            assert.equal(balance.toString(), "3000");
        });
        it("should be able to create more STK stakes", async () => {
            await stakingContractInstance.mint(accounts[3], 12000);
            const result = await stakingContractInstance.createStkStake(7000, {from: accounts[3]});
            let stake = await stakingContractInstance.getStkStakeOf(accounts[3]);
            let balance = await stakingContractInstance.balanceOf(accounts[3]);
            assert.equal(result.receipt.status, true);
            assert.equal(stake.toString(), "7000");
            assert.equal(balance.toString(), "5000");
        });
        it("should have rewarded the first stakeholder", async () => {
            let balance1 = await stakingContractInstance.balanceOf(accounts[1]);
            assert.equal(balance1.toString(), "3090");
            let balance3 = await stakingContractInstance.balanceOf(accounts[3]);
            assert.equal(balance3.toString(), "5000");
        });
        it("should know if someone is a stakeholder", async () => {
            const result = await stakingContractInstance.isStakeholder(accounts[1]);
            assert.equal(result[0], true);
            assert.equal(result[1], 0);
        });
        it("should know if someone is not a stakeholder", async () => {
            const result = await stakingContractInstance.isStakeholder(accounts[0]);
            assert.equal(result[0], false);
            assert.equal(result[1], 2**256 - 1);
        });
        it("should return the list of stakeholders", async () => {
            const stakeholders = await stakingContractInstance.getStakeholders();
            assert.equal(stakeholders.length, 2);
            assert.equal(stakeholders[0], accounts[1]);
            assert.equal(stakeholders[1], accounts[3]);
        });
        it("should calculate the total stakes", async () => {
            const allStakes = await stakingContractInstance.getAllStakes();
            assert.equal(allStakes[0].toString(), "0");
            assert.equal(allStakes[1].toString(), "16000");
        });
        it("should be able to return the contracts STK balance", async () => {
            const balance = await stakingContractInstance.getStkBalance();
            assert.equal(Number(balance.toString()), 1000 * 10 ** 18);
        });
        it("should be able to remove STK stakes", async () => {
            const result = await stakingContractInstance.removeStkStake(9000, {from: accounts[1]});
            let stake = await stakingContractInstance.getStkStakeOf(accounts[1]);
            let balance = await stakingContractInstance.balanceOf(accounts[1]);
            assert.equal(result.receipt.status, true);
            assert.equal(stake.toString(), "0");
            assert.equal(balance.toString(), "12090");
        });
        it("should have removed one account from the list of stakeholders", async () => {
            const stakeholders = await stakingContractInstance.getStakeholders();
            assert.equal(stakeholders.length, 1);
            assert.equal(stakeholders[0], accounts[3]);
        });
    });
    context("using ETH tokens", async () => {
        it("should be able to create ETH stakes", async () => {
            const result = await stakingContractInstance.createEthStake(6 * 10 ** 15, {from: accounts[2], value: 6 * 10 ** 15});
            let stake = await stakingContractInstance.getEthStakeOf(accounts[2]);
            let balance = await web3.eth.getBalance(accounts[2]);
            assert.equal(result.receipt.status, true);
            assert.equal(Number(stake.toString()), 6 * 10 ** 15);
            assert.isBelow(Number(balance.toString()), 9.9994 * 10 ** 19);
        });
        it("should be able to create ETH stakes even if the address has an STK stake", async () => {
            const result = await stakingContractInstance.createEthStake(8 * 10 ** 15, {from: accounts[3], value: 8 * 10 ** 15});
            let stake = await stakingContractInstance.getEthStakeOf(accounts[3]);
            let balance = await web3.eth.getBalance(accounts[3]);
            assert.equal(result.receipt.status, true);
            assert.equal(Number(stake.toString()), 8 * 10 ** 15);
            assert.isBelow(Number(balance.toString()), 9.9992 * 10 ** 19);
        });
        it("should know if someone is a stakeholder", async () => {
            const result = await stakingContractInstance.isStakeholder(accounts[2]);
            assert.equal(result[0], true);
            assert.equal(result[1], 1);
        });
        it("should know if someone is not a stakeholder", async () => {
            const result = await stakingContractInstance.isStakeholder(accounts[0]);
            assert.equal(result[0], false);
            assert.equal(result[1], 2**256 - 1);
        });
        it("should return the list of stakeholders", async () => {
            const stakeholders = await stakingContractInstance.getStakeholders();
            assert.equal(stakeholders.length, 2);
            assert.equal(stakeholders[1], accounts[2]);
        });
        it("should calculate the total stakes", async () => {
            const allStakes = await stakingContractInstance.getAllStakes();
            assert.equal(allStakes[0].toString(), 14 * 10 ** 15);
            assert.equal(allStakes[1].toString(), "7000");
        });
        it("should be able to return the contracts ETH balance", async () => {
            const balance = await stakingContractInstance.getEthBalance();
            assert.equal(Number(balance.toString()), 14 * 10 ** 15);
        });
        it("should be able to remove ETH stakes", async () => {
            const result = await stakingContractInstance.removeEthStake(5 * 10 ** 15, {from: accounts[2]});
            let stake = await stakingContractInstance.getEthStakeOf(accounts[2]);
            let balance = await web3.eth.getBalance(accounts[2]);
            assert.equal(result.receipt.status, true);
            assert.equal(Number(stake.toString()), 1 * 10 ** 15);
            assert.isBelow(Number(balance.toString()), 9.9999 * 10 ** 19);
            assert.isAbove(Number(balance.toString()), 9.9996 * 10 ** 19);
        });
    });
});