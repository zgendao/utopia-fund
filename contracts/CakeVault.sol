// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./token/BEP20Mintable.sol";
import "./interfaces/IController.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title A vault that holds PancakeSwap Cake tokens
contract CakeVault is Ownable {
    using SafeMath for uint256;

    IBEP20 internal cakeToken;
    BEP20Mintable internal yCakeToken;
    IController internal controller;
    address internal strategist;
    address internal constant cakeTokenAddress = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    // For timelock
    struct locked {
        uint256 expires;
        uint256 amount;
    }
    mapping(address => locked[]) internal timelocks;
    uint256 public lockInterval = 60;

    // For reward
    uint256 internal startBlock;
    uint256 internal vaultBalance;
    uint256 internal growthMonitor = 10000;
    mapping(address => uint256) internal userBalance;
    mapping(address => uint256) internal lastDeposit;
    mapping(address => uint256) internal pendingReward;


    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event ChangedCakeAddress(address newAddress);
    event ChangedStrategy(address newAddress);

    constructor(address _strategistAddress, address _controllerAddress) {
        strategist = _strategistAddress;
        controller = IController(_controllerAddress);
        cakeToken = IBEP20(cakeTokenAddress);
        cakeToken.approve(_controllerAddress, uint256(-1));
        yCakeToken = new BEP20Mintable("yCake Token", "yCake");
        startBlock = block.number;
    }

    /// @notice Can only be called by the Strategist
    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }

    /// @notice Changes the Controller and approves the CAKE token for transactions
    function changeController(address _controllerAddress) external onlyOwner {
        controller = IController(_controllerAddress);
        cakeToken.approve(_controllerAddress, uint256(-1));
    }

    /// @notice Accepts cakes, mints yCakes to the investor. Forwards the deposited amount to the active strategy contract
    /// @dev Minting yCake should be possible, since the contract should have the MINTER_ROLE
    function deposit(uint256 _amount) public {
        require(_amount > 0, "Only a positive value can be deposited");
        require(cakeToken.allowance(msg.sender, address(this)) >= _amount, "Cake allowance not sufficient");
        require(cakeToken.balanceOf(msg.sender) >= _amount, "Sender does not have enough funds");
        cakeToken.transferFrom(msg.sender, address(this), _amount);
        yCakeToken.mint(msg.sender, _amount);
        controller.deposit(_amount);
        locked memory timelockData;
        timelockData.expires = block.timestamp + lockInterval * 1 minutes;
        timelockData.amount = _amount;
        timelocks[msg.sender].push(timelockData);

        uint256 _reward = calculateReward();
        pendingReward[msg.sender] = pendingReward[msg.sender].add(_reward);
        userBalance[msg.sender] = userBalance[msg.sender].add(_amount);
        lastDeposit[msg.sender] = block.number;
        vaultBalance = vaultBalance.add(_amount);

        emit Deposit(msg.sender, _amount);
    }

    /// @notice Gets the tokens from the active strategy contract. Burns yCakes, gives back the Cakes to the investor
    /// @dev Burning yCake should be possible, since the contract should have the MINTER_ROLE
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Only a positive value can be withdrawn");
        require(yCakeToken.allowance(msg.sender, address(this)) >= _amount, "yCake allowance not sufficient");
        require(yCakeToken.balanceOf(msg.sender) - getLockedAmount(msg.sender) >= _amount, "Not enough unlocked tokens");

        uint256 _reward = calculateReward();
        uint256 profit = _amount.add(_reward).add(pendingReward[msg.sender]);
        pendingReward[msg.sender] = 0;

        controller.withdraw(profit);
        yCakeToken.burn(msg.sender, _amount);
        cakeToken.transfer(msg.sender, profit);
        emit Withdraw(msg.sender, profit);
    }

    /// @notice Changes the address of the active Strategy
    function changeStrategy(address _newStrategy) external onlyStrategist {
        uint256 _growthRate = controller.changeStrategy(_newStrategy);
        updateGrowthMonitor(_growthRate);
        emit ChangedStrategy(_newStrategy);
    }

    /// @notice Calls the harvest function of the Controller, changes the reward tokens to CAKE tokens and reinvests
    function harvest() external onlyStrategist {
        uint256 _growthRate = controller.harvest();
        updateGrowthMonitor(_growthRate);
    }

    /// @notice Withdraws everything from the active Strategy. The reward token is converted to CAKE.
    function withdrawAll() external onlyStrategist returns(uint256){
        uint256 _amount;
        uint256 _growthRate;
        (_amount, _growthRate) = controller.withdrawAll();
        updateGrowthMonitor(_growthRate);
        return _amount;
    }

    /// @notice Changes the address of the Cake token. Use in case it gets changed in the future
    function setCakeAddress(address _newAddress) external onlyOwner {
        cakeToken = IBEP20(_newAddress);
        emit ChangedCakeAddress(_newAddress);
    }

    /// @notice Sets the timelock interval for new deposits
    function setLockInterval(uint256 _minutes) public onlyOwner {
        lockInterval = _minutes;
    }

    /// @notice Checks if the address has enough unlocked deposits 
    /// @dev Also deletes any expired lock data
    function getLockedAmount(address _investor) internal returns (uint256) {
        uint256 lockedAmount = 0;
        locked[] storage usersLocked = timelocks[_investor];    // storage ref -> we can modify members directly in the original array
        for(uint256 i = 0; i < usersLocked.length; i++) {
            if (usersLocked[i].expires <= block.timestamp) {
                // Expired locks, remove them
                usersLocked[i] = usersLocked[usersLocked.length - 1];
                usersLocked.pop();
            } else {
                // Still not expired, count it in
                lockedAmount += usersLocked[i].amount;
            }
        }
        return lockedAmount;
    }

    /// @notice Gets the yCake balance of _account
    /// @return The amount of yCakes _account has
    function getBalanceOf(address _account) public view returns (uint256) {
        return yCakeToken.balanceOf(_account);
    }

    /// @notice used to monitor the the rate of the profit gain
    function updateGrowthMonitor(uint256 _growthRate) internal {
        growthMonitor = growthMonitor.mul(_growthRate).div(10000);
    }

    /// @notice calculates the reward of each user based on time and value
    function calculateReward() public view returns (uint256){
        uint256 _growth = vaultBalance.mul(growthMonitor.sub(10000)).div(10000);
        uint256 _timeShare = block.number.sub(lastDeposit[msg.sender]).mul(10000).div(block.number.sub(startBlock));
        uint256 _valueShare = userBalance[msg.sender].mul(10000).div(vaultBalance);
        uint256 _share = _timeShare.mul(_valueShare).div(10000);
        uint256 _reward = _growth.mul(_share).div(10000);
        return _reward;
    }
}
