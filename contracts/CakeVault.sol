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
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) internal userShare;
    uint256 internal fullShare;

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

        uint256 _share = cakeToShare(_amount);
        fullShare = fullShare.add(_share);
        userShare[msg.sender] = userShare[msg.sender].add(_share);
        userBalance[msg.sender] = userBalance[msg.sender].add(_amount);

        yCakeToken.mint(msg.sender, _amount);
        cakeToken.transferFrom(msg.sender, address(this), _amount);
        controller.deposit(_amount);
        locked memory timelockData;
        timelockData.expires = block.timestamp + lockInterval * 1 minutes;
        timelockData.amount = _amount;
        timelocks[msg.sender].push(timelockData);

        emit Deposit(msg.sender, _amount);
    }

    /// @notice Gets the tokens from the active strategy contract. Burns yCakes, gives back the Cakes to the investor
    /// @dev Burning yCake should be possible, since the contract should have the MINTER_ROLE
    function withdraw(uint256 _cakeAmount) public {
        require(_cakeAmount > 0, "Only a positive value can be withdrawn");
        require(userBalance[msg.sender] >= _cakeAmount, "not enough balance");
        require(yCakeToken.allowance(msg.sender, address(this)) >= _cakeAmount, "yCake allowance not sufficient");  
        require(yCakeToken.balanceOf(msg.sender) - getLockedAmount(msg.sender) >= _cakeAmount, "Not enough unlocked tokens");

        uint256 _balance = cakeToShare(userBalance[msg.sender]);
        uint256 _profit = userShare[msg.sender].sub(_balance);
        uint256 _amount = shareToCake(_profit).add(_cakeAmount);

        userShare[msg.sender] = userShare[msg.sender].sub(_profit).sub(cakeToShare(_cakeAmount));
        userBalance[msg.sender] = userBalance[msg.sender].sub(_cakeAmount);
        fullShare = fullShare.sub(_profit).sub(cakeToShare(_cakeAmount));

        if (cakeToken.balanceOf(address(this)) < _amount){
            uint256 stratBalance = controller.getBalance();
            uint256 _spill = _amount.sub(cakeToken.balanceOf(address(this)));
            if(stratBalance < _spill){
                harvest();
            }
            controller.withdraw(_spill);
        }
        
        yCakeToken.burn(msg.sender, _cakeAmount);
        cakeToken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// @notice Changes the address of the active Strategy
    function changeStrategy(address _newStrategy) external onlyStrategist {
        controller.changeStrategy(_newStrategy);
        emit ChangedStrategy(_newStrategy);
    }

    /// @notice Calls the harvest function of the Controller, changes the reward tokens to CAKE tokens and reinvests
    function harvest() public onlyStrategist {
        controller.harvest();
    }

    /// @notice Withdraws everything from the active Strategy. The reward token is converted to CAKE.
    function withdrawAll() external onlyOwner returns(uint256){
        uint256 _amount = controller.withdrawAll();
        return _amount;
    }

    /// @notice deposits all of the CAKE stored in the Vault to the active Strategy
    function depositAll() external onlyStrategist {
        uint256 _amount = cakeToken.balanceOf(address(this));
        controller.deposit(_amount);
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
        uint256 usersLockedLength = usersLocked.length;
        uint256 blockTimestamp = block.timestamp;
        for(uint256 i = 0; i < usersLockedLength; i++) {
            if (usersLocked[i].expires <= blockTimestamp) {
                // Expired locks, remove them
                usersLocked[i] = usersLocked[usersLockedLength - 1];
                usersLocked.pop();
                usersLockedLength--;
                i--;
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

    /// @notice change Cake to share value
    /// @param _cakeAmount The amount of Cake to be converted
    /// @return _cakeAmount in share
    function cakeToShare(uint256 _cakeAmount) internal view returns (uint256){
        uint256 _fullCakeAmount = controller.getBalance().add(cakeToken.balanceOf(address(this)));
        if(_fullCakeAmount > 0){
            return _cakeAmount.mul(fullShare).div(_fullCakeAmount);
        }else{
            return _cakeAmount.mul(1e21);
        }
    }

    /// @notice change share to Cake value
    /// @param _shareAmount The amount of share to be converted
    /// @return _shareAmount in Cake
    function shareToCake(uint256 _shareAmount) internal view returns (uint256){
        if(fullShare > 0){
            return controller.getBalance().add(cakeToken.balanceOf(address(this))).mul(_shareAmount).div(fullShare);
        }else{
            return 0;
        }
    }

    /// @notice a user can withdraw only the profit.
    /// does not burn yCake
    function userHarvest() external {
        uint256 _balance = cakeToShare(userBalance[msg.sender]);
        uint256 _profit = userShare[msg.sender].sub(_balance);
        uint256 _reward = shareToCake(_profit);

        userShare[msg.sender] = userShare[msg.sender].sub(_profit);
        fullShare = fullShare.sub(_profit);

        if (cakeToken.balanceOf(address(this)) < _reward){
            uint256 stratBalance = controller.getBalance();
            uint256 _spill = _reward.sub(cakeToken.balanceOf(address(this)));
            if(stratBalance < _spill){
                harvest();
            }
            controller.withdraw(_spill);
        }
        cakeToken.transfer(msg.sender, _reward);
    }

    /// @return The amount of profit in Cake
    function getPendingReward(address _account) public view returns (uint256){
        uint256 _balance = cakeToShare(userBalance[_account]);
        uint256 _profit = userShare[_account].sub(_balance);
        return shareToCake(_profit);
    }
}
