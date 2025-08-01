#!/usr/bin/env node

import { createPublicClient, http, formatEther } from 'viem';
import { lisk } from 'viem/chains';

// User address that's having trouble
const USER_ADDRESS = '0xAFA9CF6c504Ca060B31626879635c049E2De9E1c';
const CIRCLE_ADDRESS = '0x9472B1eaEEe7ed81C04CEB5520fac7180e08b806'; // Current test circle

console.log('🔍 DEBUG USER BALANCE AND CIRCLE STATUS');
console.log('=====================================');
console.log(`User: ${USER_ADDRESS}`);
console.log(`Circle: ${CIRCLE_ADDRESS}`);
console.log('');

// Create public client
const publicClient = createPublicClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com')
});

// ABI for the functions we need
const LENDING_POOL_ABI = [
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
    "inputs": [{"type": "address", "name": "user"}],
    "name": "isCircleMember",
    "outputs": [{"type": "bool"}],
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
    "inputs": [],
    "name": "totalShares",
    "outputs": [{"type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getMembers",
    "outputs": [{"type": "address[]"}],
    "stateMutability": "view",
    "type": "function"
  }
];

async function checkUserStatus() {
  try {
    console.log('⏳ Checking user status on blockchain...');
    
    // Check if user is a member
    const isMember = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: 'isCircleMember',
      args: [USER_ADDRESS]
    });
    
    // Get user's current balance
    const userBalance = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: 'getUserBalance',
      args: [USER_ADDRESS]
    });
    
    // Get user's shares
    const userShares = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: 'userShares',
      args: [USER_ADDRESS]
    });
    
    // Get circle totals
    const totalDeposits = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: 'totalDeposits'
    });
    
    const totalShares = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: 'totalShares'
    });
    
    // Get circle members
    const members = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: 'getMembers'
    });
    
    // Get user's native ETH balance
    const nativeBalance = await publicClient.getBalance({
      address: USER_ADDRESS
    });
    
    console.log('📊 USER STATUS RESULTS:');
    console.log('========================');
    console.log(`✅ Is Circle Member: ${isMember}`);
    console.log(`💰 Native ETH Balance: ${formatEther(nativeBalance)} ETH`);
    console.log(`🏦 Vault Balance: ${formatEther(userBalance)} ETH (${userBalance.toString()} wei)`);
    console.log(`📈 User Shares: ${formatEther(userShares)} (${userShares.toString()} wei)`);
    console.log('');
    console.log('📊 CIRCLE TOTALS:');
    console.log('================');
    console.log(`💰 Total Deposits: ${formatEther(totalDeposits)} ETH`);
    console.log(`📈 Total Shares: ${formatEther(totalShares)}`);
    console.log(`👥 Member Count: ${members.length}`);
    console.log(`👥 Members: ${members.join(', ')}`);
    console.log('');
    
    // Calculate the contribution amount that would be needed (Ξ0.00000265)
    const requiredContribution = 2650000000000n; // 0.00000265 ETH in wei
    console.log('🎯 CONTRIBUTION ANALYSIS:');
    console.log('=========================');
    console.log(`Required Contribution: ${formatEther(requiredContribution)} ETH (${requiredContribution.toString()} wei)`);
    console.log(`Can User Afford?: ${userBalance >= requiredContribution ? '✅ YES' : '❌ NO'}`);
    
    if (userBalance < requiredContribution) {
      console.log(`❌ INSUFFICIENT BALANCE: User needs ${formatEther(requiredContribution - userBalance)} ETH more`);
    }
    
    // Check reasons why the transaction might fail
    console.log('');
    console.log('🔍 POTENTIAL FAILURE REASONS:');
    console.log('==============================');
    
    if (!isMember) {
      console.log('❌ FAILURE REASON: User is not a circle member');
    }
    
    if (userBalance === 0n) {
      console.log('❌ FAILURE REASON: User has no deposits in the vault');
    }
    
    if (userBalance < requiredContribution) {
      console.log('❌ FAILURE REASON: Insufficient vault balance');
    }
    
    if (userShares === 0n) {
      console.log('❌ FAILURE REASON: User has no shares (hasn\'t deposited)');
    }
    
    if (nativeBalance < 10n ** 16n) { // Less than 0.01 ETH
      console.log('⚠️  WARNING: Low native ETH balance for gas fees');
    }
    
    console.log('✅ Debug complete!');
    
  } catch (error) {
    console.error('❌ Error checking user status:', error);
  }
}

checkUserStatus();