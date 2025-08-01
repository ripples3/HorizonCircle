import { decodeAbiParameters } from 'viem';

// Event data from the logs
const eventData = '0x00000000000000000000000000000000000000000000000000013e52b9abe000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000020000000000000000000000008d0d8f902ba2db13f0282f5262cd55d8930eb4560000000000000000000000002dd92c45c27dfda626dbaf3cba1fdccc95731aba0000000000000000000000000000000000000000000000000000000000000046436f6c6c61746572616c207265717565737420666f72206c6f616e2066726f6d20636972636c65203078393437322e2e2e6238303620283220636f6e7472696275746f7273290000000000000000000000000000000000000000000000000000';

try {
  const decoded = decodeAbiParameters(
    [
      { name: 'amount', type: 'uint256' },
      { name: 'contributors', type: 'address[]' },
      { name: 'purpose', type: 'string' }
    ],
    eventData
  );
  
  console.log('Decoded CollateralRequested event data:');
  console.log('Amount:', decoded[0], 'wei =', Number(decoded[0]) / 1e18, 'ETH');
  console.log('Contributors:');
  decoded[1].forEach((addr, i) => {
    console.log(`  ${i + 1}. ${addr}`);
  });
  console.log('Purpose:', decoded[2]);
  
  // Check if our user is in the list
  const targetUser = '0x2Dd92C45c27Dfda626DBAf3Cba1fdccc95731Aba';
  const isInList = decoded[1].some(addr => 
    addr.toLowerCase() === targetUser.toLowerCase()
  );
  console.log(`\n${targetUser} is ${isInList ? '✅' : '❌'} in the contributors list`);
  
} catch (error) {
  console.error('Error decoding:', error);
}