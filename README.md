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
| **Factory** | HorizonCircleMinimalProxyWithModules | `0x3540f3612Ac246D2aFE5DaeB0c825aEd29D43421` | ✅ **Latest** |
| **Implementation** | HorizonCircleWithMorphoAuth | `0x63373ea6A0C8DDC65883b0c9d2E0a67f96567Ccb` | ✅ **Latest** |
| **Registry** | CircleRegistry | `0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE` | ✅ **Verified** |
| **Lending Module** | LendingModuleSimplified | `0x96F582fAF5a1D61640f437EBea9758b18a678720` | ✅ **Verified** |
| **Swap Module** | SwapModuleIndustryStandardV2 | `0x1E394C5740f3b04b4a930EC843a43d1d49Ddbd2A` | ✅ **Verified** |

**✨ Latest Features** (August 2025):
- ✅ **addMember Functionality**: Add friends to existing circles
- ✅ **Duplicate Prevention**: Smart contract prevents duplicate members
- ✅ **Complete DeFi Integration**: Full loan execution with WETH→wstETH→Morpho lending
- ✅ **Real-time Yield**: ~5% APY on all deposits via Morpho vault integration

**Network**: Lisk Mainnet (Chain ID: 1135)  
**Currency**: Native ETH  
**Block Explorer**: https://blockscout.lisk.com/  
**Deploy Block**: 19,755,618 (August 2025)

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
│   ├── src/                  # Active contracts (PRODUCTION)
│   │   ├── HorizonCircleWithMorphoAuth.sol         # ✅ Circle implementation
│   │   ├── HorizonCircleMinimalProxyWithModules.sol # ✅ Factory
│   │   ├── CircleRegistry.sol                      # ✅ Discovery system
│   │   ├── LendingModuleSimplified.sol             # ✅ Morpho integration
│   │   ├── SwapModuleIndustryStandardV2.sol        # ✅ Velodrome swaps
│   │   └── LiskConfig.sol                          # ✅ Network config
│   ├── script/               # Deployment scripts
│   ├── tests_archive/        # Essential test scripts only
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

### Phase 1 (✅ Completed - August 2025)
- ✅ **Complete Lending Circle System**: Factory pattern with proxy deployment
- ✅ **Full DeFi Integration**: Morpho vault + Morpho lending + Velodrome swaps
- ✅ **Member Management**: Add/remove members with duplicate prevention
- ✅ **Real-time Yield**: ~5% APY on all ETH deposits
- ✅ **Complete Loan Execution**: WETH→wstETH→Morpho lending→ETH to borrower
- ✅ **Production UI**: Circle creation, deposits, loans, member management

### Phase 2 (🔄 Ready for Production)
- ✅ **Smart Contract Verification**: All contracts verified on Lisk Blockscout
- ✅ **Bug Fixes**: Duplicate member prevention, cache optimization
- ✅ **Enhanced UX**: Improved error handling and user feedback
- 🔄 **Mobile Optimization**: Responsive design improvements
- 🔄 **Advanced Notifications**: Real-time loan request alerts

### Phase 3 (🔮 Future Enhancements)
- 🔮 **Multi-protocol Yield**: Integrate additional DeFi protocols
- 🔮 **Cross-chain Support**: Expand to other L2 networks
- 🔮 **Governance Features**: DAO-style circle governance
- 🔮 **Philippine Market**: Localized features and partnerships

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Live Contracts**: All contracts deployed and verified on Lisk mainnet
- **Factory**: [0x3540f3612Ac246D2aFE5DaeB0c825aEd29D43421](https://blockscout.lisk.com/address/0x3540f3612Ac246D2aFE5DaeB0c825aEd29D43421)
- **Implementation**: [0x63373ea6A0C8DDC65883b0c9d2E0a67f96567Ccb](https://blockscout.lisk.com/address/0x63373ea6A0C8DDC65883b0c9d2E0a67f96567Ccb)
- **Documentation**: See `CLAUDE.md` for technical details
- **Block Explorer**: https://blockscout.lisk.com/
- **Lisk Network**: https://lisk.com/

## 💡 Support

For questions and support:
- **Issues**: Create a GitHub issue
- **Development**: Check `CLAUDE.md` for detailed technical guidance
- **Status**: Check `TODO.md` for current development priorities

---

**Built with ❤️ for the DeFi community**
