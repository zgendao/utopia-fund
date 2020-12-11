// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./token/IBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface PoolInterface {
    function withdraw(uint256 _amount) external;
    function pendingReward(address _user) external view returns (uint256);
    function deposit(uint256 _amount) external;
}

contract Strategy is Ownable{

    address private vaultAddress;
    address private strategistAddress;
    address private activePoolAddress;
    address private activeRewardTokenAddress;

    uint256 balance;

    mapping(string => address) pools;
    mapping(string => address) rewardTokens;

    IBEP20 private cakeToken;
    IBEP20 private rewardToken;

    constructor (
        address _vaultAddress, 
        address _strategistAddress, 
        string memory _poolSymbol, 
        address _poolAddress,
        string memory _rewardTokenSymbol,
        address _rewardTokenAddress
        ) {
        cakeToken = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
        rewardToken = IBEP20(_rewardTokenAddress);
        vaultAddress = _vaultAddress;
        strategistAddress = _strategistAddress;
        pools[_poolSymbol] = _poolAddress;
        rewardTokens[_rewardTokenSymbol] = _rewardTokenAddress;
        activePoolAddress = _poolAddress;
        activeRewardTokenAddress = _rewardTokenAddress;
        //ide kell a pancake flip végtelen approve a pool fele
    }

    modifier onlyVault(){
        require(msg.sender == vaultAddress);
        _;
    }

    modifier onlyStrategist(){
        require(msg.sender == strategistAddress);
        _;
    }

    /// @notice Approves Vault to manage the amount of tokens it just got
    /// @param _wot The address of the BEP20 token the function accepted
    /// @param _amount The amount of tokens it accepted
    function acceptTokens(address _wot, uint256 _amount) public onlyStrategist {
        IBEP20(_wot).approve(msg.sender, _amount);
    }

    function deposit (uint256 _amount) external onlyVault {
        cakeToken.transferFrom(msg.sender, address(this), _amount);
        PoolInterface(activePoolAddress).deposit(_amount);
        balance += _amount;
    }


    function withdraw (uint256 _amount) external onlyVault {
        require(balance >= _amount, "There isn't enough balance");
        PoolInterface(activePoolAddress).withdraw(_amount);
        cakeToken.transfer(vaultAddress, _amount);
        rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        balance -= _amount;
    }


    function withdrawAll () external onlyStrategist {
        PoolInterface(activePoolAddress).withdraw(balance);
        cakeToken.transfer(vaultAddress, balance);
        rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        balance = 0;
    }

    //nincs harvest függvény de a withdraw elküldi a jutalmat is
    function harvest () external onlyStrategist {
        PoolInterface(activePoolAddress).withdraw(balance);
        PoolInterface(activePoolAddress).deposit(balance);
        rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
    }


    function reinvest (string memory _symbolOfNewPool, string memory _symbolOfNewRewardToken) external onlyStrategist {
        require(pools[_symbolOfNewPool] != address(0x0), "This pool doesn't exist");
        require(rewardTokens[_symbolOfNewRewardToken] != address(0x0), "This token doesn't exist");
        PoolInterface(activePoolAddress).withdraw(balance);
        rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        activePoolAddress = pools[_symbolOfNewPool];
        activeRewardTokenAddress = rewardTokens[_symbolOfNewRewardToken];
        PoolInterface(activePoolAddress).deposit(balance);
    }

    //új pool és reward token hozzáadása. fontos hogy össze tartozzon
    function addPool(string memory _poolSymbol, address _poolAddress, string memory _rewardTokenSymbol, address _rewardTokenAddress) external onlyOwner {
        require(pools[_poolSymbol] == address(0x0), "This pool is already set");
        require(rewardTokens[_rewardTokenSymbol] == address(0x0), "This token is already set");
        //ide kell a pancake flip végtelen approve a pool fele
        pools[_poolSymbol] = _poolAddress;
        rewardTokens[_rewardTokenSymbol] = _rewardTokenAddress;
    }

    //egy már korábban megadott pool és reward token aktívra állítása. fontos hogy össze tartozzon
    function rollback(string memory _poolSymbol, string memory _rewardTokenSymbol) external onlyOwner {
        require(pools[_poolSymbol] != address(0x0), "This pool doesn't exist");
        require(rewardTokens[_rewardTokenSymbol] != address(0x0), "This token doesn't exist");
        activePoolAddress = pools[_poolSymbol];
        activeRewardTokenAddress = rewardTokens[_rewardTokenSymbol];

    }
}
