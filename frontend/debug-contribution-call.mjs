#!/usr/bin/env node

import { createPublicClient, http, formatEther, parseEther } from 'viem';
import { lisk } from 'viem/chains';

// Test data
const USER_ADDRESS = '0xAFA9CF6c504Ca060B31626879635c049E2De9E1c';
const CIRCLE_ADDRESS = '0x9472B1eaEEe7ed81C04CEB5520fac7180e08b806';
const CONTRIBUTION_AMOUNT = parseEther('0.00000265'); // Same as frontend
const REQUEST_ID = '0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef123456'; // Mock for testing

console.log('🔍 DEBUG CONTRIBUTE TO REQUEST SIMULATION');
console.log('==========================================');

// Create public client
const publicClient = createPublicClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com')
});

// Complete ABI for contributeToRequest function
const CONTRIBUTE_ABI = [
  {
    "inputs": [
      {"type": "bytes32", "name": "requestId"},
      {"type": "uint256", "name": "wethAmount"}
    ],
    "name": "contributeToRequest",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "user"}],
    "name": "getUserBalance",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "user"}],
    "name": "userShares",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "totalShares",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "totalDeposits",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "bytes32", "name": "requestId"}
    ],
    "name": "requests",
    "outputs": [
      {"type": "address", "name": "borrower"},
      {"type": "uint256", "name": "amountNeeded"},
      {"type": "address[]", "name": "requestedContributors"},
      {"type": "uint256", "name": "totalContributed"},
      {"type": "uint256", "name": "deadline"},
      {"type": "bool", "name": "fulfilled"},
      {"type": "bool", "name": "executed"},
      {"type": "string", "name": "purpose"},
      {"type": "uint256", "name": "createdAt"}
    ],
    "stateMutability": "view",
    "type": "function"
  }
];

async function simulateContribution() {
  try {
    console.log('⏳ Simulating contribution call...');
    console.log(`User: ${USER_ADDRESS}`);
    console.log(`Circle: ${CIRCLE_ADDRESS}`);
    console.log(`Contribution Amount: ${formatEther(CONTRIBUTION_AMOUNT)} ETH (${CONTRIBUTION_AMOUNT.toString()} wei)`);
    console.log('');

    // Get current user balance data  
    const userBalance = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: CONTRIBUTE_ABI,
      functionName: 'getUserBalance',
      args: [USER_ADDRESS]
    });

    const userShares = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: CONTRIBUTE_ABI,
      functionName: 'userShares',
      args: [USER_ADDRESS]
    });

    const totalShares = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: CONTRIBUTE_ABI,
      functionName: 'totalShares'
    });

    const totalDeposits = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: CONTRIBUTE_ABI,
      functionName: 'totalDeposits'
    });

    console.log('📊 CURRENT STATE:');
    console.log('=================');
    console.log(`User Balance: ${formatEther(userBalance)} ETH (${userBalance.toString()} wei)`);
    console.log(`User Shares: ${formatEther(userShares)} (${userShares.toString()} wei)`);
    console.log(`Total Shares: ${formatEther(totalShares)} (${totalShares.toString()} wei)`);
    console.log(`Total Deposits: ${formatEther(totalDeposits)} ETH (${totalDeposits.toString()} wei)`);
    console.log('');

    // Simulate the smart contract logic for contributeToRequest
    console.log('🔍 SIMULATING SMART CONTRACT LOGIC:');
    console.log('===================================');

    // Check 1: Does user have sufficient balance?
    console.log(`✓ Check 1: User has ${formatEther(userBalance)} ETH >= ${formatEther(CONTRIBUTION_AMOUNT)} ETH: ${userBalance >= CONTRIBUTION_AMOUNT ? '✅ PASS' : '❌ FAIL'}`);

    // Check 2: Calculate shares to withdraw
    const sharesToWithdraw = totalShares > 0n ? (CONTRIBUTION_AMOUNT * totalShares) / userBalance : 0n;
    console.log(`✓ Check 2: Shares to withdraw: ${formatEther(sharesToWithdraw)} (${sharesToWithdraw.toString()} wei)`);
    console.log(`✓ Check 2: User has ${formatEther(userShares)} >= ${formatEther(sharesToWithdraw)}: ${userShares >= sharesToWithdraw ? '✅ PASS' : '❌ FAIL'}`);

    // Check 3: Is contribution amount > 0?
    console.log(`✓ Check 3: Contribution amount > 0: ${CONTRIBUTION_AMOUNT > 0n ? '✅ PASS' : '❌ FAIL'}`);

    console.log('');

    // Show what the actual contract call would look like
    console.log('📞 SIMULATED FUNCTION CALL:');
    console.log('===========================');
    console.log(`Function: contributeToRequest`);
    console.log(`Address: ${CIRCLE_ADDRESS}`);
    console.log(`Args[0] (requestId): ${REQUEST_ID}`);
    console.log(`Args[1] (wethAmount): ${CONTRIBUTION_AMOUNT.toString()} wei`);
    console.log('');

    // The main validation checks that might fail:
    console.log('🚨 POTENTIAL FAILURE POINTS:');
    console.log('============================');

    if (userBalance < CONTRIBUTION_AMOUNT) {
      console.log('❌ LIKELY FAILURE: Insufficient vault balance');
      console.log(`   - User needs: ${formatEther(CONTRIBUTION_AMOUNT)} ETH`);
      console.log(`   - User has: ${formatEther(userBalance)} ETH`);
      console.log(`   - Shortfall: ${formatEther(CONTRIBUTION_AMOUNT - userBalance)} ETH`);
    }

    if (userShares < sharesToWithdraw) {
      console.log('❌ LIKELY FAILURE: Insufficient shares');
      console.log(`   - Shares needed: ${formatEther(sharesToWithdraw)}`);
      console.log(`   - User has: ${formatEther(userShares)}`);
      console.log(`   - Shortfall: ${formatEther(sharesToWithdraw - userShares)}`);
    }

    if (CONTRIBUTION_AMOUNT === 0n) {
      console.log('❌ LIKELY FAILURE: Zero contribution amount');
    }

    // Check if the user's calculation is mathematically consistent
    console.log('');
    console.log('🧮 MATHEMATICAL CONSISTENCY CHECK:');
    console.log('==================================');
    
    const expectedBalance = totalShares > 0n ? (userShares * totalDeposits) / totalShares : 0n;
    console.log(`Expected balance from shares: ${formatEther(expectedBalance)} ETH`);
    console.log(`Actual balance from contract: ${formatEther(userBalance)} ETH`);
    console.log(`Balance consistency: ${expectedBalance === userBalance ? '✅ CONSISTENT' : '⚠️ INCONSISTENT'}`);

    console.log('✅ Simulation complete!');

  } catch (error) {
    console.error('❌ Error during simulation:', error);
  }
}

simulateContribution();