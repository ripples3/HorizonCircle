#!/usr/bin/env node

import { createWalletClient, createPublicClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { lisk } from 'viem/chains';
import dotenv from 'dotenv';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

// Load environment variables
const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../contracts/.env') });

// Get registry bytecode
const registryJson = JSON.parse(readFileSync(join(__dirname, '../contracts/out/CircleRegistry.sol/CircleRegistry.json'), 'utf8'));
const REGISTRY_BYTECODE = registryJson.bytecode.object;

const registryAbi = [
  {
    type: 'constructor',
    inputs: [],
    stateMutability: 'nonpayable'
  },
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
  }
];

// Setup clients
const account = privateKeyToAccount(process.env.PRIVATE_KEY);
const publicClient = createPublicClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com'),
});

const walletClient = createWalletClient({
  account,
  chain: lisk,
  transport: http('https://rpc.api.lisk.com'),
});

console.log('🧹 Deploying Fresh Clean Registry');
console.log('This will create a completely new registry with 0 circles');

async function deployCleanRegistry() {
  try {
    // Deploy fresh registry
    console.log('\n📋 Deploying new CircleRegistry...');
    const deployHash = await walletClient.deployContract({
      abi: registryAbi,
      bytecode: `0x${REGISTRY_BYTECODE}`,
      args: [],
    });
    
    console.log('⏳ Deploy transaction sent:', deployHash);
    
    const receipt = await publicClient.waitForTransactionReceipt({ 
      hash: deployHash,
      confirmations: 2,
    });
    
    if (receipt.status !== 'success') {
      console.error('❌ Registry deployment failed');
      return;
    }
    
    const registryAddress = receipt.contractAddress;
    console.log('✅ Fresh registry deployed at:', registryAddress);
    
    // Verify it's empty
    const userAddress = '0x8D0d8f902ba2DB13f0282F5262cD55d8930EB456';
    const circles = await publicClient.readContract({
      address: registryAddress,
      abi: registryAbi,
      functionName: 'getUserCircles',
      args: [userAddress],
    });
    
    console.log(`\n✅ Registry is clean - user has ${circles.length} circles`);
    
    // Now register only the new circle
    const NEW_CIRCLE = '0x2e033fff4eb92adec543a0a2b601d59e8bc88c65';
    const CIRCLE_NAME = 'Updated Circle 1753720317939';
    const MEMBERS = [
      '0xAFA9CF6c504Ca060B31626879635c049E2De9E1c',
      '0x8D0d8f902ba2DB13f0282F5262cD55d8930EB456'
    ];
    
    console.log('\n📝 Registering only the new circle...');
    console.log('Circle:', NEW_CIRCLE);
    console.log('Name:', CIRCLE_NAME);
    
    const registerHash = await walletClient.writeContract({
      address: registryAddress,
      abi: registryAbi,
      functionName: 'registerCircle',
      args: [NEW_CIRCLE, CIRCLE_NAME, MEMBERS],
    });
    
    console.log('⏳ Register transaction sent:', registerHash);
    
    const registerReceipt = await publicClient.waitForTransactionReceipt({ 
      hash: registerHash,
      confirmations: 2,
    });
    
    if (registerReceipt.status !== 'success') {
      console.error('❌ Registration failed');
      return;
    }
    
    console.log('✅ New circle registered');
    
    // Verify final state
    const finalCircles = await publicClient.readContract({
      address: registryAddress,
      abi: registryAbi,
      functionName: 'getUserCircles',
      args: [userAddress],
    });
    
    console.log(`\n🎉 SUCCESS! Clean registry ready:`);
    console.log(`📍 Registry Address: ${registryAddress}`);
    console.log(`👤 User now has ${finalCircles.length} circle(s):`);
    finalCircles.forEach((circle, i) => {
      console.log(`   ${i + 1}. ${circle}`);
    });
    
    console.log(`\n💡 Next steps:`);
    console.log(`1. Update frontend web3.ts to use registry: ${registryAddress}`);
    console.log(`2. Test notifications with clean state`);
    console.log(`3. Only the updated circle with Morpho fixes will be available`);
    
  } catch (error) {
    console.error('\n❌ Error during deployment:', error.message);
  }
}

deployCleanRegistry();