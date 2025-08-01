# HorizonCircle Smart Contracts

DeFi-powered cooperative lending platform for the Philippine BNPL market.

## Quick Start

### 1. Setup Environment

Create `.env` file (copy from `.env.example`):
```bash
PRIVATE_KEY=your_private_key_here
RPC_URL=https://rpc.api.lisk.com
```

### 2. Deploy to Lisk Mainnet

```bash
# Deploy and test with small ETH amount
forge script script/DeployAndTest.s.sol --rpc-url $RPC_URL --broadcast --verify

# Or deploy only
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify
```

### 3. Test Integration

```bash
# Test token contracts and Velodrome integration
forge script script/TestIntegrations.s.sol --rpc-url $RPC_URL --broadcast
```

## Contract Addresses

### Lisk Mainnet (Chain ID: 1135)

**Token Contracts:**
- WETH: `0x4200000000000000000000000000000000000006`
- wstETH: `0x76D8de471F54aAA87784119c60Df1bbFc852C415`
- USDC: `0x05D032ac25d322df992303dCa074EE7392C117b9`

**Velodrome DEX:**
- Router: `0x3a63171DD9BebF4D07BC782FECC7eb0b890C2A45`
- Factory V2 (AMM): `0x31832f2a97Fd20664D76Cc421207669b55CE4BC0`
- Factory CL (Slipstream): `0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F`

## Architecture

### Core Contracts

1. **HorizonCircleFactory.sol** - Deploys and manages circle instances
2. **HorizonCircle.sol** - Individual circle vault with DeFi integration
3. **VelodromeHelper.sol** - ETH/wstETH swap utilities

### Key Features

- **Social Lending**: Members contribute collateral for each other's loans
- **Yield Earning**: Deposits earn yield through Morpho protocol (planned)
- **Cost Savings**: 67-80% cheaper than traditional Philippine lending
- **wstETH Collateral**: Continues earning staking rewards while borrowed against

## Development

### Compile
```bash
forge build
```

### Test
```bash
forge test
```

### Gas Reports
```bash
forge test --gas-report
```

## Usage Flow

1. **Create Circle**: `factory.createCircle("Family", [member1, member2])`
2. **Deposit ETH**: `circle.deposit{value: 1 ether}()`
3. **Request Loan**: `circle.requestCollateral(5000, [contributors], "Medical")`
4. **Contribute**: `circle.contributeToRequest{value: 1 ether}(requestId)`
5. **Execute Loan**: `circle.executeRequest(requestId)` (converts to wstETH, borrows)
6. **Repay**: `circle.repayLoan{value: repayAmount}(loanId)`

## Economic Model

- **Base Yield**: 5% APY on deposits (Morpho ETH vault)
- **Borrowing Rate**: 8% APR gross cost
- **Effective Rate**: ~0.1% APR net cost (after yield offset)
- **Social Premium**: Contributors earn 12% vs 10% for social risk

## Security

- **ReentrancyGuard**: All external functions protected
- **Access Control**: Member-only functions and creator privileges
- **Slippage Protection**: 0.5% max slippage on swaps
- **Interest Calculations**: Time-based with proper precision