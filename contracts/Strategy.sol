// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./token/IBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

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
    using SafeMath for uint256;

    address private vaultAddress;
    address private strategistAddress;
    address private activePoolAddress;
    address private activeRewardTokenAddress;

    uint256 balance;

    mapping(string => address) pools;
    mapping(string => address) rewardTokens;

    IBEP20 private cakeToken;
    IBEP20 private rewardToken;

    CAKEPoolInterface cakePool;

    /// @notice Összeköti a Straregy-t a Vaultal és a Strategist-el és megad egy kezdő pool-t
    /// @param _vaultAddress A Vault contract address-e
    /// @param _strategistAddress A Strategist contract address-e
    /// @param _poolSymbol A kezdő pool-t beazonosító szimbólum
    /// @param _poolAddress A kezdő pool címe
    /// @param _rewardTokenSymbol A jutalomként kapott tokent beazonosító szimbólum
    /// @param _rewardTokenAddress A jutalomként kapott token address-e
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
        cakeToken.approve(activePoolAddress, uint256(-1));
        cakePool = CAKEPoolInterface(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    }

    /// @notice A hívó csak a Vault lehet
    modifier onlyVault(){
        require(msg.sender == vaultAddress);
        _;
    }

    /// @notice A hívó csak a Strategist lehet
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

    /// @notice lekéri a korábban approve-olt CAKE tokeneket, feljegyzi és elküldi az aktív poolnak
    /// @param _amount Az elküldésre szánt CAKE token mennyisége
    function deposit (uint256 _amount) external onlyVault {
        cakeToken.transferFrom(msg.sender, address(this), _amount);
        if(activePoolAddress == 0x73feaa1eE314F8c655E354234017bE2193C9E24E) {
            cakePool.enterStaking(_amount);
        } else {
            PoolInterface(activePoolAddress).deposit(_amount);
        }
        balance.add(_amount);
    }


    /// @notice A Vault számára az aktív pool-ból lekér egy bizonyos összeget és a nyereséget elküldi a Strategist-nek.
    /// A kezelt összeg változását könyveli.
    /// @param _amount A lekérni szándékozott CAKE token mennyisége
    function withdraw (uint256 _amount) external onlyVault {
        require(balance >= _amount, "There isn't enough balance");
        if(activePoolAddress == 0x73feaa1eE314F8c655E354234017bE2193C9E24E) {
            uint256 reward = cakePool.pendingCake(0, address(this));
            cakePool.leaveStaking(_amount);
            cakeToken.transfer(vaultAddress, _amount);
            rewardToken.transfer(strategistAddress, reward);
        } else {
            PoolInterface(activePoolAddress).withdraw(_amount);
            cakeToken.transfer(vaultAddress, _amount);
            rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        }
        balance.sub(_amount);
    }

    /// @notice A Strategist kérésére az aktív pool-ból kivesz minden tokent, a nyereséget elküldi a Strategist-nek,
    /// a többit a Vaultnak. A kezelt összeget 0-ra állítja
    function withdrawAll () external onlyStrategist {
        if(activePoolAddress == 0x73feaa1eE314F8c655E354234017bE2193C9E24E) {
            uint256 reward = cakePool.pendingCake(0, address(this));
            cakePool.leaveStaking(balance);
            cakeToken.transfer(vaultAddress, balance);
            rewardToken.transfer(strategistAddress, reward);
        } else {
            PoolInterface(activePoolAddress).withdraw(balance);
            cakeToken.transfer(vaultAddress, balance);
            rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        }
        balance = 0;
    }

    /// @notice Nincs harvest függvény de a withdraw elküldi a jutalmat is.
    function harvest () external onlyStrategist {
        if(activePoolAddress == 0x73feaa1eE314F8c655E354234017bE2193C9E24E) {
            uint256 reward = cakePool.pendingCake(0, address(this));
            cakePool.leaveStaking(0);
            rewardToken.transfer(strategistAddress, reward);
        } else {
            PoolInterface(activePoolAddress).withdraw(0);
            rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        }
    }

    /// @notice Kivesz mindent az aktív pool-ból, lecseráli az aktív pool-t és reward tokent,
    /// elküldi a nyereséget a Strategist-nek majd mindent berak az új aktív pool-ba
    /// @dev Fontos, hogy a pool és a token összetartozzon és már korábban el legyen tárolva
    /// @param _symbolOfNewPool Az új pool-t beazonosító szimbólum
    /// @param _symbolOfNewRewardToken Az új jutalomként kapott tokent beazonosító szimbólum
    function reinvest (string memory _symbolOfNewPool, string memory _symbolOfNewRewardToken) external onlyStrategist {
        require(pools[_symbolOfNewPool] != address(0x0), "This pool doesn't exist");
        require(rewardTokens[_symbolOfNewRewardToken] != address(0x0), "This token doesn't exist");

        if(activePoolAddress == 0x73feaa1eE314F8c655E354234017bE2193C9E24E) {
            uint256 reward = cakePool.pendingCake(0, address(this));
            cakePool.leaveStaking(balance);
            rewardToken.transfer(strategistAddress, reward);
        } else {
            PoolInterface(activePoolAddress).withdraw(balance);
            rewardToken.transfer(strategistAddress, rewardToken.balanceOf(address(this)));
        }

        activePoolAddress = pools[_symbolOfNewPool];
        activeRewardTokenAddress = rewardTokens[_symbolOfNewRewardToken];

        if(activePoolAddress == 0x73feaa1eE314F8c655E354234017bE2193C9E24E) {
            cakePool.enterStaking(balance);
        } else {
            PoolInterface(activePoolAddress).deposit(balance);
        }
    }

    /// @notice Új pool-t és reward tokent ad a tároltak listájához. Csak az Owner tudja meghívni
    /// @dev Fontos, hogy a Strategy contractot NE a Strategist deploy-olja biztonsági okokból.
    /// A token és a pool összetartozó legyen
    /// @param _poolSymbol Az új pool-t beazonosító szimbólum
    /// @param _poolAddress Az új pool címe
    /// @param _rewardTokenSymbol Az új jutalomként kapott tokent beazonosító szimbólum
    /// @param _rewardTokenAddress Az új jutalomként kapott token address-e
    function addPool(string memory _poolSymbol, address _poolAddress, string memory _rewardTokenSymbol, address _rewardTokenAddress) external onlyOwner {
        require(pools[_poolSymbol] == address(0x0), "This pool is already set");
        require(rewardTokens[_rewardTokenSymbol] == address(0x0), "This token is already set");
        pools[_poolSymbol] = _poolAddress;
        rewardTokens[_rewardTokenSymbol] = _rewardTokenAddress;
        cakeToken.approve(_poolAddress, uint256(-1));
    }

    /// @notice Egy már korábban megadott pool és reward token aktívra állítása. Csak az Owner tudja meghívni
    /// @dev A token és a pool összetartozó legyen.
    /// Fontos, hogy a Strategy contractot NE a Strategist deploy-olja biztonsági okokból.
    /// Ennek az a célja, hogy se a Strategist se az Owner ne tudjon visszaélni.
    /// A pool váltáshoz mind a kettő hozzájárulására szükség van.
    /// @param _poolSymbol Az új pool-t beazonosító szimbólum
    /// @param _rewardTokenSymbol Az új jutalomként kapott tokent beazonosító szimbólum
    function rollback(string memory _poolSymbol, string memory _rewardTokenSymbol) external onlyOwner {
        require(pools[_poolSymbol] != address(0x0), "This pool doesn't exist");
        require(rewardTokens[_rewardTokenSymbol] != address(0x0), "This token doesn't exist");
        activePoolAddress = pools[_poolSymbol];
        activeRewardTokenAddress = rewardTokens[_rewardTokenSymbol];
    }
}
