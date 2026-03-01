"use client";

import { useEffect, useState } from "react";
import { ethers } from "ethers";

const VAULT_ABI = [
  "function deposit(uint256 assets) returns (uint256)",
  "function withdraw(uint256 shares) returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
  "function totalAssets() view returns (uint256)",
];

const ERC20_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function decimals() view returns (uint8)",
];

export default function Home() {
  const [account, setAccount] = useState<string>("");
  const [usdcBalance, setUsdcBalance] = useState<string>("0");
  const [shareBalance, setShareBalance] = useState<string>("0");
  const [depositAmount, setDepositAmount] = useState<string>("0");
  const [withdrawAmount, setWithdrawAmount] = useState<string>("0");

  const rpcUrl = process.env.NEXT_PUBLIC_RPC_URL!;
  const usdc = process.env.NEXT_PUBLIC_USDC!;
  const vault = process.env.NEXT_PUBLIC_VAULT!;

  const provider = new ethers.JsonRpcProvider(rpcUrl);

  async function connect() {
    if (!window.ethereum) return alert("MetaMask not found");
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
    setAccount(accounts[0]);
  }

  async function refresh() {
    if (!account) return;
    const usdcContract = new ethers.Contract(usdc, ERC20_ABI, provider);
    const vaultContract = new ethers.Contract(vault, VAULT_ABI, provider);
    const [bal, shares] = await Promise.all([
      usdcContract.balanceOf(account),
      vaultContract.balanceOf(account),
    ]);
    setUsdcBalance(bal.toString());
    setShareBalance(shares.toString());
  }

  async function deposit() {
    if (!window.ethereum) return;
    const signer = await new ethers.BrowserProvider(window.ethereum).getSigner();
    const usdcContract = new ethers.Contract(usdc, ERC20_ABI, signer);
    const vaultContract = new ethers.Contract(vault, VAULT_ABI, signer);
    const amount = BigInt(depositAmount);
    await (await usdcContract.approve(vault, amount)).wait();
    await (await vaultContract.deposit(amount)).wait();
    refresh();
  }

  async function withdraw() {
    if (!window.ethereum) return;
    const signer = await new ethers.BrowserProvider(window.ethereum).getSigner();
    const vaultContract = new ethers.Contract(vault, VAULT_ABI, signer);
    const amount = BigInt(withdrawAmount);
    await (await vaultContract.withdraw(amount)).wait();
    refresh();
  }

  useEffect(() => {
    refresh();
  }, [account]);

  return (
    <main style={{ maxWidth: 700, margin: "40px auto", fontFamily: "Inter, sans-serif" }}>
      <h1>USDC Yield Vault</h1>
      <p>Deposit USDC → vault supplies to Aave v3 → withdraw with yield.</p>

      {!account ? (
        <button onClick={connect}>Connect Wallet</button>
      ) : (
        <div>
          <div>Account: {account}</div>
          <div>USDC balance: {usdcBalance}</div>
          <div>Vault shares: {shareBalance}</div>
        </div>
      )}

      <hr />

      <div>
        <h3>Deposit</h3>
        <input value={depositAmount} onChange={(e) => setDepositAmount(e.target.value)} />
        <button onClick={deposit}>Deposit</button>
      </div>

      <div style={{ marginTop: 16 }}>
        <h3>Withdraw (shares)</h3>
        <input value={withdrawAmount} onChange={(e) => setWithdrawAmount(e.target.value)} />
        <button onClick={withdraw}>Withdraw</button>
      </div>
    </main>
  );
}
