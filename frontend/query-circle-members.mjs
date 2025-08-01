#!/usr/bin/env node

import { createPublicClient, http, getContract, parseAbi } from 'viem';
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
const CIRCLE_ADDRESS = '0x9697b91369c4768df91d25d86e0d19fb4e7c6983';

// ABI for the functions we need
const CIRCLE_ABI = parseAbi([
  // Member functions
  'function members(uint256) view returns (address)',
  'function memberCount() view returns (uint256)',
  'function isMember(address) view returns (bool)',
  'function getMembers() view returns (address[])',
  'function getMemberCount() view returns (uint256)',
  // Other functions
  'function name() view returns (string)',
  'function totalDeposits() view returns (uint256)',
  'function totalShares() view returns (uint256)',
  // Events
  'event MemberAdded(address indexed member)',
  'event MemberRemoved(address indexed member)'
]);

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

    // First check if this is a proxy by looking at bytecode
    console.log('Checking contract bytecode...');
    const bytecode = await publicClient.getBytecode({ address: CIRCLE_ADDRESS });
    console.log(`Bytecode length: ${bytecode ? bytecode.length : 0} characters`);
    if (bytecode && bytecode.length < 200) {
      console.log('⚠️  This appears to be a minimal proxy contract');
      console.log(`Bytecode: ${bytecode}\n`);
    }

    // Query contract data
    console.log('Fetching circle data...\n');

    // Try different member reading approaches
    let members = [];
    let memberCount = 0;

    // Approach 1: Try getMembers() function
    try {
      members = await contract.read.getMembers();
      console.log(`✅ getMembers() returned ${members.length} members`);
    } catch (e) {
      console.log(`❌ getMembers() failed: ${e.message}`);
    }

    // Approach 2: Try getMemberCount() function
    try {
      memberCount = await contract.read.getMemberCount();
      console.log(`✅ getMemberCount() returned: ${memberCount}`);
    } catch (e) {
      console.log(`❌ getMemberCount() failed: ${e.message}`);
    }

    // Approach 3: Try memberCount() function (different name)
    if (memberCount === 0) {
      try {
        memberCount = await contract.read.memberCount();
        console.log(`✅ memberCount() returned: ${memberCount}`);
      } catch (e) {
        console.log(`❌ memberCount() failed: ${e.message}`);
      }
    }

    // Approach 4: Try reading members array directly if we have a count
    if (memberCount > 0 && members.length === 0) {
      console.log(`\nTrying to read members array directly...`);
      const tempMembers = [];
      for (let i = 0; i < memberCount; i++) {
        try {
          const member = await contract.read.members([BigInt(i)]);
          tempMembers.push(member);
          console.log(`  Member ${i}: ${member}`);
        } catch (e) {
          console.log(`  Could not read member ${i}: ${e.message}`);
        }
      }
      if (tempMembers.length > 0) {
        members = tempMembers;
      }
    }

    // Try to get other contract data
    try {
      const circleName = await contract.read.name();
      console.log(`\nCircle Name: ${circleName}`);
    } catch (e) {
      console.log(`\n❌ Could not read circle name: ${e.message}`);
    }

    try {
      const totalDeposits = await contract.read.totalDeposits();
      console.log(`Total Deposits: ${totalDeposits} wei (${Number(totalDeposits) / 1e18} ETH)`);
    } catch (e) {
      console.log(`❌ Could not read totalDeposits: ${e.message}`);
    }

    try {
      const totalShares = await contract.read.totalShares();
      console.log(`Total Shares: ${totalShares}`);
    } catch (e) {
      console.log(`❌ Could not read totalShares: ${e.message}`);
    }

    // Check for MemberAdded events
    console.log('\n\nChecking for MemberAdded events...');
    try {
      const events = await publicClient.getLogs({
        address: CIRCLE_ADDRESS,
        event: {
          name: 'MemberAdded',
          args: {},
          inputs: [{ name: 'member', type: 'address', indexed: true }],
          type: 'event'
        },
        fromBlock: 0n,
        toBlock: 'latest'
      });
      
      console.log(`Found ${events.length} MemberAdded events`);
      const uniqueMembers = new Set();
      events.forEach((event, i) => {
        const member = event.args.member;
        uniqueMembers.add(member);
        console.log(`  Event ${i}: Member added: ${member} at block ${event.blockNumber} (tx: ${event.transactionHash})`);
      });
      
      if (events.length > 0) {
        console.log(`\nUnique members from events: ${uniqueMembers.size}`);
        Array.from(uniqueMembers).forEach((member, i) => {
          console.log(`  ${i + 1}. ${member}`);
        });
      }
    } catch (e) {
      console.error(`❌ Error fetching MemberAdded events: ${e.message}`);
    }

    // Final summary
    console.log('\n\n=== SUMMARY ===');
    if (members.length > 0) {
      console.log(`Members found via contract calls: ${members.length}`);
      members.forEach((member, i) => {
        console.log(`  ${i + 1}. ${member}`);
      });
    } else {
      console.log('No members found via contract calls');
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