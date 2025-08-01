# HorizonCircle

> **DeFi-Powered Cooperative Lending Platform**  
> Targeting the Philippine BNPL market with 67-80% cost savings through social collateral mechanisms and multi-protocol yield optimization.

[![Lisk Mainnet](https://img.shields.io/badge/Lisk-Mainnet-blue)](https://blockscout.lisk.com/)
[![Next.js](https://img.shields.io/badge/Next.js-15-black)](https://nextjs.org/)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-red)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Ready-green)](https://getfoundry.sh/)

## 🌟 Overview

HorizonCircle revolutionizes lending by combining **social collateral** with **automated DeFi yield generation**. Users create lending circles where members earn ~5% APY on deposits while supporting each other's borrowing needs at effective rates as low as 3% APR.

### Key Innovation
- **Social Collateral**: Members contribute to each other's loan collateral requirements
- **Real-Time Yield**: Deposits automatically earn yield through Morpho WETH vault integration  
- **Dynamic Rates**: Borrowing rate = Morpho yield + 3% spread (effective ~3% APR after yield)
- **85% LTV**: High loan-to-value ratio with community-backed collateral
- **DeFi Integration**: WETH→wstETH swaps via Velodrome DEX + Morpho lending markets

## 🏗️ Architecture

### Smart Contract System
```
Factory Pattern (EIP-1167)
├── HorizonCircleFactory → Creates lending circles via minimal proxy
├── HorizonCircleCore → Circle logic with social lending + DeFi integration
├── CircleRegistry → Discovery system for UI
└── Modules → Velodrome swaps + Morpho lending integration
```

### DeFi Integration Flow
```
ETH Deposit → WETH → Morpho Vault (5% APY) → Share-based accounting
     ↓
Social Loan Request → Member Contributions → Share Deduction
     ↓  
WETH Withdrawal → wstETH Swap → Morpho Lending → ETH Transfer to Borrower
```

## 🚀 Production Deployment (Lisk Mainnet)

| Component | Contract | Address | Status |
|-----------|----------|---------|---------|
| **Circle Creation** | HorizonCircleFactory | `0x95e4c63Ee7e82b94D75dDbF858F0D2D0600fcCdD` | ✅ Working (7+ circles) |
| **Circle Logic** | HorizonCircleWithMorphoAuth | `0x763004aE80080C36ec99eC5f2dc3F2C260638A83` | ✅ Working (48KB bytecode) |
| **Discovery** | CircleRegistry | `0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE` | ✅ Working |
| **Loan Execution** | LendingModule | `0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801` | ✅ Working (funded) |
| **Yield Generation** | Morpho WETH Vault | `0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346` | ✅ Working (~5% APY) |

**Network**: Lisk Mainnet (Chain ID: 1135)  
**Currency**: Native ETH  
**Block Explorer**: https://blockscout.lisk.com/

## 🛠️ Tech Stack

### Frontend
- **Framework**: Next.js 15 + TypeScript + Tailwind CSS
- **UI Components**: Shadcn/ui
- **Web3**: Wagmi + Viem for Lisk network integration
- **Authentication**: Privy SDK (wallet abstraction + email login)
- **Database**: Supabase (PostgreSQL)

### Smart Contracts
- **Language**: Solidity 0.8.20
- **Framework**: Foundry
- **Pattern**: Factory + Minimal Proxy (EIP-1167)
- **Integration**: Morpho Blue + Velodrome CL Pools

### DeFi Protocols
- **Yield**: Morpho WETH Vault (~5% APY)
- **Swaps**: Velodrome Concentrated Liquidity Pools
- **Collateral**: wstETH via Morpho lending markets

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Foundry
- Git

### Frontend Setup
```bash
# Clone repository
git clone https://github.com/yourusername/HorizonCircle.git
cd HorizonCircle

# Install frontend dependencies
cd frontend
npm install

# Start development server
npm run dev
# Open http://localhost:3000
```

### Smart Contract Development
```bash
# Navigate to contracts
cd contracts

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Deploy to Lisk mainnet (requires .env setup)
forge script script/Deploy.s.sol --rpc-url https://rpc.api.lisk.com --broadcast
```

### Environment Setup
```bash
# Frontend (.env.local)
NEXT_PUBLIC_PRIVY_APP_ID=your_privy_app_id
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_key

# Contracts (.env)
PRIVATE_KEY=your_private_key
RPC_URL=https://rpc.api.lisk.com
```

## 📁 Project Structure

```
HorizonCircle/
├── frontend/                 # Next.js application
│   ├── src/
│   │   ├── app/              # App router pages
│   │   ├── components/       # React components
│   │   ├── hooks/            # Web3 hooks
│   │   └── config/           # Contract addresses & ABIs
│   └── package.json
├── contracts/                # Smart contracts
│   ├── src/                  # Active contracts
│   │   ├── HorizonCircleWithMorphoAuth.sol
│   │   ├── HorizonCircleModularFactory.sol
│   │   ├── CircleRegistry.sol
│   │   └── interfaces/       # External protocol interfaces
│   ├── future/               # Advanced contracts (ready for deployment)
│   ├── unused/               # Legacy/experimental contracts
│   ├── script/               # Deployment scripts
│   └── foundry.toml
└── README.md
```

## 🎯 Key Features

### For Users
- **Easy Onboarding**: Email + wallet abstraction via Privy
- **Automatic Yield**: Earn ~5% APY on ETH deposits
- **Social Lending**: Borrow with community collateral support
- **Low Effective Rates**: ~3% APR effective borrowing cost
- **High LTV**: 85% loan-to-value ratios

### For Developers
- **Factory Pattern**: Gas-efficient circle deployment
- **Modular Architecture**: Swap/lending modules for complex DeFi operations
- **Industry Standards**: ERC4626 vaults, Uniswap V3 compatible swaps
- **Event-Driven**: Real-time UI updates via blockchain events
- **Comprehensive Testing**: Foundry test suite + manual verification

## 🔧 Development

### Smart Contract Commands
```bash
# Build contracts
forge build --force

# Run tests with gas reporting
forge test --gas-report

# Deploy specific script
forge script script/DeployLite.s.sol --rpc-url $RPC_URL --broadcast

# Verify deployment
cast call $FACTORY_ADDRESS "getCircleCount()" --rpc-url $RPC_URL
```

### Frontend Commands
```bash
# Development
npm run dev          # Start dev server
npm run build        # Production build
npm run lint         # ESLint
npm run type-check   # TypeScript validation

# Testing
npm run test         # Run tests (if configured)
```

## 📊 Performance

### Smart Contract Metrics
- **Circle Contract**: 48KB (within 24KB proxy limit via modular design)
- **Factory Gas Cost**: ~200K gas per circle deployment
- **Deposit Gas Cost**: ~150K gas (includes Morpho vault integration)
- **Loan Execution**: ~400K gas (includes DEX swap + lending integration)

### DeFi Integration
- **Morpho Vault APY**: ~5% (real-time yield on deposits)
- **Swap Slippage**: 0.5% max (MEV protection)
- **Loan LTV**: 85% (community-backed collateral)
- **Effective Borrowing**: ~3% APR (after yield earnings)

## 🛡️ Security

### Smart Contract Security
- **ReentrancyGuard**: All external functions protected
- **Access Control**: Member-only functions with validation
- **Share-based Accounting**: Prevents inflation attacks
- **Slippage Protection**: 0.5% max on all swaps
- **Industry Standards**: ERC4626, OpenZeppelin patterns

### Architecture Security
- **Isolated Positions**: Each circle maintains separate DeFi positions
- **Proxy Pattern**: Upgradeable via factory (not individual circles)
- **Event-driven**: Transparent on-chain activity tracking
- **Rate Limiting**: RPC call optimization to prevent abuse

## 🤝 Contributing

### Development Process
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and test thoroughly
4. Commit with clear messages (`git commit -m 'Add amazing feature'`)
5. Push and create Pull Request

### Code Standards
- **Solidity**: Follow OpenZeppelin patterns
- **TypeScript**: Strict mode enabled
- **Testing**: Comprehensive test coverage required
- **Documentation**: Update README and CLAUDE.md for changes

## 📋 Roadmap

### Phase 1 (✅ Completed)
- Basic lending circle functionality
- Factory pattern deployment
- Morpho vault integration
- UI for circle management

### Phase 2 (🔄 In Progress)
- Advanced DeFi integration (Morpho Blue lending)
- Enhanced UI/UX improvements
- Real-time notifications
- Mobile optimization

### Phase 3 (🔮 Future)
- Multi-protocol yield strategies
- Cross-chain integration
- Governance features
- Philippine market expansion

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Live App**: [Coming Soon]
- **Documentation**: See `CLAUDE.md` and `TODO.md`
- **Block Explorer**: https://blockscout.lisk.com/
- **Lisk Network**: https://lisk.com/

## 💡 Support

For questions and support:
- **Issues**: Create a GitHub issue
- **Development**: Check `CLAUDE.md` for detailed technical guidance
- **Status**: Check `TODO.md` for current development priorities

---

**Built with ❤️ for the DeFi community**