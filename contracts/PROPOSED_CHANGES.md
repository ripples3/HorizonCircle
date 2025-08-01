# Smart Contract Enhancement Proposal: Targeted Collateral Request Notifications

## Problem
The current `CollateralRequested` event doesn't include contributor addresses, so the frontend cannot filter notifications to show them only to targeted users.

## Current Event (Line 61 in HorizonCircle.sol)
```solidity
event CollateralRequested(bytes32 indexed requestId, address indexed borrower, uint256 amount, string purpose);
```

## Solution 1: Enhanced Event with Contributors Array

### Change the event definition:
```solidity
event CollateralRequested(
    bytes32 indexed requestId, 
    address indexed borrower, 
    uint256 amount, 
    address[] contributors,  // ADD THIS
    string purpose
);
```

### Update the emission (Line 224):
```solidity
emit CollateralRequested(requestId, msg.sender, amount, contributors, purpose);
```

## Solution 2: Individual Contributor Events (Alternative)

### Add a new event:
```solidity
event ContributorRequested(
    bytes32 indexed requestId,
    address indexed contributor,
    uint256 amountRequested
);
```

### Emit for each contributor in requestCollateral function:
```solidity
// After creating the request
for (uint256 i = 0; i < contributors.length; i++) {
    emit ContributorRequested(requestId, contributors[i], amount / contributors.length);
}
```

## Frontend Hook Update

With Solution 1, update the event listening in `useBalance.ts`:

```typescript
// Get CollateralRequested events from this circle
const logs = await publicClient.getLogs({
  address: circleAddress as `0x${string}`,
  event: parseAbiItem('event CollateralRequested(bytes32 indexed requestId, address indexed borrower, uint256 amount, address[] contributors, string purpose)'),
  fromBlock: 'earliest',
  toBlock: 'latest',
});

// Filter to only show requests where current user is in contributors array
for (const log of logs) {
  const { requestId, borrower, amount, contributors, purpose } = log.args;
  
  // Only show if current user is in the contributors array
  if (contributors.includes(address.toLowerCase())) {
    allRequests.push({
      id: requestId,
      requestId,
      requestor: borrower,
      amount: parseFloat(formatEther(amount)),
      purpose,
      circleAddress,
      // ... rest of request data
    });
  }
}
```

## Deployment Required

These changes require redeploying the smart contracts:

1. Update `HorizonCircle.sol` with the enhanced event
2. Update frontend ABI in `web3.ts`
3. Deploy new contracts using `DeployLite.s.sol`
4. Update contract addresses in frontend config

## Benefits

✅ **Targeted Notifications**: Only requested contributors see requests
✅ **No Mock Data**: Use real blockchain events  
✅ **Scalable**: Works with any number of contributors
✅ **Efficient**: Single event query with client-side filtering

## Implementation Priority

**High Priority** - This fixes the core notification targeting issue preventing real event usage.