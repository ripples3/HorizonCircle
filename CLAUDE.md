# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HorizonCircle is a DeFi-powered cooperative lending platform targeting the Philippine BNPL market. It provides 67-80% cost savings vs traditional BNPL through a Morpho-backed lending protocol with social collateral contribution features.

**Key Business Model:**
- Users deposit USDC and earn 5% APY
- Borrow up to 85% of deposits at ultra-low effective rates (~0.1% APR)
- Social lending circles allow members to contribute collateral for larger loans
- Morpho protocol handles yield generation and borrowing infrastructure

## Tech Stack

**Frontend:** Next.js 15 + TypeScript + Tailwind CSS + Shadcn/ui (Desktop Web Browser)
**Authentication:** Privy SDK (wallet abstraction with email login)
**Web3:** Wagmi + Viem for Lisk network integration
**Database:** Supabase (PostgreSQL)
**Blockchain:** Lisk mainnet
**DeFi Protocol:** Morpho for yield and borrowing

## Development Commands

```bash
# Development server (with Turbopack)
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Lint code
npm run lint

# Working directory
cd frontend/
```

## Current Status & Limitations

**✅ Completed (Fully Working):**
- **Complete authentication system** with Privy (email + wallet abstraction)
- **Full Supabase database integration** with user data persistence
- **Complete dashboard** with sidebar navigation and real user data
- **Multi-step deposit/borrow forms** with rate calculations
- **User account management** with automatic record creation
- **Real-time balance tracking** and borrowing capacity calculations
- **Responsive UI/UX** optimized for desktop web browsers
- **Database schema** with all tables and relationships
- **TypeScript type safety** throughout the application
- **Custom React hooks** for data management (useUserData, useBalance, etc.)

**❌ Missing for Production (DeFi Integration):**
- **Smart contract deployment to Lisk** (contracts need to be deployed)
- **Actual Web3 transactions** (depends on deployed contracts)
- **Morpho protocol integration** (yield generation not connected)
- **Social lending features** (circle management is placeholder)
- **Real transaction execution** (currently demonstration only)

**Current Behavior:**
- **With API keys configured**: Users can create accounts, view real dashboard data, use deposit/borrow forms (demo transactions)
- **Without API keys**: Shows configuration requirements with graceful fallback
- **Account creation works** when `NEXT_PUBLIC_PRIVY_APP_ID` is set
- **Database operations work** when Supabase credentials are configured
- **Rate calculations and UI flows** are fully functional

## Architecture Overview

### Directory Structure
```
frontend/src/
├── app/                    # Next.js app router
├── components/
│   ├── auth/              # Authentication components
│   ├── dashboard/         # Main dashboard interface
│   ├── lending/           # Deposit/borrow flows
│   ├── circle/            # Social lending features
│   └── ui/               # Shadcn/ui components
├── config/               # Web3 and Supabase configuration
├── constants/            # App constants and rates
├── hooks/                # Custom React hooks for Web3
├── providers/            # Context providers
├── types/                # TypeScript type definitions
└── database/             # SQL schemas
```

### Key Configuration Files

**Environment Variables** (`.env.local`):
- `NEXT_PUBLIC_PRIVY_APP_ID` - Privy authentication (REQUIRED for account creation)
- `NEXT_PUBLIC_ALCHEMY_API_KEY` - Lisk RPC provider
- `NEXT_PUBLIC_SUPABASE_URL` - Database connection
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Database auth

**Core Constants** (`src/constants/index.ts`):
- `BASE_YIELD_RATE: 0.05` (5% APY)
- `BORROWING_RATE: 0.08` (8% APR)
- `DEFAULT_LTV: 0.85` (85% loan-to-value)
- `LISK_CHAIN_ID: 1135`

### Web3 Integration

**Chain Configuration** (`src/config/web3.ts`):
- Lisk mainnet with Alchemy RPC fallback
- Wagmi config with SSR support
- Contract addresses and ABIs (placeholders for deployment)

**Smart Contract Integration:**
- USDC token contract (ERC20)
- HorizonCircle lending pool contract
- Morpho protocol integration (planned)

### Data Layer

**Database Schema** (`src/database/schema.sql`):
- **FULLY IMPLEMENTED**: `users` - User accounts and balances
- **FULLY IMPLEMENTED**: `circles` - Lending circles (max 50 members)
- **FULLY IMPLEMENTED**: `loans` - Individual loan records
- **FULLY IMPLEMENTED**: `loan_requests` - Social lending requests
- **FULLY IMPLEMENTED**: `contributions` - Collateral contributions
- **FULLY IMPLEMENTED**: `transactions` - All financial activity
- **FULLY IMPLEMENTED**: Row Level Security (RLS) policies
- **FULLY IMPLEMENTED**: Database triggers and indexes

**TypeScript Types** (`src/types/index.ts` and `src/types/supabase.ts`):
- **FULLY IMPLEMENTED**: Core domain types: User, Circle, Loan, Transaction
- **FULLY IMPLEMENTED**: Supabase database types with full type safety
- **FULLY IMPLEMENTED**: Component props interfaces
- **FULLY IMPLEMENTED**: API response types

### Authentication & State Management

**Privy Integration** (`src/providers/privy-provider.tsx`):
- **FULLY WORKING**: Email-based authentication (no wallet complexity for users)
- **FULLY WORKING**: Embedded wallet creation
- **FULLY WORKING**: React Query for async state
- **FULLY WORKING**: Graceful fallback when API keys are missing
- **FULLY WORKING**: Automatic user record creation in Supabase

**Custom Hooks** (`src/hooks/`):
- `useUserData` - **WORKING**: Real user data management with Supabase
- `useBalance` - **WORKING**: USDC balance calculations and lending data
- `useTransactions` - **PLACEHOLDER**: Deposit, borrow, repay operations (smart contract integration pending)
- Wagmi hooks for contract interactions (contracts not deployed)

### UI Components

**Dashboard Layout** (`src/components/dashboard/`):
- **FULLY WORKING**: Sidebar navigation with multiple tabs
- **FULLY WORKING**: Real-time balance and rate calculations
- **FULLY WORKING**: User account management and settings
- **PLACEHOLDER**: Activity feeds and transaction history (shows "coming soon")

**Lending Flows** (`src/components/lending/`):
- **FULLY WORKING**: Multi-step deposit form with yield projections
- **FULLY WORKING**: Borrow interface with sliding scale and effective rate calculation
- **FULLY WORKING**: Rate transparency and cost breakdowns
- **PLACEHOLDER**: Social lending request system (shows "coming soon")

**Rate Calculation Logic:**
```typescript
// Effective rate calculation
const grossBorrowingCost = amount * BORROWING_RATE;
const yieldOffset = userBalance * BASE_YIELD_RATE;
const effectiveRate = (grossBorrowingCost - yieldOffset) / amount;
```

## Key Implementation Details

### Social Lending Model
- **Collateral Contribution System**: Users request additional collateral from circle members
- **Voluntary Participation**: No voting fatigue - members choose to contribute
- **Risk Distribution**: Contributors earn higher rates (12% vs 10%) for social risk
- **Circle Limits**: Maximum 50 members to maintain trust relationships

### Rate Transparency
- **Gross Rate**: 8% APR borrowing cost
- **Yield Offset**: User earns 5% APY on collateral
- **Effective Rate**: ~0.1% APR net cost to user
- **Dynamic Calculations**: Real-time rate updates based on user balances

### Morpho Integration Strategy
- **Deposit Flow**: User deposits → MetaMorpho Vault → Earns yield
- **Borrow Flow**: Withdraw from vault → Use as collateral → Borrow from Morpho Blue
- **Limitation**: Collateral stops earning yield while borrowed (Morpho design)
- **Trade-off**: Users give up 5% yield to access ultra-low borrowing rates

## Development Notes

**Current Working State:**
- **Desktop Web Browser**: Fully responsive design optimized for desktop
- **Authentication**: Privy integration working with email-based account creation
- **Database**: Supabase integration working with real user data persistence
- **UI Complete**: All core interfaces built and functional
- **Account Creation**: WORKING when Privy API key is configured

**File Structure:**
- `page.tsx` - Main application entry point with authentication flow
- `page-simple.tsx` - Basic landing page for testing (not currently used)
- `dashboard-layout.tsx` - Main dashboard with sidebar navigation
- `database-test.tsx` - Debug component for testing database connection

**Current Configuration Status:**
- **Required for full functionality**: Privy API key, Supabase credentials
- **When configured**: Users can create accounts, view real dashboard data
- **When missing**: Shows configuration requirements with graceful fallback
- **Database operations**: Working when Supabase credentials are set

**Next Steps for Production:**
1. Deploy smart contracts to Lisk mainnet
2. Connect Web3 transactions to deployed contracts
3. Implement Morpho protocol integration
4. Complete social lending features
5. Add real transaction execution and history

## Implementation Details

### Working Features

**1. User Authentication & Management**
- Email-based account creation via Privy
- Automatic embedded wallet generation
- User record creation in Supabase database
- Real-time user data synchronization
- Account settings and profile management

**2. Dashboard & UI Components**
- Real-time balance display and calculations
- Multi-step deposit form with yield projections
- Multi-step borrow form with effective rate calculations
- Sidebar navigation with multiple tabs
- Responsive design for desktop browsers

**3. Rate Calculation Engine**
- Gross borrowing rate: 8% APR
- Yield offset: 5% APY on collateral
- Effective rate calculation: (gross cost - yield offset) / loan amount
- Dynamic updates based on user balance changes
- Social lending rate premiums (12% for contributors)

**4. Database Operations**
- User CRUD operations with Supabase
- Real-time data synchronization
- Type-safe database queries
- Row Level Security (RLS) implementation
- Database connection testing and validation

### Current Limitations

**1. Smart Contract Layer**
- Contract addresses are empty placeholders
- No deployed contracts on Lisk mainnet
- Web3 transactions are simulated
- USDC token integration pending

**2. DeFi Protocol Integration**
- Morpho protocol not connected
- No real yield generation
- MetaMorpho vault deposits not implemented
- Borrowing transactions are demonstrations

**3. Social Lending Features**
- Circle management interface is placeholder
- Loan request system shows "coming soon"
- Contribution workflow not implemented
- Social features await smart contract deployment

## Rate Model Validation

The application demonstrates significant cost savings:
- **Philippine BNPL Market**: 30-50% effective APR with hidden fees
- **HorizonCircle**: 8-15% transparent APR with yield offset
- **Net Result**: 67-80% cost reduction for users
- **Competitive Analysis**: Beats SSS loans (10% APR) and bank personal loans (24-36% APR)

## Production Readiness Checklist

### ✅ Completed
- [x] User authentication and account management
- [x] Database schema and data persistence
- [x] Core UI components and user flows
- [x] Rate calculation engine
- [x] TypeScript type safety
- [x] Responsive design for desktop
- [x] Error handling and loading states

### ⏳ In Progress / Pending
- [ ] Smart contract deployment to Lisk
- [ ] Web3 transaction integration
- [ ] Morpho protocol connection
- [ ] Social lending features completion
- [ ] Real transaction history
- [ ] Mobile responsiveness optimization

### 🔄 Next Development Phase
- [ ] Deploy lending pool contracts
- [ ] Connect USDC token integration
- [ ] Implement Morpho vault deposits
- [ ] Build circle management system
- [ ] Add transaction execution layer
- [ ] Implement yield distribution
- [ ] Add analytics and reporting