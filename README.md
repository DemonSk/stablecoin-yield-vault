# USDC Yield Vault (Aave v3) — Full Stack

## What it is
A minimal full‑stack staking vault:
- Users deposit **USDC** and receive **vault shares**.
- The vault supplies USDC to **Aave v3** to earn yield.
- Users withdraw shares and receive USDC + yield.

## Contracts (Foundry)
### How to run
```bash
forge test
```

### Key contracts
- `YieldVault.sol` — core vault logic
- `MockAavePool.sol` — mock Aave pool for tests
- `MockERC20.sol` — mock USDC/aUSDC

## Frontend (Next.js)
### Setup
```bash
cd frontend
cp .env.example .env.local
npm install
npm run dev
```

### Env variables
```
NEXT_PUBLIC_RPC_URL=
NEXT_PUBLIC_USDC=
NEXT_PUBLIC_VAULT=
```

## Deploy (Sepolia)
1. Deploy `YieldVault` with:
   - `USDC` address
   - `aUSDC` address
   - `Aave Pool` address
2. Update `.env.local` with deployed addresses.

## Notes
- This is a **learning demo**, not audited.
- For production: add ERC‑4626, access control, pausable, and safety checks.
