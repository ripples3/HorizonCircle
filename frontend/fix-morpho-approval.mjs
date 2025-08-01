import { createWalletClient, createPublicClient, http, parseAbi, formatEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { lisk } from 'viem/chains';
import dotenv from 'dotenv';

dotenv.config();

if (!process.env.PRIVATE_KEY) {
  console.error('Please set PRIVATE_KEY in .env file');
  process.exit(1);
}

const account = privateKeyToAccount(process.env.PRIVATE_KEY);
const circleAddress = '0x6D209f83285838a6D3c695225604f26C9DFA1Dfa';
const morphoVault = '0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346';

const client = createPublicClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com')
});

const walletClient = createWalletClient({
  account,
  chain: lisk,
  transport: http('https://rpc.api.lisk.com')
});

console.log('Fixing Morpho approval issue...\n');
console.log('Account:', account.address);

// First check if we're a member of the circle
const circleAbi = parseAbi([
  'function isCircleMember(address) view returns (bool)',
  'function creator() view returns (address)'
]);

try {
  const isMember = await client.readContract({
    address: circleAddress,
    abi: circleAbi,
    functionName: 'isCircleMember',
    args: [account.address]
  });
  
  const creator = await client.readContract({
    address: circleAddress,
    abi: circleAbi,
    functionName: 'creator',
    args: []
  });
  
  console.log('Is member:', isMember);
  console.log('Circle creator:', creator);
  console.log('Is creator:', creator.toLowerCase() === account.address.toLowerCase());
  
  if (!isMember && creator.toLowerCase() !== account.address.toLowerCase()) {
    console.error('Error: Account is not a member or creator of this circle');
    process.exit(1);
  }
  
  // The workaround: We need to call a function on the circle that will make it approve itself
  // Unfortunately, there's no direct way to do this without modifying the contract
  // Let's check if there's any existing approval
  
  const morphoAbi = parseAbi([
    'function allowance(address owner, address spender) view returns (uint256)',
    'function balanceOf(address) view returns (uint256)'
  ]);
  
  const allowance = await client.readContract({
    address: morphoVault,
    abi: morphoAbi,
    functionName: 'allowance',
    args: [circleAddress, circleAddress]
  });
  
  const shares = await client.readContract({
    address: morphoVault,
    abi: morphoAbi,
    functionName: 'balanceOf',
    args: [circleAddress]
  });
  
  console.log('\nCurrent state:');
  console.log('Circle Morpho shares:', shares);
  console.log('Circle self-allowance:', allowance);
  
  console.log('\nUnfortunately, the circle needs to approve itself to spend its Morpho shares.');
  console.log('This requires either:');
  console.log('1. Updating the contract to use redeem() instead of withdraw()');
  console.log('2. Adding a function to make the circle approve itself');
  console.log('3. Using a different approach for withdrawal');
  
  console.log('\nPossible immediate workaround:');
  console.log('Deploy a new circle with updated bytecode that includes the fix');
  
} catch (error) {
  console.error('Error:', error);
}