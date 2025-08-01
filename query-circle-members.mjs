#!/usr/bin/env node

import { createPublicClient, http, getContract } from 'viem';
import { lisk } from 'viem/chains';

// Lisk configuration
const liskChain = {
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
      http: ['https://rpc.api.lisk.com'],
    },
    public: {
      http: ['https://rpc.api.lisk.com'],
    },
  },
};

// Contract address
const CIRCLE_ADDRESS = '0x22Fb7A14F4eb65e333bB903247e5f97C192C98f4';

// ABI for the functions we need
const CIRCLE_ABI = [
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
    name: 'name',
    inputs: [],
    outputs: [{ name: '', type: 'string' }],
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
    name: 'totalShares',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view'
  }
];

async function queryCircle() {
  console.log('Querying HorizonCircle Contract on Lisk Mainnet');
  console.log('===========================================');
  console.log(`Contract Address: ${CIRCLE_ADDRESS}`);
  console.log(`Network: Lisk (Chain ID: ${liskChain.id})`);
  console.log(`RPC: ${liskChain.rpcUrls.default.http[0]}\n`);

  try {
    // Create public client
    const publicClient = createPublicClient({
      chain: liskChain,
      transport: http(liskChain.rpcUrls.default.http[0]),
    });

    // Create contract instance
    const contract = getContract({
      address: CIRCLE_ADDRESS,
      abi: CIRCLE_ABI,
      client: publicClient,
    });

    // Query contract data
    console.log('Fetching circle data...\n');

    // Get circle name
    const circleName = await contract.read.name();
    console.log(`Circle Name: ${circleName}`);

    // Get member count
    const memberCount = await contract.read.getMemberCount();
    console.log(`Member Count: ${memberCount}`);

    // Get all members
    const members = await contract.read.getMembers();
    console.log(`\nMembers (${members.length}):`);
    members.forEach((member, index) => {
      console.log(`  ${index + 1}. ${member}`);
    });

    // Get total deposits
    const totalDeposits = await contract.read.totalDeposits();
    console.log(`\nTotal Deposits: ${totalDeposits} wei (${Number(totalDeposits) / 1e18} ETH)`);

    // Get total shares
    const totalShares = await contract.read.totalShares();
    console.log(`Total Shares: ${totalShares}`);

    // Verify member count matches
    if (Number(memberCount) !== members.length) {
      console.log(`\n⚠️  WARNING: Member count mismatch!`);
      console.log(`   getMemberCount() returns: ${memberCount}`);
      console.log(`   getMembers().length is: ${members.length}`);
    } else {
      console.log(`\n✅ Member count verified: ${memberCount} members`);
    }

  } catch (error) {
    console.error('\n❌ Error querying contract:', error.message);
    if (error.cause) {
      console.error('Cause:', error.cause);
    }
  }
}

// Run the query
queryCircle();