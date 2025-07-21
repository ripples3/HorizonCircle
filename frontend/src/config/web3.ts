import { createConfig } from 'wagmi';
import { lisk } from 'wagmi/chains';
import { http } from 'viem';
import { createPublicClient } from 'viem';

// Lisk chain configuration
export const liskChain = {
  ...lisk,
  id: 1135,
  name: 'Lisk',
  nativeCurrency: {
    decimals: 18,
    name: 'Lisk',
    symbol: 'LSK',
  },
  rpcUrls: {
    default: {
      http: [
        `https://lisk-mainnet.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_API_KEY}`,
        'https://rpc.api.lisk.com',
      ],
    },
    public: {
      http: ['https://rpc.api.lisk.com'],
    },
  },
  blockExplorers: {
    default: {
      name: 'Lisk Explorer',
      url: 'https://blockscout.lisk.com',
    },
  },
};

// Wagmi configuration
export const wagmiConfig = createConfig({
  chains: [liskChain],
  transports: {
    [liskChain.id]: http(),
  },
  ssr: true, // Enable server-side rendering
});

// Contract addresses (to be filled in later)
export const CONTRACT_ADDRESSES = {
  LENDING_POOL: '',
  USDC_TOKEN: '0xA0b86a33E6441346a7f1c1c2eAb5c4A5eb13F6c8', // USDC on Lisk (placeholder)
  MORPHO_VAULT: '',
} as const;

// Contract ABIs (to be filled in later)
export const CONTRACT_ABIS = {
  USDC: [
    // ERC20 standard functions
    'function balanceOf(address) view returns (uint256)',
    'function transfer(address to, uint256 amount) returns (bool)',
    'function approve(address spender, uint256 amount) returns (bool)',
    'function allowance(address owner, address spender) view returns (uint256)',
  ],
  LENDING_POOL: [
    // HorizonCircle lending functions (to be implemented)
    'function deposit(uint256 amount) external',
    'function borrow(uint256 amount) external',
    'function repay(uint256 amount) external',
    'function getUserData(address user) view returns (uint256 balance, uint256 borrowed, uint256 available)',
  ],
} as const;