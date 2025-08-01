import { createPublicClient, http, formatEther } from 'viem';

const client = createPublicClient({
  chain: { id: 1135 },
  transport: http('https://rpc.api.lisk.com'),
});

const circleAddress = '0xFa18bA025dfC33ac34E2AAe7548FCF1427757C71';
const requestId = '0xda086eefc5441ae4164ea3d0e930197adb6ed948dfc004fbe1df25bbaa8cddfa';
const contributor = '0x2Dd92C45c27Dfda626DBAf3Cba1fdccc95731Aba';

// Try to decode the request struct
try {
  console.log('Checking request state...\n');
  
  // Get individual fields since struct mapping doesn't work well
  const borrowerCall = await client.readContract({
    address: circleAddress,
    abi: [{
      type: 'function',
      name: 'requests',
      inputs: [{ name: '', type: 'bytes32' }],
      outputs: [
        { name: 'borrower', type: 'address' },
        { name: 'amountNeeded', type: 'uint256' },
        { name: 'requestedContributors', type: 'address[]' },
        { name: 'totalContributed', type: 'uint256' },
        { name: 'deadline', type: 'uint256' },
        { name: 'fulfilled', type: 'bool' },
        { name: 'executed', type: 'bool' },
        { name: 'purpose', type: 'string' },
        { name: 'createdAt', type: 'uint256' }
      ],
      stateMutability: 'view'
    }],
    functionName: 'requests',
    args: [requestId],
  });

  console.log('Full request data:', borrowerCall);
  console.log('\nParsed request:');
  console.log('- Borrower:', borrowerCall[0]);
  console.log('- Amount needed:', formatEther(borrowerCall[1]), 'ETH');
  console.log('- Requested contributors:', borrowerCall[2]);
  console.log('- Total contributed:', formatEther(borrowerCall[3]), 'ETH');
  console.log('- Deadline:', new Date(Number(borrowerCall[4]) * 1000).toISOString());
  console.log('- Fulfilled:', borrowerCall[5]);
  console.log('- Executed:', borrowerCall[6]);
  console.log('- Purpose:', borrowerCall[7]);
  console.log('- Created at:', new Date(Number(borrowerCall[8]) * 1000).toISOString());

  // Also check the specific contribution
  const contributionAmount = await client.readContract({
    address: circleAddress,
    abi: [{
      type: 'function',
      name: 'getRequestContributions',
      inputs: [
        { name: 'requestId', type: 'bytes32' },
        { name: 'contributor', type: 'address' }
      ],
      outputs: [{ name: '', type: 'uint256' }],
      stateMutability: 'view'
    }],
    functionName: 'getRequestContributions',
    args: [requestId, contributor],
  });

  console.log('\nContribution from', contributor + ':');
  console.log(formatEther(contributionAmount), 'ETH');

} catch (error) {
  console.error('Error:', error);
}