#!/usr/bin/env node

import { createPublicClient, http } from 'viem';
import { lisk } from 'viem/chains';

const USER_ADDRESS = '0x8D0d8f902ba2DB13f0282F5262cD55d8930EB456';
const REGISTRY_ADDRESS = '0x503c9eab64ee36af23e2d4801b0495a5804e5392';

const registryAbi = [
  {
    type: 'function',
    name: 'getUserCircles',
    inputs: [{ name: 'user', type: 'address' }],
    outputs: [{ name: '', type: 'address[]' }],
    stateMutability: 'view'
  }
];

const publicClient = createPublicClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com'),
});

console.log('🔍 Debug: Checking user circles for frontend hook');
console.log('User:', USER_ADDRESS);
console.log('Registry:', REGISTRY_ADDRESS);

async function debugUserCircles() {
  try {
    console.log('\n📋 Direct registry query (same as useUserCirclesDirect hook):');
    
    const userCircles = await publicClient.readContract({
      address: REGISTRY_ADDRESS,
      abi: registryAbi,
      functionName: 'getUserCircles',
      args: [USER_ADDRESS],
    });
    
    console.log('✅ Query successful!');
    console.log('Result:', userCircles);
    console.log('Circle count:', userCircles.length);
    
    if (userCircles.length > 0) {
      console.log('\n📝 Circles found:');
      userCircles.forEach((circle, i) => {
        console.log(`  ${i + 1}. ${circle}`);
      });
      
      console.log('\n💡 The user SHOULD see these circles in the frontend');
      console.log('💡 If they see "Your Circles (0)", it could be:');
      console.log('   - Wrong wallet connected');
      console.log('   - React query cache issue');
      console.log('   - Authentication not complete');
      console.log('   - Case sensitivity in address comparison');
      
    } else {
      console.log('\n❌ No circles found for this user');
      console.log('💡 This would explain why they see "Your Circles (0)"');
    }
    
  } catch (error) {
    console.error('\n❌ Error querying registry:', error.message);
  }
}

debugUserCircles();