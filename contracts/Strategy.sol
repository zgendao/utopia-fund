// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./token/IBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface PoolInterface {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function pendingReward(address _user) external view returns (uint256);
}

interface CAKEPoolInterface {
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    //CAKE Pool: _pid = 0, _user = address(this)
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
}

contract Strategy is Ownable{

    address internal vaultAddress;
    address internal strategistAddress;
    address internal activePoolAddress;
    address internal activeRewardTokenAddress;
    address internal cakePoolAddress = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
    address internal cakeTokenAddress = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    uint256 public balance = 0;

    mapping(string => address) internal pools;
    mapping(string => address) internal rewardTokens;
    mapping(string => string) internal tokenOfPool;

    IBEP20 internal cakeToken;
    IBEP20 internal rewardToken;

    CAKEPoolInterface internal cakePool;

    /// @notice Links the Strategy, the Vault and the Strategist together and initialises a starting pool
    /// @param _vaultAddress Address of the Vault contract
    /// @param _strategistAddress Address of the Strategist wallet
    /// @param _poolSymbol Identifier symbol of the starting pool
    /// @param _poolAddress Address of the starting pool
    /// @param _rewardTokenSymbol Identifier symbol of the starting reward token
    /// @param _rewardTokenAddress Address of the starting reward token
    constructor (
        address _vaultAddress, 
        address _strategistAddress, 
        string memory _poolSymbol, 
        address _poolAddress,
        string memory _rewardTokenSymbol,
        address _rewardTokenAddress
        ) {
        cakeToken = IBEP20(cakeTokenAddress);
        rewardToken = IBEP20(_rewardTokenAddress);
        vaultAddress = _vaultAddress;
        strategistAddress = _strategistAddress;
        pools[_poolSymbol] = _poolAddress;
        rewardTokens[_rewardTokenSymbol] = _rewardTokenAddress;
        tokenOfPool[_poolSymbol] = _rewardTokenSymbol;
        activePoolAddress = _poolAddress;
        activeRewardTokenAddress = _rewardTokenAddress;
        cakeToken.approve(activePoolAddress, uint256(-1));
        cakePool = CAKEPoolInterface(cakePoolAddress);
    }

    /// @notice Can only be called by the Vault
    modifier onlyVault(){
        require(msg.sender == vaultAddress);
        _;
    }

    /// @notice Can only be called by the Strategist
    modifier onlyStrategist(){
        require(msg.sender == strategistAddress);
        _;
    }

    /// @notice Approves Vault to manage the tokens it sends to Strategy
    /// @param _wot The address of the BEP20 token to approve
    /// @param _amount The amount of tokens to approve
    function acceptTokens(address _wot, uint256 _amount) external onlyVault {
        IBEP20(_wot).approve(msg.sender, _amount);
    }

    /// @notice Takes the CAKE tokens approved beforehand, adds the amount to the balance then sends it to the active pool
    /// @param _amount The amount of CAKE tokens to be transferred
    function deposit (uint256 _amount) external onlyVault {
        cakeToken.transferFrom(msg.sender, address(this), _amount);
        if(activePoolAddress == cakePoolAddress) {
            cakePool.enterStaking(_amount);
        } else {
            PoolInterface(activePoolAddress).deposit(_amount);
        }
        balance += _amount;
    }


    /// @notice Withdraws a certain amount of CAKE tokens and sends them to the Vault and the profit is sent to the Strategist.
    /// The withdrawn amount is subtracted from the balance
    /// @param _amount The amount of CAKE tokens to be withdrawn
    function withdraw (uint256 _amount) external onlyVault {
        require(balance >= _amount, "There is not enough balance");
        if(activePoolAddress == cakePoolAddress) {
            uint256 reward = cakePool.pendingCake(0, address(this));
            cakePool.leaveStaking(_amount);
            cakeToken.transfer(vaultAddress, _amount);
            rewardToken.transfer(strategistAddress, reward);
        } else {
            PoolInterface(activePoolAddress).withdraw(_amount);
            cakeToken.transfer(vaultAddress, _amount);
            rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        }
        balance -= _amount;
    }

    /// @notice Withdraws all of the CAKE tokens and sends them to the Vault and the profit is sent to the Strategist.
    /// The balance is set to zero
    function withdrawAll () external onlyVault returns (uint256) {
        if(activePoolAddress == cakePoolAddress) {
            uint256 reward = cakePool.pendingCake(0, address(this));
            cakePool.leaveStaking(balance);
            cakeToken.transfer(vaultAddress, balance);
            rewardToken.transfer(strategistAddress, reward);
        } else {
            PoolInterface(activePoolAddress).withdraw(balance);
            cakeToken.transfer(vaultAddress, balance);
            rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        }
        uint256 amount = balance;
        balance = 0;
        return amount;
    }
 
    /// @notice There is no built in harvest function but the withdraw transfers the profit
    /// This is just a withdraw with zero amount.
    function harvest () external onlyStrategist {
        if(activePoolAddress == cakePoolAddress) {
            uint256 reward = cakePool.pendingCake(0, address(this));
            cakePool.leaveStaking(0);
            rewardToken.transfer(strategistAddress, reward);
        } else {
            PoolInterface(activePoolAddress).withdraw(0);
            rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        }
    }

    /// @notice Withdraws everything then changes the active pool and reward token.
    /// Sends the profit to the Strategist and everything else is sent to the new active pool.
    /// @dev The new active pool and reward token has to belong together and should be declared beforehand.
    /// @param _symbolOfNewPool Identifier symbol of the new pool
    function reinvest (string memory _symbolOfNewPool) external onlyStrategist {
        require(pools[_symbolOfNewPool] != address(0x0), "This pool does not exist");
        require(rewardTokens[tokenOfPool[_symbolOfNewPool]] != address(0x0), "This pair is not set");

        if(activePoolAddress == cakePoolAddress) {
            uint256 reward = cakePool.pendingCake(0, address(this));
            cakePool.leaveStaking(balance);
            rewardToken.transfer(strategistAddress, reward);
        } else {
            PoolInterface(activePoolAddress).withdraw(balance);
            rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        }

        activePoolAddress = pools[_symbolOfNewPool];
        activeRewardTokenAddress = rewardTokens[tokenOfPool[_symbolOfNewPool]];
        rewardToken = IBEP20(activeRewardTokenAddress);

        if(activePoolAddress == cakePoolAddress) {
            cakePool.enterStaking(balance);
        } else {
            PoolInterface(activePoolAddress).deposit(balance);
        }
    }

    /// @notice Adds a new pool to the list.
    /// @dev The pool and reward token has to belong together and the reward token should be added beforehand.
    /// It is important that the Owner and the Strategist are different entities for safety reasons.
    /// This way neither can exploit the contract.
    /// Both are needed to add and use a new pool.
    /// @param _poolSymbol Identifier symbol of the new pool
    /// @param _poolAddress Address of the new pool
    /// @param _rewardTokenSymbol Identifier symbol of the reward token
    function addPool(string memory _poolSymbol, address _poolAddress, string memory _rewardTokenSymbol) external onlyOwner {
        require(pools[_poolSymbol] == address(0x0), "This pool is already set");
        require(rewardTokens[_rewardTokenSymbol] != address(0x0), "This token does not exist");
        pools[_poolSymbol] = _poolAddress;
        tokenOfPool[_poolSymbol] = _rewardTokenSymbol;
        cakeToken.approve(_poolAddress, uint256(-1));
    }

    /// @notice Adds a new reward token to the list.
    /// @param _rewardTokenSymbol Identifier symbol of the new reward token
    /// @param _rewardTokenAddress Address of the new reward token
    function addToken(string memory _rewardTokenSymbol, address _rewardTokenAddress) external onlyOwner {
        require(rewardTokens[_rewardTokenSymbol] == address(0x0), "This token is already set");
        rewardTokens[_rewardTokenSymbol] = _rewardTokenAddress;
    }
    /// @notice Sets an older pool and token to active.
    /// @dev there is NO withdraw or invest.
    /// THIS IS FOR SERIOUS EMERGENCIES ONLY
    /// The pool and reward token has to belong together
    /// @param _poolSymbol Identifier symbol of the pool to be set to active
    function rollback(string memory _poolSymbol) external onlyOwner {
        require(pools[_poolSymbol] != address(0x0), "This pool does not exist");
        require(rewardTokens[tokenOfPool[_poolSymbol]] != address(0x0), "This token does not exist");
        activePoolAddress = pools[_poolSymbol];
        activeRewardTokenAddress = rewardTokens[tokenOfPool[_poolSymbol]];
        rewardToken = IBEP20(activeRewardTokenAddress);
    }

    /// @return The amount of CAKE tokens handled by the Strategy
    function getBalance() external view returns (uint256) {
        return balance;
    }
}
