import { createPublicClient, http, formatEther, parseAbiItem } from 'viem';
import { lisk } from 'viem/chains';

const client = createPublicClient({
  chain: lisk,
  transport: http('https://rpc.api.lisk.com')
});

const TX_HASH = '0xafecd29ec8d4304edfb90391d567a04b948c577a023f44da4b9e848ca8aa1a8c';
const WETH = '0x4200000000000000000000000000000000000006';
const MORPHO_VAULT = '0x31832F2A97fD20664d76Cc421207669b55cE4BC0';

async function traceDeposit() {
  console.log('Tracing deposit transaction:', TX_HASH);
  console.log('---');
  
  // Get transaction receipt
  const receipt = await client.getTransactionReceipt({ hash: TX_HASH });
  console.log('Status:', receipt.status);
  console.log('Gas used:', receipt.gasUsed.toString());
  console.log('Logs count:', receipt.logs.length);
  console.log('---');
  
  // Look for WETH deposit event
  const wethDepositEvent = parseAbiItem('event Deposit(address indexed dst, uint256 wad)');
  
  for (const log of receipt.logs) {
    if (log.address.toLowerCase() === WETH.toLowerCase()) {
      try {
        const decoded = client.decodeEventLog({
          abi: [wethDepositEvent],
          data: log.data,
          topics: log.topics
        });
        console.log('WETH Deposit event:');
        console.log('  To:', decoded.args.dst);
        console.log('  Amount:', formatEther(decoded.args.wad), 'WETH');
      } catch {}
    }
    
    // Check for Morpho vault events
    if (log.address.toLowerCase() === MORPHO_VAULT.toLowerCase()) {
      console.log('Morpho vault event found at index', receipt.logs.indexOf(log));
      console.log('  Topics:', log.topics);
    }
  }
  
  // Check final WETH balance
  const balanceOfABI = {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  };
  
  const circleAddress = receipt.to;
  const wethBalance = await client.readContract({
    address: WETH,
    abi: [balanceOfABI],
    functionName: 'balanceOf',
    args: [circleAddress]
  });
  
  console.log('---');
  console.log('Circle WETH balance after tx:', formatEther(wethBalance), 'WETH');
}

traceDeposit().catch(console.error);