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
    }

    /// @notice Withdraws a certain amount of staking tokens and sends them to the Controller and the reward is stored for now.
    /// The withdrawn amount is subtracted from the balance
    /// @param _amount The amount of staking tokens to be withdrawn
    function withdraw(uint256 _amount) external onlyController {
        require(balance >= _amount, "There is not enough balance");  
        
        pool.withdraw(_amount);
        stakeToken.transfer(controllerAddress, _amount);
        balance = balance.sub(_amount);
    }
    
    /// @notice Withdraws all of the staking tokens.
    /// The reward is swapped to staking token and all of the staking token is sent to the Controller
    /// balance is set to zero
    function withdrawAll() external onlyController returns (uint256) {
        uint256 _amount = balance;
        pool.withdraw(_amount);
        uint256 _reward = rewardToken.balanceOf(address(this));
        exchange.swapExactTokensForTokens(_reward, uint256(0), exchangePath, address(this), block.timestamp.add(1800));
        _amount = stakeToken.balanceOf(address(this));
        stakeToken.transfer(controllerAddress, _amount);
        balance = 0;
        return _amount;
    }

    /// @notice There is no built in harvest function but the withdraw transfers the profit.
    /// The profit is reinvested in the pool
    function harvest() external onlyController {
        pool.withdraw(0);
        uint256 _reward = rewardToken.balanceOf(address(this));
        exchange.swapExactTokensForTokens(_reward, uint256(0), exchangePath, address(this), block.timestamp.add(1800));
        _reward = stakeToken.balanceOf(address(this));
        pool.deposit(_reward);
        balance = balance.add(_reward);
    }

    /// @return The amount of staking tokens handled by the Strategy
    function getBalance() external view returns (uint256) {
        return balance;
    }
}