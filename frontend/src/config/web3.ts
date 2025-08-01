import { createConfig } from 'wagmi';
import { lisk } from 'wagmi/chains';
import { http } from 'viem';

// Alternative RPC endpoints for Lisk
const RPC_ENDPOINTS = {
  PRIMARY: 'https://rpc.api.lisk.com',
  // Add alternative endpoints if available
  // Consider using a dedicated RPC service like:
  // - Alchemy, Infura, QuickNode for production
  // - https://raas.gelato.network/rpc (as suggested in error)
};

// Lisk chain configuration
export const liskChain = {
  ...lisk,
  id: 1135,
  name: 'Lisk',
  nativeCurrency: {
    decimals: 18,
    name: 'Ethereum',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: {
      http: [RPC_ENDPOINTS.PRIMARY],
    },
    public: {
      http: [RPC_ENDPOINTS.PRIMARY],
    },
  },
  blockExplorers: {
    default: {
      name: 'Lisk Explorer',
      url: 'https://blockscout.lisk.com',
    },
  },
};

// Only Lisk chain supported
export const wagmiConfig = createConfig({
  chains: [liskChain],
  transports: {
    [liskChain.id]: http(RPC_ENDPOINTS.PRIMARY, {
      timeout: 30_000, // Increased timeout for rate-limited requests
      retryCount: 3, // Allow retries with backoff
      batch: {
        wait: 100, // Batch RPC calls with 100ms wait
      },
    }),
  },
  ssr: true,
});

// Contract addresses - CURRENT WORKING CONTRACTS (Jan 2025) ✅ USERS RECEIVE ETH
export const CONTRACT_ADDRESSES = {
  LENDING_POOL: '', // No default circle - users select their circle during borrow flow
  USDC_TOKEN: '0xA0b86a33E6441346a7f1c1c2eAb5c4A5eb13F6c8', // USDC on Lisk
  MORPHO_VAULT: '0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346', // Re7 WETH vault on Lisk
  REGISTRY: '0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE', // ✅ CORRECT: Registry with partial sync (3/7 circles)
  FACTORY: '0x95e4c63Ee7e82b94D75dDbF858F0D2D0600fcCdD', // ✅ FIXED: Actual working factory (7 circles created)
  IMPLEMENTATION: '0x763004aE80080C36ec99eC5f2dc3F2C260638A83', // ✅ CORRECT: HorizonCircleWithMorphoAuth
  LENDING_MODULE: '0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801', // ✅ FIXED: Now funded - users receive ETH
} as const;

// Contract ABIs - Actual deployed contract ABIs
export const CONTRACT_ABIS = {
  USDC: [
    // ERC20 standard functions
    'function balanceOf(address) view returns (uint256)',
    'function transfer(address to, uint256 amount) returns (bool)',
    'function approve(address spender, uint256 amount) returns (bool)',
    'function allowance(address owner, address spender) view returns (uint256)',
  ],
  
  // HorizonCircleFactoryLite ABI (simplified factory)
  FACTORY: [
    {
      type: 'function',
      name: 'createCircle',
      inputs: [
        { name: 'name', type: 'string' },
        { name: 'initialMembers', type: 'address[]' }
      ],
      outputs: [{ name: 'circleAddress', type: 'address' }],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'getCircleCount',
      inputs: [],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'getUserCircles',
      inputs: [{ name: 'user', type: 'address' }],
      outputs: [{ name: '', type: 'address[]' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'allCircles',
      inputs: [{ name: '', type: 'uint256' }],
      outputs: [{ name: '', type: 'address' }],
      stateMutability: 'view'
    },
    {
      type: 'event',
      name: 'CircleCreated',
      inputs: [
        { name: 'circleAddress', type: 'address', indexed: true },
        { name: 'name', type: 'string', indexed: false },
        { name: 'creator', type: 'address', indexed: true }
      ]
    }
  ],

  // CircleRegistry ABI - Industry standard registry pattern
  REGISTRY: [
    {
      type: 'function',
      name: 'registerCircle',
      inputs: [
        { name: 'circle', type: 'address' },
        { name: 'name', type: 'string' },
        { name: 'members', type: 'address[]' }
      ],
      outputs: [],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'getUserCircles',
      inputs: [{ name: 'user', type: 'address' }],
      outputs: [{ name: '', type: 'address[]' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'getCircleCount',
      inputs: [],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'allCircles',
      inputs: [{ name: '', type: 'uint256' }],
      outputs: [{ name: '', type: 'address' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'isCircle',
      inputs: [{ name: 'circle', type: 'address' }],
      outputs: [{ name: '', type: 'bool' }],
      stateMutability: 'view'
    },
    {
      type: 'event',
      name: 'CircleRegistered',
      inputs: [
        { name: 'circle', type: 'address', indexed: true },
        { name: 'name', type: 'string', indexed: false },
        { name: 'creator', type: 'address', indexed: true }
      ]
    }
  ],

  // HorizonCircle (LendingCircle) ABI - Key functions
  LENDING_POOL: [
    {
      type: 'receive',
      stateMutability: 'payable'
    },
    {
      type: 'function',
      name: 'deposit',
      inputs: [],
      outputs: [],
      stateMutability: 'payable'
    },
    {
      type: 'function',
      name: 'withdraw',
      inputs: [{ name: 'shares', type: 'uint256' }],
      outputs: [],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'getUserBalance',
      inputs: [{ name: 'user', type: 'address' }],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'userShares',
      inputs: [{ name: '', type: 'address' }],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'name',
      inputs: [],
      outputs: [{ name: '', type: 'string' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'isCircleMember',
      inputs: [{ name: '', type: 'address' }],
      outputs: [{ name: '', type: 'bool' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'totalShares',
      inputs: [],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'totalDeposits',
      inputs: [],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'getMembers',
      inputs: [],
      outputs: [{ name: '', type: 'address[]' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'getMemberCount',
      inputs: [],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'getAvailableBalance',
      inputs: [],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'requestCollateral',
      inputs: [
        { name: 'borrowAmount', type: 'uint256' },
        { name: 'collateralAmount', type: 'uint256' },
        { name: 'contributors', type: 'address[]' },
        { name: 'contributorAmounts', type: 'uint256[]' },
        { name: 'purpose', type: 'string' }
      ],
      outputs: [{ name: 'requestId', type: 'bytes32' }],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'contributeToRequest',
      inputs: [
        { name: 'requestId', type: 'bytes32' }
      ],
      outputs: [],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'declineRequest',
      inputs: [{ name: 'requestId', type: 'bytes32' }],
      outputs: [],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'executeRequest',
      inputs: [{ name: 'requestId', type: 'bytes32' }],
      outputs: [{ name: 'loanId', type: 'bytes32' }],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'allContributorsResponded',
      inputs: [{ name: 'requestId', type: 'bytes32' }],
      outputs: [{ name: '', type: 'bool' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'repayLoan',
      inputs: [{ name: 'loanId', type: 'bytes32' }],
      outputs: [],
      stateMutability: 'payable'
    },
    {
      type: 'function',
      name: 'addMember',
      inputs: [{ name: 'newMember', type: 'address' }],
      outputs: [],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'removeMember',
      inputs: [{ name: 'member', type: 'address' }],
      outputs: [],
      stateMutability: 'nonpayable'
    },
    {
      type: 'function',
      name: 'creator',
      inputs: [],
      outputs: [{ name: '', type: 'address' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'requests',
      inputs: [{ name: '', type: 'bytes32' }],
      outputs: [
        { name: 'borrower', type: 'address' },
        { name: 'borrowAmount', type: 'uint256' },
        { name: 'collateralNeeded', type: 'uint256' },
        { name: 'totalContributed', type: 'uint256' },
        { name: 'deadline', type: 'uint256' },
        { name: 'fulfilled', type: 'bool' },
        { name: 'executed', type: 'bool' },
        { name: 'purpose', type: 'string' },
        { name: 'createdAt', type: 'uint256' }
      ],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'activeLoans',
      inputs: [{ name: '', type: 'bytes32' }],
      outputs: [
        { name: 'borrower', type: 'address' },
        { name: 'principal', type: 'uint256' },
        { name: 'interestRate', type: 'uint256' },
        { name: 'startTime', type: 'uint256' },
        { name: 'duration', type: 'uint256' },
        { name: 'totalRepaid', type: 'uint256' },
        { name: 'wstETHCollateral', type: 'uint256' },
        { name: 'active', type: 'bool' },
        { name: 'requestId', type: 'bytes32' }
      ],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'userLoans',
      inputs: [{ name: '', type: 'address' }, { name: '', type: 'uint256' }],
      outputs: [{ name: '', type: 'bytes32' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'allLoans',
      inputs: [{ name: '', type: 'uint256' }],
      outputs: [{ name: '', type: 'bytes32' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'requestDeclines',
      inputs: [
        { name: 'requestId', type: 'bytes32' },
        { name: 'contributor', type: 'address' }
      ],
      outputs: [{ name: '', type: 'bool' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'getRequestContributions',
      inputs: [
        { name: 'requestId', type: 'bytes32' },
        { name: 'contributor', type: 'address' }
      ],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'getExpectedContribution',
      inputs: [
        { name: 'requestId', type: 'bytes32' },
        { name: 'contributor', type: 'address' }
      ],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'function',
      name: 'getBorrowingRate',
      inputs: [],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    },
    {
      type: 'event',
      name: 'Deposit',
      inputs: [
        { name: 'member', type: 'address', indexed: true },
        { name: 'amount', type: 'uint256', indexed: false },
        { name: 'shares', type: 'uint256', indexed: false }
      ]
    },
    {
      type: 'event',
      name: 'Withdraw',
      inputs: [
        { name: 'member', type: 'address', indexed: true },
        { name: 'amount', type: 'uint256', indexed: false },
        { name: 'shares', type: 'uint256', indexed: false }
      ]
    },
    {
      type: 'event',
      name: 'CollateralRequested',
      inputs: [
        { name: 'requestId', type: 'bytes32', indexed: true },
        { name: 'borrower', type: 'address', indexed: true },
        { name: 'amount', type: 'uint256', indexed: false },
        { name: 'contributors', type: 'address[]', indexed: false },
        { name: 'purpose', type: 'string', indexed: false }
      ]
    },
    {
      type: 'event',
      name: 'ContributionMade',
      inputs: [
        { name: 'requestId', type: 'bytes32', indexed: true },
        { name: 'contributor', type: 'address', indexed: true },
        { name: 'amount', type: 'uint256', indexed: false }
      ]
    },
    {
      type: 'event',
      name: 'RequestDeclined',
      inputs: [
        { name: 'requestId', type: 'bytes32', indexed: true },
        { name: 'contributor', type: 'address', indexed: true },
        { name: 'timestamp', type: 'uint256', indexed: false }
      ]
    },
    {
      type: 'event',
      name: 'LoanExecuted',
      inputs: [
        { name: 'requestId', type: 'bytes32', indexed: true },
        { name: 'loanId', type: 'bytes32', indexed: true },
        { name: 'borrower', type: 'address', indexed: true },
        { name: 'amount', type: 'uint256', indexed: false }
      ]
    },
    {
      type: 'function',
      name: 'directLTVWithdraw',
      inputs: [
        { name: 'borrowAmount', type: 'uint256' }
      ],
      outputs: [
        { name: 'loanId', type: 'bytes32' }
      ],
      stateMutability: 'nonpayable'
    }
  ],
} as const;