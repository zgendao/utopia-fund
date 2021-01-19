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
    }

    /// @notice Withdraws a certain amount of CAKE tokens and sends them to the Controller and the reward is stored for now.
    /// The withdrawn amount is subtracted from the balance
    /// @param _amount The amount of staking tokens to be withdrawn
    function withdraw(uint256 _amount) external onlyController {
        require(balance >= _amount, "There is not enough balance");  
        pool.leaveStaking(_amount);
        cakeToken.transfer(controllerAddress, _amount);
        balance = balance.sub(_amount);
    }

    /// @notice Withdraws all of the staking tokens.
    /// The reward and the stake is sent to the Controller
    /// balance is set to zero
    function withdrawAll() external onlyController returns (uint256) {
        uint256 _amount = balance;
        pool.leaveStaking(_amount);
        _amount = cakeToken.balanceOf(address(this));
        cakeToken.transfer(controllerAddress, _amount);
        balance = 0;
        return _amount;
    }
    
    /// @notice There is no built in harvest function but the withdraw transfers the profit.
    /// The profit is reinvested in the pool
    function harvest() external onlyController {
        pool.leaveStaking(0);
        uint256 _amount = cakeToken.balanceOf(address(this));
        pool.enterStaking(_amount);
        balance = balance.add(_amount);
    }

    /// @return The amount of CAKE tokens handled by the Strategy
    function getBalance() external view returns (uint256) {
        return balance;
    }
}