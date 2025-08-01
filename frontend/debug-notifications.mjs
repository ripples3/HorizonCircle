#!/usr/bin/env node

import { createPublicClient, http } from 'viem';
import { lisk } from 'viem/chains';

const CIRCLE_ADDRESS = '0x2e033fff4eb92adec543a0a2b601d59e8bc88c65'; // Updated circle
const USER_ADDRESS = '0x8D0d8f902ba2DB13f0282F5262cD55d8930EB456'; // User who should get notifications

const publicClient = createPublicClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com'),
});

console.log('🔍 Debugging Notifications');
console.log('Circle:', CIRCLE_ADDRESS);
console.log('User:', USER_ADDRESS);

async function debugNotifications() {
  try {
    console.log('\n📋 Checking for CollateralRequested events...');
    
    // Get recent events from the circle (last 1000 blocks)
    const currentBlock = await publicClient.getBlockNumber();
    const fromBlock = currentBlock - 1000n;
    const toBlock = 'latest';
    
    console.log('Searching from block:', fromBlock.toString(), 'to current block:', currentBlock.toString());
    
    const logs = await publicClient.getLogs({
      address: CIRCLE_ADDRESS,
      fromBlock,
      toBlock,
    });
    
    console.log(`Found ${logs.length} total events`);
    
    if (logs.length > 0) {
      console.log('\n📝 Recent events:');
      logs.forEach((log, i) => {
        console.log(`${i + 1}. Block: ${log.blockNumber}, Topics: ${log.topics.length}`);
        console.log(`   First topic: ${log.topics[0]?.slice(0, 20)}...`);
        console.log(`   Data length: ${log.data?.length || 0} chars`);
      });
    } else {
      console.log('\n❌ No events found in the last 1000 blocks');
      console.log('This could mean:');
      console.log('1. No collateral requests have been made');
      console.log('2. The circle is new and has no activity');
      console.log('3. The circle address is incorrect');
    }
    
    // Check if the user is actually a member
    console.log('\n👤 Checking circle membership...');
    const isMember = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: [{
        type: 'function',
        name: 'isCircleMember',
        inputs: [{ name: '', type: 'address' }],
        outputs: [{ name: '', type: 'bool' }],
        stateMutability: 'view'
      }],
      functionName: 'isCircleMember',
      args: [USER_ADDRESS],
    });
    
    console.log(`User ${USER_ADDRESS} is member:`, isMember);
    
    if (!isMember) {
      console.log('❌ User is not a member - they cannot receive notifications');
      console.log('💡 Only circle members can receive collateral request notifications');
    }
    
    // Get all members
    const members = await publicClient.readContract({
      address: CIRCLE_ADDRESS,
      abi: [{
        type: 'function',
        name: 'getMembers',
        inputs: [],
        outputs: [{ name: '', type: 'address[]' }],
        stateMutability: 'view'
      }],
      functionName: 'getMembers',
      args: [],
    });
    
    console.log('\n👥 Circle members:');
    members.forEach((member, i) => {
      console.log(`${i + 1}. ${member} ${member.toLowerCase() === USER_ADDRESS.toLowerCase() ? '← Target user' : ''}`);
    });
    
    console.log('\n💡 To test notifications:');
    console.log('1. Make a collateral request from the circle creator');
    console.log('2. Include the target user in the contributors list');
    console.log('3. Check that the CollateralRequested event is emitted');
    console.log('4. Verify the frontend notification system picks it up');
    
  } catch (error) {
    console.error('❌ Error debugging notifications:', error.message);
  }
}

debugNotifications();