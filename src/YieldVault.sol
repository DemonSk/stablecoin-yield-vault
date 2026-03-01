// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC20.sol";
import "./interfaces/IAavePool.sol";

/// @notice Simple USDC vault that deposits to Aave and issues shares.
contract YieldVault {
    string public name = "USDC Yield Vault";
    string public symbol = "yvUSDC";
    uint8 public immutable decimals;

    IERC20 public immutable asset; // USDC
    IERC20 public immutable aToken; // aUSDC
    IAavePool public immutable pool;

    address public owner;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "OWNER");
        _;
    }

    constructor(address _asset, address _aToken, address _pool) {
        asset = IERC20(_asset);
        aToken = IERC20(_aToken);
        pool = IAavePool(_pool);
        owner = msg.sender;
        decimals = IERC20(_asset).decimals();
    }

    // --- ERC20 share logic ---
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "ALLOWANCE");
        allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "BALANCE");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    // --- Vault logic ---
    function totalAssets() public view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        uint256 ts = totalSupply;
        return ts == 0 ? assets : (assets * ts) / totalAssets();
    }

    function previewWithdraw(uint256 shares) public view returns (uint256) {
        uint256 ts = totalSupply;
        return ts == 0 ? 0 : (shares * totalAssets()) / ts;
    }

    function deposit(uint256 assets) external returns (uint256 shares) {
        require(assets > 0, "ZERO");
        shares = previewDeposit(assets);
        require(shares > 0, "SHARES");

        require(asset.transferFrom(msg.sender, address(this), assets), "TRANSFER_FROM");
        require(asset.approve(address(pool), assets), "APPROVE");
        pool.supply(address(asset), assets, address(this), 0);

        _mint(msg.sender, shares);
        emit Deposit(msg.sender, assets, shares);
    }

    function withdraw(uint256 shares) external returns (uint256 assets) {
        require(shares > 0, "ZERO");
        assets = previewWithdraw(shares);
        require(assets > 0, "ASSETS");

        _burn(msg.sender, shares);
        pool.withdraw(address(asset), assets, address(this));
        require(asset.transfer(msg.sender, assets), "TRANSFER");

        emit Withdraw(msg.sender, assets, shares);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(balanceOf[from] >= amount, "BALANCE");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    // owner‑only rescue for wrong tokens (optional)
    function rescue(address token, address to, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(to, amount), "RESCUE");
    }
}
