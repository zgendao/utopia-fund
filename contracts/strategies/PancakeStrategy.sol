// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../token/IBEP20.sol";
import "../interfaces/PancakePoolInterface.sol";
import "../interfaces/TokenSwap.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PancakeStrategy is Ownable{
    using SafeMath for uint256;

    address internal vaultAddress;
    address internal controllerAddress;

    uint256 public balance = 0;
    uint256 internal withdrawn = 0;
    uint256 internal deposited = 0;

    IBEP20 internal stakeToken;
    IBEP20 internal rewardToken;

    address[] internal exchangePath;

    PoolInterface internal pool;
    TokenSwap internal exchange;

    /// @notice Links the Strategy, the Vault and the Controller together and initialises the pool
    /// @param _vaultAddress Address of the Vault contract
    /// @param _controllerAddress Address of the Controller contract
    /// @param _stakeTokenAddress Address of the staking token
    /// @param _poolAddress Address of the pool
    /// @param _rewardTokenAddress Address of the reward token
    /// @param _exchangeAddress contranct handling the token swap [0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F]
    /// @param _path path of exchange from reward to stake token
    constructor (
        address _vaultAddress, 
        address _controllerAddress,
        address _stakeTokenAddress, 
        address _poolAddress,
        address _rewardTokenAddress,
        address _exchangeAddress,
        address[] memory _path
        ) {
        stakeToken = IBEP20(_stakeTokenAddress);
        rewardToken = IBEP20(_rewardTokenAddress);
        vaultAddress = _vaultAddress;
        controllerAddress = _controllerAddress;
        pool = PoolInterface(_poolAddress);
        exchangePath = _path;
        exchange = TokenSwap(_exchangeAddress);
        stakeToken.approve(_poolAddress, uint256(-1));
        rewardToken.approve(_exchangeAddress, uint256(-1));
    }

    /// @notice Can only be called by the Controller
    modifier onlyController(){
        require(msg.sender == controllerAddress, "Not Controller");
        _;
    }

    /// @notice In case of an error in the exchange contract
    function setExchange(address _newExchangeAddress) external onlyOwner {
       exchange = TokenSwap(_newExchangeAddress);
    }

    /// @notice In case some tokens stuck in the contract
    function saveTokens(address _tokenAddress) external onlyOwner {
         IBEP20(_tokenAddress).transfer(msg.sender, IBEP20(_tokenAddress).balanceOf(address(this)));
    }

    /// @notice Takes the staking tokens approved beforehand, adds the amount to the balance then sends it to the pool
    /// @param _amount The amount of tokens to be transferred
    function deposit(uint256 _amount) external onlyController {
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        pool.deposit(_amount);
        balance = balance.add(_amount);
        deposited = deposited.add(_amount);
    }

    /// @notice Withdraws a certain amount of staking tokens and sends them to the Controller and the reward is stored for now.
    /// The withdrawn amount is subtracted from the balance
    /// @param _amount The amount of staking tokens to be withdrawn
    function withdraw(uint256 _amount) external onlyController {
        require(balance >= _amount, "There is not enough balance");  
        
        pool.withdraw(_amount);
        stakeToken.transfer(controllerAddress, _amount);
        balance = balance.sub(_amount);
        withdrawn = withdrawn.add(_amount);
    }
    
    /// @notice Withdraws all of the staking tokens.
    /// The reward is swapped to staking token and all of the staking token is sent to the Controller
    /// balance is set to zero
    function withdrawAll() external onlyController returns (uint256, uint256, uint256) {
        pool.withdraw(balance);
        uint256 _reward = rewardToken.balanceOf(address(this));
        exchange.swapExactTokensForTokens(_reward, uint256(0), exchangePath, address(this), block.timestamp.add(1800));
        uint256 _fullAmount = stakeToken.balanceOf(address(this));
        uint256 _amount = _fullAmount;
        _reward = _fullAmount.sub(balance);
        uint256 _fee = 0;

        if(_reward >= 10000){
            _fee = calculateFee(_reward);
            _amount = _amount.sub(_fee);
        }

        uint256 _growthRate = calculateGrowthRate(balance, _amount);

        stakeToken.transfer(controllerAddress, _fullAmount);
        balance = 0;
        withdrawn = 0;
        deposited = 0;
        return (_amount, _fee, _growthRate);
    }

    /// @notice There is no built in harvest function but the withdraw transfers the profit.
    /// The profit is reinvested in the pool
    function harvest() external onlyController returns (uint256, uint256) {
        uint256 _oldBalance = balance;
        pool.withdraw(0);
        uint256 _reward = rewardToken.balanceOf(address(this));
        exchange.swapExactTokensForTokens(_reward, uint256(0), exchangePath, address(this), block.timestamp.add(1800));
        _reward = stakeToken.balanceOf(address(this));
        uint256 _fee = 0;

        if(_reward >= 10000){
            _fee = calculateFee(_reward);
            _reward = _reward.sub(_fee);
            stakeToken.transfer(controllerAddress, _fee);
        }

        pool.deposit(_reward);
        balance = balance.add(_reward);

        uint256 _growthRate = calculateGrowthRate(_oldBalance, balance);
        withdrawn = 0;
        deposited = 0;
        return (_fee, _growthRate);
    }

    /// @return The amount of staking tokens handled by the Strategy
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