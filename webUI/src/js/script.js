
    let contract;
    //this needs to be updated after deployement of Vault
    const cakeVaultAddress = "0x32C658FE435145D3B1Edb91E3f1c850362397eca";
    const cakeAddress = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";
    const yCakeAddress = "0xe0897C19e6dE7A127A1C3147b214184Ba6D8AD32";
    const maxValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935n;

    //contract functions
    async function cakeApprove() {
      contract = new web3.eth.Contract(BEP20Abi, cakeAddress);
      let accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      await contract.methods.approve(cakeVaultAddress, maxValue).send( {from : accounts[0], gas: 500000} )
    }

    async function yCakeApprove() {
      contract = new web3.eth.Contract(BEP20Abi, yCakeAddress);
      let accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      await contract.methods.approve(cakeVaultAddress, maxValue).send( {from : accounts[0], gas: 500000} )
    }
    
    async function stake() {
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      let stakeAmount = document.getElementById("stakeAmount").value;
      await contract.methods.deposit(stakeAmount).send( {from : accounts[0], gas: 500000} )
    }

    async function withdraw() {
      let accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let withdrawAmount = document.getElementById("withdrawAmount").value;
      await contract.methods.withdraw(withdrawAmount).send( {from : accounts[0], gas: 500000} )
    }

    async function userHarvest() {
      let accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      await contract.methods.userHarvest().send( {from : accounts[0], gas: 500000} )
    }

    async function getBalance() {
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      let balance = await contract.methods.userBalance(accounts[0]).call();
	    return balance;
    }

    async function getReward() {
      let accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let reward = await contract.methods.getPendingReward(accounts[0]).call();
	    return reward;
    }

    async function getBalanceOf() {
      let accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      contract = new web3.eth.Contract(cakeVaultAbi, cakeVaultAddress);
      let yCake = await contract.methods.getBalanceOf(accounts[0]).call();
	    return yCake;
    }

window.addEventListener('load', async () => {
    // Modern dapp browsers...
    if (window.ethereum) {
      window.web3 = new Web3(ethereum);
      try {

        //listeners
        document.getElementById('stakeButton').addEventListener('click', async () => stake());
        document.getElementById('withdrawButton').addEventListener('click', async () => withdraw());
        document.getElementById('harvestButton').addEventListener('click', async () => userHarvest());
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