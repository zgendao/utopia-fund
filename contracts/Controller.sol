// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./token/IBEP20.sol";
import "./interfaces/StrategyInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Controller is Ownable{
    using SafeMath for uint256;

    address public strategist;

    mapping(address => address) internal stakeTokens;
    mapping(address => mapping(address => bool)) internal strategies;
    mapping(address => address) internal activeStrategies;
    mapping(address => address) internal rewardTokens;

    constructor (address _strategistAddress) {
        strategist = _strategistAddress;
    }

    /// @notice Can only be called by the Vault
    modifier onlyVault(){
        require(stakeTokens[msg.sender] != address(0x0), "Not Vault");
        _;
    }

    /// @notice Can only be called by the Strategist
    modifier onlyStrategist(){
        require(msg.sender == strategist, "Not Strategist");
        _;
    }

    /// @param _strategistAddress Address of the new Strategist
    function setStrategist(address _strategistAddress) external onlyOwner {
        strategist = _strategistAddress;
    }

    /// @param _vaultAddress Address of the new Vault
    /// @param _stakeTokenAddress Address of the Token belonging to the new Vault
    function addVault(address _vaultAddress, address _stakeTokenAddress) external onlyOwner {
        stakeTokens[_vaultAddress] = _stakeTokenAddress;
    }

    /// @notice Tha Vault has to be added beforehand
    /// @param _vaultAddress Address of the Vault that uses the new Strategy
    /// @param _strategyAddress Address of the new Strategy
    /// @param _rewardTokenAddress Address of the Token we get from the new Strategy as reward
    function addStrategy(address _vaultAddress, address _strategyAddress, address _rewardTokenAddress) external onlyStrategist {
        require(stakeTokens[_vaultAddress] != address(0x0), "Not Vault");
        strategies[_vaultAddress][_strategyAddress] = true;
        rewardTokens[_strategyAddress] = _rewardTokenAddress;
    }

    /// @notice After a Strategy is added this has to be called for it to function
    /// @param _strategyAddress Address of the Strategy to be approved
    /// @param _stakeTokenAddress Address of the Token that is being deposited to the Strategy
    function approveStrategy(address _strategyAddress, address _stakeTokenAddress) external onlyStrategist {
        IBEP20(_stakeTokenAddress).approve(_strategyAddress, uint256(-1));
    }

    function deposit(uint256 _amount) external onlyVault {
        IBEP20(stakeTokens[msg.sender]).transferFrom(msg.sender, address(this), _amount);
        StrategyInterface(activeStrategies[msg.sender]).deposit(_amount);
    }

    function withdraw(uint256 _amount) external onlyVault {
        StrategyInterface(activeStrategies[msg.sender]).withdraw(_amount);
        IBEP20(stakeTokens[msg.sender]).transfer(msg.sender, _amount);
    }

    function withdrawAll() external onlyVault returns(uint256) {
        uint256 _amount;
        uint256 _fee;
        (_amount, _fee) = StrategyInterface(activeStrategies[msg.sender]).withdrawAll();
        if(_fee > 0){
            IBEP20(stakeTokens[msg.sender]).transfer(strategist, _fee);
        }
        IBEP20(stakeTokens[msg.sender]).transfer(msg.sender, _amount);
        return _amount;
    }

    /// @notice In case some tokens stuck in the contract
    function saveTokens(address _tokenAddress) external onlyOwner {
         IBEP20(_tokenAddress).transfer(msg.sender, IBEP20(_tokenAddress).balanceOf(address(this)));
    }

    /// @notice Calls the harvest function of the active strategy, changes the reward tokens to stake tokens and reinvests
    function harvest() external onlyVault {
        uint256 _fee = StrategyInterface(activeStrategies[msg.sender]).harvest();
        if(_fee > 0){
            IBEP20(stakeTokens[msg.sender]).transfer(strategist, _fee);
        }
    } 

    /// @notice Withdraws everything from the active Strategy and changes the active Strategy
    /// @param _newStrategy Address of the new active Strategy
    function changeStrategy(address _newStrategy) external onlyVault{
        require(rewardTokens[_newStrategy] != address(0x0), "Reward token not set");
        require(strategies[msg.sender][_newStrategy] == true, "Strategy not set");
        uint256 _amount;
        uint256 _fee;

        if(activeStrategies[msg.sender] == address(0x0)){
            activeStrategies[msg.sender] = _newStrategy;
        } else {
            if(StrategyInterface(activeStrategies[msg.sender]).getBalance() > 0){
                (_amount, _fee) = StrategyInterface(activeStrategies[msg.sender]).withdrawAll();
                if(_fee > 0){
                    IBEP20(stakeTokens[msg.sender]).transfer(strategist, _fee);
                }
                activeStrategies[msg.sender] = _newStrategy;
                StrategyInterface(activeStrategies[msg.sender]).deposit(_amount);
            }else{
                activeStrategies[msg.sender] = _newStrategy;
            }
        }
    }

    /// @return The amount of Stake tokens handled by the Strategy
    function getBalance() external view onlyVault returns(uint256) {
        return StrategyInterface(activeStrategies[msg.sender]).getBalance();
    }
}