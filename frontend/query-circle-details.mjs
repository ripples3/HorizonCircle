#!/usr/bin/env node

import { createPublicClient, http, getContract, formatEther, parseAbi } from 'viem';
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

// Contract addresses
const CIRCLE_ADDRESS = '0x9697b91369c4768df91d25d86e0d19fb4e7c6983';
const REGISTRY_ADDRESS = '0xd9Cb92798992588E3011c2192b81C3454D294e8f';
const FACTORY_ADDRESS = '0x3bA7eED94C0706C9e99ddD002c8eAA163127F3F2';

// Extended ABI with more functions
const CIRCLE_ABI = parseAbi([
  'function getMembers() view returns (address[])',
  'function getMemberCount() view returns (uint256)',
  'function name() view returns (string)',
  'function totalDeposits() view returns (uint256)',
  'function totalShares() view returns (uint256)',
  'function memberDeposits(address) view returns (uint256)',
  'function memberShares(address) view returns (uint256)',
  'function isMember(address) view returns (bool)',
  'event MemberAdded(address indexed member)',
  'event DepositMade(address indexed member, uint256 amount)',
  'event CollateralRequested(address indexed from, address indexed to, uint256 requestId, uint256 amount)'
]);

async function queryCircleDetails() {
  console.log('=== HorizonCircle Detailed Query ===');
  console.log(`Circle: ${CIRCLE_ADDRESS}`);
  console.log(`Registry: ${REGISTRY_ADDRESS}`);
  console.log(`Factory: ${FACTORY_ADDRESS}`);
  console.log(`Network: Lisk Mainnet (Chain ID: ${liskChain.id})`);
  console.log('=====================================\n');

  // Create public client
  const publicClient = createPublicClient({
    chain: liskChain,
    transport: http(liskChain.rpcUrls.default.http[0]),
  });

  // 1. Check Registry Status
  console.log('1. Registry Status:');
  console.log('==================');
  try {
    const registryAbi = parseAbi([
      'function circles(address) view returns (bool)',
      'event CircleRegistered(address indexed circle)'
    ]);

    const isRegistered = await publicClient.readContract({
      address: REGISTRY_ADDRESS,
      abi: registryAbi,
      functionName: 'circles',
      args: [CIRCLE_ADDRESS]
    });
    console.log(`Circle is registered: ${isRegistered ? '✅ YES' : '❌ NO'}`);

    // Check for registration event
    const registrationEvents = await publicClient.getLogs({
      address: REGISTRY_ADDRESS,
      event: {
        name: 'CircleRegistered',
        args: { circle: CIRCLE_ADDRESS },
        inputs: [{ name: 'circle', type: 'address', indexed: true }],
        type: 'event'
      },
      fromBlock: 0n,
      toBlock: 'latest'
    });
    
    if (registrationEvents.length > 0) {
      console.log(`Registration event found at block ${registrationEvents[0].blockNumber}`);
    } else {
      console.log('No registration event found');
    }
  } catch (e) {
    console.error(`Error checking registry: ${e.message}`);
  }

  // 2. Check Factory Creation
  console.log('\n2. Factory Creation:');
  console.log('===================');
  try {
    const factoryAbi = parseAbi([
      'event CircleCreated(address indexed circle, address indexed creator)'
    ]);

    const creationEvents = await publicClient.getLogs({
      address: FACTORY_ADDRESS,
      event: {
        name: 'CircleCreated',
        args: { circle: CIRCLE_ADDRESS },
        inputs: [
          { name: 'circle', type: 'address', indexed: true },
          { name: 'creator', type: 'address', indexed: true }
        ],
        type: 'event'
      },
      fromBlock: 0n,
      toBlock: 'latest'
    });
    
    if (creationEvents.length > 0) {
      console.log(`✅ Created via factory by ${creationEvents[0].args.creator}`);
      console.log(`Creation block: ${creationEvents[0].blockNumber}`);
    } else {
      console.log('❌ Not created via factory (likely direct deployment)');
    }
  } catch (e) {
    console.error(`Error checking factory: ${e.message}`);
  }

  // 3. Circle Details
  console.log('\n3. Circle Details:');
  console.log('=================');
  try {
    // Create contract instance
    const contract = getContract({
      address: CIRCLE_ADDRESS,
      abi: CIRCLE_ABI,
      client: publicClient,
    });

    // Get basic info
    const circleName = await contract.read.name();
    const memberCount = await contract.read.getMemberCount();
    const members = await contract.read.getMembers();
    const totalDeposits = await contract.read.totalDeposits();
    const totalShares = await contract.read.totalShares();

    console.log(`Name: ${circleName}`);
    console.log(`Members: ${memberCount}`);
    console.log(`Total Deposits: ${formatEther(totalDeposits)} ETH`);
    console.log(`Total Shares: ${totalShares}`);

    // Get detailed member information
    console.log('\n4. Member Details:');
    console.log('=================');
    
    for (let i = 0; i < members.length; i++) {
      const member = members[i];
      console.log(`\nMember ${i + 1}: ${member}`);
      
      try {
        // Get deposits
        const deposit = await contract.read.memberDeposits([member]);
        console.log(`  Deposits: ${formatEther(deposit)} ETH`);
        
        // Get shares
        const shares = await contract.read.memberShares([member]);
        console.log(`  Shares: ${shares}`);
        
        // Calculate percentage
        if (totalShares > 0n) {
          const percentage = (Number(shares) / Number(totalShares) * 100).toFixed(2);
          console.log(`  Ownership: ${percentage}%`);
        }
      } catch (e) {
        console.log(`  Error reading member data: ${e.message}`);
      }
    }

    // Check contract balance
    const contractBalance = await publicClient.getBalance({ address: CIRCLE_ADDRESS });
    console.log(`\n5. Contract Balance:`);
    console.log('==================');
    console.log(`ETH Balance: ${formatEther(contractBalance)} ETH`);
    console.log(`Matches deposits: ${contractBalance === totalDeposits ? '✅ YES' : '❌ NO'}`);

    // Check for events
    console.log('\n6. Recent Events:');
    console.log('================');
    
    // Deposit events
    const depositEvents = await publicClient.getLogs({
      address: CIRCLE_ADDRESS,
      event: {
        name: 'DepositMade',
        args: {},
        inputs: [
          { name: 'member', type: 'address', indexed: true },
          { name: 'amount', type: 'uint256', indexed: false }
        ],
        type: 'event'
      },
      fromBlock: 0n,
      toBlock: 'latest'
    });
    
    console.log(`Deposits: ${depositEvents.length} events`);
    depositEvents.forEach(event => {
      console.log(`  ${event.args.member} deposited ${formatEther(event.args.amount)} ETH`);
    });

    // Collateral request events
    const collateralEvents = await publicClient.getLogs({
      address: CIRCLE_ADDRESS,
      event: {
        name: 'CollateralRequested',
        args: {},
        inputs: [
          { name: 'from', type: 'address', indexed: true },
          { name: 'to', type: 'address', indexed: true },
          { name: 'requestId', type: 'uint256', indexed: false },
          { name: 'amount', type: 'uint256', indexed: false }
        ],
        type: 'event'
      },
      fromBlock: 0n,
      toBlock: 'latest'
    });
    
    console.log(`\nCollateral Requests: ${collateralEvents.length} events`);
    collateralEvents.forEach(event => {
      console.log(`  Request ${event.args.requestId}: ${event.args.from} → ${event.args.to} for ${formatEther(event.args.amount)} ETH`);
    });

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.cause) {
      console.error('Cause:', error.cause);
    }
  }
}

// Run the query
queryCircleDetails();