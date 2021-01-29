
    var contract;
    //this needs to be updated after deployement of Vault
    const cakeVaultAddress = "0x0";
    const cakeAddress = "0x0";
    const yCakeAddress = "0x0";
    const maxValue = BigInt(115792089237316195423570985008687907853269984665640564039457584007913129639935);

    //contract functions
    async function cakeApprove() {
      contract = new web3.eth.Contract(BEP20Abi, cakeAddress);
      let userAccount = await web3.eth.getAccounts();
      await contract.methods.approve(cakeVaultAddress, maxValue).send( {from : userAccount[0], gas: 500000} )
    }

    async function yCakeApprove() {
      contract = new web3.eth.Contract(BEP20Abi, yCakeAddress);
      let userAccount = await web3.eth.getAccounts();
      await contract.methods.approve(cakeVaultAddress, maxValue).send( {from : userAccount[0], gas: 500000} )
    }
    
    async function stake() {
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let userAccount = await web3.eth.getAccounts();
      let stakeAmount = document.getElementById("stakeAmount").value;
      await contract.methods.deposit(stakeAmount).send( {from : userAccount[0], gas: 500000} )
    }

    async function withdraw() {
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let userAccount = await web3.eth.getAccounts();
      let withdrawAmount = document.getElementById("withdrawAmount").value;
      await contract.methods.withdraw(withdrawAmount).send( {from : userAccount[0], gas: 500000} )
    }

    async function getBalance() {
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let balance = await contract.methods.getBalance().call();
	    return balance;
    }

    async function getBalanceOf() {
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let userAccount = await web3.eth.getAccounts();
      let yCake = await contract.methods.getBalanceOf(userAccount[0]).call();
	    return yCake;
    }

    async function getReward() {
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let reward = await contract.methods.calculateReward().call();
	    return reward;
    }

window.addEventListener('load', async () => {
    // Modern dapp browsers...
    if (window.ethereum) {
      window.web3 = new Web3(ethereum);
      try {
        // Request account access if needed
        await ethereum.enable();

        //listeners
        document.getElementById('stakeButton').addEventListener('click', async () => stake());
        document.getElementById('withdrawButton').addEventListener('click', async () => withdraw());
        document.getElementById('approve_Cake').addEventListener('click', async () => cakeApprove());
        document.getElementById('approve_yCake').addEventListener('click', async () => yCakeApprove());

        //function calls
        let balanceValue = await getBalance();
        let rewardValue = await getReward();
        let yCakeValue = await getBalanceOf();

        let balanceElement = document.getElementById("balance");
        let rewardElement = document.getElementById("reward");
        let yCakeElement = document.getElementById("yCake");

        balanceElement.innerHTML = balanceValue;
        rewardElement.innerHTML = rewardValue;
        yCakeElement.innerHTML = yCakeValue;

      } catch (error) {
        // User denied account access...
      }
    }
    // Non-dapp browsers...
    else {
      console.log('Non-Ethereum browser detected. You should consider trying MetaMask!');
    }
  });