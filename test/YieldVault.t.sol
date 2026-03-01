// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/YieldVault.sol";
import "../src/mocks/MockERC20.sol";
import "../src/mocks/MockAavePool.sol";

contract YieldVaultTest is Test {
    MockERC20 usdc;
    MockERC20 aUsdc;
    MockAavePool pool;
    YieldVault vault;

    address alice = address(0xA11CE);

    function setUp() public {
        usdc = new MockERC20("USD Coin", "USDC", 6);
        aUsdc = new MockERC20("Aave USDC", "aUSDC", 6);
        pool = new MockAavePool(address(usdc), address(aUsdc));
        vault = new YieldVault(address(usdc), address(aUsdc), address(pool));

        usdc.mint(alice, 1_000_000_000); // 1000 USDC (6 decimals)
        vm.prank(alice);
        usdc.approve(address(vault), type(uint256).max);
    }

    function testDepositWithdraw() public {
        vm.prank(alice);
        vault.deposit(100_000_000); // 100 USDC

        assertEq(vault.balanceOf(alice), 100_000_000);
        assertEq(aUsdc.balanceOf(address(vault)), 100_000_000);

        vm.prank(alice);
        vault.withdraw(50_000_000); // withdraw 50 shares

        assertEq(usdc.balanceOf(alice), 950_000_000);
    }

    function testYieldAccrues() public {
        vm.prank(alice);
        vault.deposit(100_000_000); // 100 USDC

        // simulate yield: mint 10 aUSDC to vault
        aUsdc.mint(address(vault), 10_000_000);

        uint256 assets = vault.previewWithdraw(100_000_000);
        assertEq(assets, 110_000_000);
    }
}
