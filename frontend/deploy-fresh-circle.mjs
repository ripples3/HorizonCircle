#!/usr/bin/env node

import { createWalletClient, createPublicClient, http, parseEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { lisk } from 'viem/chains';
import dotenv from 'dotenv';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

// Load environment variables
const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../contracts/.env') });

// Contract addresses
const REGISTRY_ADDRESS = '0x503c9eab64ee36af23e2d4801b0495a5804e5392';
const USER_ADDRESS = '0x8D0d8f902ba2DB13f0282F5262cD55d8930EB456';

// ABIs
const registryAbi = [
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
  }
];

const circleAbi = [
  {
    type: 'constructor',
    inputs: [
      { name: '_name', type: 'string' },
      { name: 'initialMembers', type: 'address[]' },
      { name: '_factory', type: 'address' }
    ],
    stateMutability: 'nonpayable'
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
    name: 'requestCollateral',
    inputs: [
      { name: 'amount', type: 'uint256' },
      { name: 'contributors', type: 'address[]' },
      { name: 'contributorAmounts', type: 'uint256[]' },
      { name: 'purpose', type: 'string' }
    ],
    outputs: [{ name: 'requestId', type: 'bytes32' }],
    stateMutability: 'nonpayable'
  }
];

// Load bytecode from contractDeployment.ts
const deploymentFile = readFileSync(join(__dirname, 'src/utils/contractDeployment.ts'), 'utf8');
const bytecodeMatch = deploymentFile.match(/export const HORIZON_CIRCLE_BYTECODE = '0x' \+ `(0x[0-9a-fA-F]+)`/);
const CIRCLE_BYTECODE = bytecodeMatch ? bytecodeMatch[1] : null;

if (!CIRCLE_BYTECODE) {
  console.error('❌ Could not extract bytecode from contractDeployment.ts');
  process.exit(1);
}

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

console.log('🚀 Deploying Fresh Circle with Updated Bytecode');
console.log('User to add:', USER_ADDRESS);
console.log('Deployer:', account.address);
console.log('Registry:', REGISTRY_ADDRESS);
console.log('Bytecode version:', CIRCLE_BYTECODE.slice(0, 20) + '...');

async function deployFreshCircle() {
  try {
    // Create circle with both user and deployer as members
    const circleName = 'Updated Circle ' + Date.now();
    const initialMembers = [account.address, USER_ADDRESS]; // Both users are members
    
    console.log('\n🔧 Creating circle:', circleName);
    console.log('Initial members:', initialMembers);
    
    // Deploy the circle contract with UPDATED bytecode
    const deployHash = await walletClient.deployContract({
      abi: circleAbi,
      bytecode: CIRCLE_BYTECODE,
      args: [circleName, initialMembers, REGISTRY_ADDRESS],
    });
    
    console.log('⏳ Deploy transaction sent:', deployHash);
    
    // Wait for deployment
    const receipt = await publicClient.waitForTransactionReceipt({ 
      hash: deployHash,
      confirmations: 2,
    });
    
    if (receipt.status !== 'success') {
      console.error('❌ Deployment failed');
      return;
    }
    
    const circleAddress = receipt.contractAddress;
    console.log('✅ Fresh circle deployed at:', circleAddress);
    console.log('🎯 This circle has the UPDATED bytecode with Morpho fixes!');
    
    // Register the circle
    console.log('\n📝 Registering circle in registry...');
    const registerHash = await walletClient.writeContract({
      address: REGISTRY_ADDRESS,
      abi: registryAbi,
      functionName: 'registerCircle',
      args: [circleAddress, circleName, initialMembers],
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
    
    console.log('✅ Circle registered successfully');
    
    // Make a small deposit to test functionality
    console.log('\n💰 Making test deposit of 0.001 ETH...');
    const depositHash = await walletClient.writeContract({
      address: circleAddress,
      abi: circleAbi,
      functionName: 'deposit',
      args: [],
      value: parseEther('0.001'),
    });
    
    console.log('⏳ Deposit transaction sent:', depositHash);
    
    const depositReceipt = await publicClient.waitForTransactionReceipt({ 
      hash: depositHash,
      confirmations: 2,
    });
    
    if (depositReceipt.status !== 'success') {
      console.error('❌ Deposit failed');
      return;
    }
    
    console.log('✅ Test deposit successful!');
    
    console.log('\n🎉 SUCCESS! Fresh circle ready for testing:');
    console.log('📍 Circle Address:', circleAddress);
    console.log('👤 User can now test:', USER_ADDRESS);
    console.log('💡 Try requestCollateral - should work without #1002 error!');
    console.log('🌐 Visit http://localhost:3000 to see the new circle');
    
  } catch (error) {
    console.error('\n❌ Error during deployment:', error.message);
    if (error.cause) {
      console.error('Cause:', error.cause);
    }
  }
}

// Run the deployment
deployFreshCircle();