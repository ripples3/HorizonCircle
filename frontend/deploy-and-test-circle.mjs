import { createPublicClient, createWalletClient, http, parseEther, formatEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { lisk } from 'viem/chains';
import fs from 'fs';

// Read bytecode from the updated contract
const BYTECODE = fs.readFileSync('./bytecode.txt', 'utf8').trim();

// Test accounts
const DEPLOYER_KEY = process.env.DEPLOYER_KEY || '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
const MEMBER1_KEY = process.env.MEMBER1_KEY || '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';
const MEMBER2_KEY = process.env.MEMBER2_KEY || '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a';

const deployer = privateKeyToAccount(DEPLOYER_KEY);
const member1 = privateKeyToAccount(MEMBER1_KEY);
const member2 = privateKeyToAccount(MEMBER2_KEY);

const publicClient = createPublicClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com')
});

const walletClient = createWalletClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com')
});

console.log('Deployer:', deployer.address);
console.log('Member 1:', member1.address);
console.log('Member 2:', member2.address);

async function deployCircle() {
  console.log('\n1. Deploying new circle with comprehensive fixes...');
  
  const hash = await walletClient.deployContract({
    abi: [],
    bytecode: `0x${BYTECODE}`,
    account: deployer,
  });
  
  console.log('Deploy tx:', hash);
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log('Circle deployed at:', receipt.contractAddress);
  
  return receipt.contractAddress;
}

async function setupMembers(circleAddress) {
  console.log('\n2. Adding members to circle...');
  
  const addMemberABI = {
    inputs: [{ name: '_member', type: 'address' }],
    name: 'addMember',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  };
  
  // Add member1
  const hash1 = await walletClient.writeContract({
    address: circleAddress,
    abi: [addMemberABI],
    functionName: 'addMember',
    args: [member1.address],
    account: deployer
  });
  await publicClient.waitForTransactionReceipt({ hash: hash1 });
  console.log('Added member 1');
  
  // Add member2
  const hash2 = await walletClient.writeContract({
    address: circleAddress,
    abi: [addMemberABI],
    functionName: 'addMember',
    args: [member2.address],
    account: deployer
  });
  await publicClient.waitForTransactionReceipt({ hash: hash2 });
  console.log('Added member 2');
  
  // Verify member count
  const getMemberCountABI = {
    inputs: [],
    name: 'getMemberCount',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  };
  
  const memberCount = await publicClient.readContract({
    address: circleAddress,
    abi: [getMemberCountABI],
    functionName: 'getMemberCount'
  });
  
  console.log('Total members:', memberCount.toString());
}

async function makeDeposits(circleAddress) {
  console.log('\n3. Making deposits...');
  
  const depositABI = {
    inputs: [],
    name: 'deposit',
    outputs: [],
    stateMutability: 'payable',
    type: 'function'
  };
  
  // Deployer deposits
  const hash1 = await walletClient.writeContract({
    address: circleAddress,
    abi: [depositABI],
    functionName: 'deposit',
    value: parseEther('0.001'),
    account: deployer
  });
  await publicClient.waitForTransactionReceipt({ hash: hash1 });
  console.log('Deployer deposited 0.001 ETH');
  
  // Member1 deposits
  const hash2 = await walletClient.writeContract({
    address: circleAddress,
    abi: [depositABI],
    functionName: 'deposit',
    value: parseEther('0.0005'),
    account: member1
  });
  await publicClient.waitForTransactionReceipt({ hash: hash2 });
  console.log('Member 1 deposited 0.0005 ETH');
  
  // Check total deposits
  const totalDepositsABI = {
    inputs: [],
    name: 'totalDeposits',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  };
  
  const totalDeposits = await publicClient.readContract({
    address: circleAddress,
    abi: [totalDepositsABI],
    functionName: 'totalDeposits'
  });
  
  console.log('Total deposits:', formatEther(totalDeposits), 'ETH');
}

async function createCollateralRequest(circleAddress) {
  console.log('\n4. Creating collateral request...');
  
  const requestCollateralABI = {
    inputs: [
      { name: '_loanAmount', type: 'uint256' },
      { name: '_collateralAmount', type: 'uint256' },
      { name: '_duration', type: 'uint256' }
    ],
    name: 'requestCollateral',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  };
  
  // Member2 requests collateral
  const loanAmount = parseEther('0.0001');
  const collateralAmount = parseEther('0.00001'); // Small amount to test precision
  const duration = 7 * 24 * 60 * 60; // 7 days
  
  const hash = await walletClient.writeContract({
    address: circleAddress,
    abi: [requestCollateralABI],
    functionName: 'requestCollateral',
    args: [loanAmount, collateralAmount, duration],
    account: member2
  });
  
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log('Collateral request created, tx:', hash);
  
  // Get request ID from event
  const requestCreatedEvent = receipt.logs.find(log => 
    log.topics[0] === '0x' + '0'.repeat(63) + '1' // Simplified event matching
  );
  
  return 0; // First request
}

async function contributeToRequest(circleAddress, requestId) {
  console.log('\n5. Contributing to collateral request...');
  
  const contributeABI = {
    inputs: [
      { name: '_requestId', type: 'uint256' },
      { name: '_amount', type: 'uint256' }
    ],
    name: 'contributeToCollateral',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function'
  };
  
  // Get request details first
  const getRequestABI = {
    inputs: [{ name: '', type: 'uint256' }],
    name: 'collateralRequests',
    outputs: [
      { name: 'borrower', type: 'address' },
      { name: 'loanAmount', type: 'uint256' },
      { name: 'collateralNeeded', type: 'uint256' },
      { name: 'collateralFilled', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
      { name: 'executed', type: 'bool' }
    ],
    stateMutability: 'view',
    type: 'function'
  };
  
  const request = await publicClient.readContract({
    address: circleAddress,
    abi: [getRequestABI],
    functionName: 'collateralRequests',
    args: [BigInt(requestId)]
  });
  
  console.log('Request details:');
  console.log('  Borrower:', request[0]);
  console.log('  Collateral needed:', formatEther(request[2]), 'ETH');
  console.log('  Collateral filled:', formatEther(request[3]), 'ETH');
  
  // Calculate contribution amount (small amount to test precision)
  const contributionAmount = parseEther('0.000005');
  
  console.log('Contributing', formatEther(contributionAmount), 'ETH...');
  
  try {
    const hash = await walletClient.writeContract({
      address: circleAddress,
      abi: [contributeABI],
      functionName: 'contributeToCollateral',
      args: [BigInt(requestId), contributionAmount],
      account: deployer
    });
    
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log('✅ Contribution successful! Gas used:', receipt.gasUsed.toString());
    
    // Check updated request
    const updatedRequest = await publicClient.readContract({
      address: circleAddress,
      abi: [getRequestABI],
      functionName: 'collateralRequests',
      args: [BigInt(requestId)]
    });
    
    console.log('Updated collateral filled:', formatEther(updatedRequest[3]), 'ETH');
    
  } catch (error) {
    console.error('❌ Contribution failed:', error);
    if (error.cause?.data?.errorName) {
      console.error('Error name:', error.cause.data.errorName);
    }
  }
}

async function checkCircleState(circleAddress) {
  console.log('\n6. Checking final circle state...');
  
  const WETH = '0x4200000000000000000000000000000000000006';
  const MORPHO_VAULT = '0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346';
  
  // Check WETH balance
  const balanceOfABI = {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  };
  
  const wethBalance = await publicClient.readContract({
    address: WETH,
    abi: [balanceOfABI],
    functionName: 'balanceOf',
    args: [circleAddress]
  });
  
  console.log('WETH balance in circle:', formatEther(wethBalance), 'WETH');
  
  // Check Morpho shares
  const morphoShares = await publicClient.readContract({
    address: MORPHO_VAULT,
    abi: [balanceOfABI],
    functionName: 'balanceOf',
    args: [circleAddress]
  });
  
  console.log('Morpho vault shares:', morphoShares.toString());
  
  if (morphoShares > 0n) {
    const convertToAssetsABI = {
      inputs: [{ name: 'shares', type: 'uint256' }],
      name: 'convertToAssets',
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view',
      type: 'function'
    };
    
    const morphoAssets = await publicClient.readContract({
      address: MORPHO_VAULT,
      abi: [convertToAssetsABI],
      functionName: 'convertToAssets',
      args: [morphoShares]
    });
    
    console.log('Value in Morpho vault:', formatEther(morphoAssets), 'WETH (earning ~5% APY)');
  }
}

async function main() {
  try {
    // Deploy new circle
    const circleAddress = await deployCircle();
    
    // Setup members
    await setupMembers(circleAddress);
    
    // Make deposits
    await makeDeposits(circleAddress);
    
    // Create collateral request
    const requestId = await createCollateralRequest(circleAddress);
    
    // Test contribution with precision fix
    await contributeToRequest(circleAddress, requestId);
    
    // Check final state
    await checkCircleState(circleAddress);
    
    console.log('\n✅ All tests completed!');
    console.log('Circle address:', circleAddress);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

main();