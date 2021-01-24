// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../token/IBEP20.sol";
import "../interfaces/PancakeCakePoolInterface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PancakeCakeStrategy{
    using SafeMath for uint256;

    address internal vaultAddress;
    address internal controllerAddress;

    uint256 public balance = 0;
    uint256 internal withdrawn = 0;
    uint256 internal deposited = 0;

    IBEP20 internal cakeToken;

    CakePoolInterface internal pool;

    /// @notice Links the Strategy, the Vault and the Controller together and initialises the pool
    /// @param _vaultAddress Address of the Vault contract
    /// @param _controllerAddress Address of the Controller contract
    /// @param _cakeTokenAddress Address of the CAKE token. This is the staking AND the reward token.
    /// @param _poolAddress Address of the CAKEpool
    constructor (
        address _vaultAddress, 
        address _controllerAddress,
        address _cakeTokenAddress, 
        address _poolAddress
        ) {
        cakeToken = IBEP20(_cakeTokenAddress);
        vaultAddress = _vaultAddress;
        controllerAddress = _controllerAddress;
        pool = CakePoolInterface(_poolAddress);
        cakeToken.approve(_poolAddress, uint256(-1));
    }


    /// @notice Can only be called by the Controller
    modifier onlyController(){
        require(msg.sender == controllerAddress, "Not Controller");
        _;
    }

    /// @notice Takes the CAKE tokens approved beforehand, adds the amount to the balance then sends it to the pool
    /// @param _amount The amount of tokens to be transferred
    function deposit(uint256 _amount) external onlyController {
        cakeToken.transferFrom(msg.sender, address(this), _amount);
        pool.enterStaking(_amount);
        balance = balance.add(_amount);
        deposited = deposited.add(_amount);
    }

    /// @notice Withdraws a certain amount of CAKE tokens and sends them to the Controller and the reward is stored for now.
    /// The withdrawn amount is subtracted from the balance
    /// @param _amount The amount of staking tokens to be withdrawn
    function withdraw(uint256 _amount) external onlyController {
        require(balance >= _amount, "There is not enough balance");  
        pool.leaveStaking(_amount);
        cakeToken.transfer(controllerAddress, _amount);
        balance = balance.sub(_amount);
        withdrawn = withdrawn.add(_amount);
    }

    /// @notice Withdraws all of the staking tokens.
    /// The reward and the stake is sent to the Controller
    /// balance is set to zero
    function withdrawAll() external onlyController returns (uint256, uint256, uint256) {
        pool.leaveStaking(balance);
        uint256 _fullAmount = cakeToken.balanceOf(address(this));
        uint256 _amount = _fullAmount;
        uint256 _reward = _fullAmount.sub(balance);
        uint256 _fee = 0;

        if(_reward >= 10000){
            _fee = calculateFee(_reward);
            _amount = _amount.sub(_fee);
        }

        uint256 _growthRate = calculateGrowthRate(balance, _amount);

        cakeToken.transfer(controllerAddress, _fullAmount);
        balance = 0;
        withdrawn = 0;
        deposited = 0;
        return (_amount, _fee, _growthRate);
    }
    
    /// @notice There is no built in harvest function but the withdraw transfers the profit.
    /// The profit is reinvested in the pool
    function harvest() external onlyController returns (uint256, uint256) {
        uint256 _oldBalance = balance;
        pool.leaveStaking(0);
        uint256 _reward = cakeToken.balanceOf(address(this));
        uint256 _fee = 0;

        if(_reward >= 10000){
            _fee = calculateFee(_reward);
            _reward = _reward.sub(_fee);
            cakeToken.transfer(controllerAddress, _fee);
        }

        pool.enterStaking(_reward);
        balance = balance.add(_reward);
        uint256 _growthRate = calculateGrowthRate(_oldBalance, balance);
        withdrawn = 0;
        deposited = 0;
        return (_fee, _growthRate);
    }

    /// @return The amount of CAKE tokens handled by the Strategy
    function getBalance() external view returns (uint256) {
        return balance;
    }

    /// @notice If the reward is less than 10000 the rounding error becomes considerable
    /// @return One percent of the submited amount.
    function calculateFee (uint256 _reward) internal pure returns(uint256){
        _reward = _reward.mul(100).div(10000);
        return _reward;
    }

    /// @notice This is used to calculate the profit of each user
    /// @return The growth rate of the deposited founds.
    function calculateGrowthRate (uint256 _balance, uint256 _balanceWithProfit) internal view returns(uint256){
        _balance = _balance.add(withdrawn).sub(deposited);
        _balanceWithProfit = _balanceWithProfit.add(withdrawn).sub(deposited);
        uint256 growthRate = _balanceWithProfit.mul(10000).div(_balance);
        return growthRate;
    }
}