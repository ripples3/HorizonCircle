# HorizonCircle Smart Contract Architecture

## Active Contracts (Production)

```
┌─────────────────────────────────────────────────────────┐
│                    CircleRegistry.sol                    │
│                 0x0A0504ad92...2aC931                   │
│                                                         │
│  - Tracks all deployed circles                         │
│  - Manages user memberships                            │
│  - Industry standard registry pattern                  │cwar
└────────────────────────┬────────────────────────────────┘
                         │ tracks
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   HorizonCircle.sol                     │
│                 0xdfEfcC4848...B02959                   │
│                                                         │
│  Main lending circle with:                             │
│  - ETH deposits → WETH conversion                      │
│  - Morpho vault integration (yield)                    │
│  - Social collateral requests                          │
│  - Loan system with wstETH collateral                  │
└──────────┬──────────────────────┬───────────────────────┘
           │ imports              │ deploys
           ▼                      ▼
┌──────────────────────┐  ┌──────────────────────┐
│   LiskConfig.sol     │  │ VelodromeHelper.sol  │
│                      │  │                      │
│ Network addresses:   │  │ Swap functions:      │
│ - WETH               │  │ - ETH → wstETH       │
│ - wstETH             │  │ - wstETH → ETH       │
│ - Morpho vault       │  │ - Slippage protection│
│ - Velodrome router   │  │                      │
└──────────────────────┘  └──────────────────────┘
```

## How They Work Together

### 1. **User Flow**
```
User → CircleRegistry → HorizonCircle → Morpho Vault
                            ↓
                      Velodrome DEX
```

### 2. **Deposit Flow**
```
ETH → HorizonCircle → WETH → Morpho Vault (earns yield)
```

### 3. **Loan Flow**
```
Request Collateral → Contributors add WETH → Withdraw from Morpho
         ↓
    Execute Loan → WETH → ETH → wstETH (via Velodrome)
         ↓
    wstETH used as collateral in Morpho lending
```

## Key Integrations

### Morpho Protocol
- **Vault**: `0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346`
- **Purpose**: Earn 5% APY on deposits
- **Token**: WETH

### Velodrome DEX
- **Router**: `0x3a63171DD9BebF4D07BC782FECC7eb0b890C2A45`
- **Purpose**: Swap ETH ↔ wstETH for collateral
- **Slippage**: 0.5% max

## File Structure
```
contracts/src/
├── HorizonCircle.sol       # Main circle contract (22KB)
├── CircleRegistry.sol      # Registry for tracking circles (2.5KB)
├── LiskConfig.sol          # Network configuration
├── VelodromeHelper.sol     # DEX swap helper
└── unused/                 # Failed factory attempts (all >24KB)
    ├── HorizonCircleFactory*.sol
    └── README.md
```

## Why Registry Pattern?

The factory pattern failed because:
- HorizonCircle = 22KB
- Any factory deploying it = 22KB + factory code > 24KB limit

Industry standard solution:
1. Deploy circles directly
2. Register them in a lightweight registry
3. Same pattern used by ENS, Gnosis Safe, etc.