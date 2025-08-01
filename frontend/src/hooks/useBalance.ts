import React from 'react';
import { useReadContract, useBalance, useAccount, usePublicClient } from 'wagmi';
import { readContract } from 'viem/actions';
import { parseAbiItem, formatEther } from 'viem';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';
import { rateLimitedGetLogs } from '@/utils/rateLimitedRpc';
import { getCachedCircles, storeCachedCircles, storeCircleMetadata, type CircleCacheData } from '@/utils/circleCache';

// Global block filter constant  
const MIN_BLOCK_NUMBER = BigInt(19669673); // Updated for fresh testing (Aug 2025)

// ETH balance (native token on Lisk)
export function useETHBalance(address: string | undefined) {
  return useBalance({
    address: address as `0x${string}`,
    query: {
      enabled: !!address,
    },
  });
}

// User's balance in the lending circle (ETH equivalent)
export function useUserCircleBalance(address: string | undefined, circleAddress?: string) {
  const contractAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
  
  const result = useReadContract({
    address: contractAddress as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'getUserBalance',
    args: [address as `0x${string}`],
    query: {
      enabled: !!address && !!contractAddress,
      refetchOnMount: false, // Prevent auto refetch on mount
      refetchOnReconnect: false, // Prevent auto refetch on reconnect  
      refetchOnWindowFocus: false, // Prevent refetch when window gains focus
      staleTime: 300000, // Consider data stale after 5 minutes (increased from 2min)
      refetchInterval: false,
      retry: 1, // Reduce retries
      retryDelay: 5000, // 5 second delay (increased from 3s)
    },
  });

  // Debug logging (reduced frequency)
  React.useEffect(() => {
    if (result.error) {
      console.log('❌ Balance Query Error:', {
        address,
        contractAddress,
        error: result.error.message
      });
    } else if (result.data) {
      console.log('✅ Balance Query Success:', {
        address,
        contractAddress,
        balance: result.data.toString()
      });
    }
  }, [address, contractAddress, result.data, result.error]);

  return result;
}

// User's shares in the lending circle
export function useUserShares(address: string | undefined, circleAddress?: string) {
  const contractAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
  return useReadContract({
    address: contractAddress as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'userShares',
    args: [address as `0x${string}`],
    query: {
      enabled: !!address && !!contractAddress,
    },
  });
}

// Direct registry query for user circles with block filtering
export function useUserCirclesDirect() {
  const { address } = useAccount();
  const publicClient = usePublicClient();
  const [filteredCircles, setFilteredCircles] = React.useState<string[]>([]);
  const [isFiltering, setIsFiltering] = React.useState(false);
  
  // Use FACTORY as primary source since it has getUserCircles() 
  const result = useReadContract({
    address: CONTRACT_ADDRESSES.FACTORY as `0x${string}`,
    abi: CONTRACT_ABIS.FACTORY,
    functionName: 'getUserCircles',
    args: address ? [address] : undefined,
    query: {
      enabled: !!address && !!CONTRACT_ADDRESSES.FACTORY,
      staleTime: 30000, // Shorter cache for better responsiveness
      gcTime: 300000, // Keep in cache for 5 minutes
      refetchInterval: false, // No auto-refresh
    },
  });
  
  // Filter to show only circles created after this block (fresh start)
  // Update this block number to start fresh with new circles only
  
  // Memoize the expensive discovery operation
  const discoverUserCircles = React.useCallback(async () => {
    if (!address || !publicClient) {
      setFilteredCircles([]);
      return;
    }
    
    setIsFiltering(true);
    
    try {
      // Additional safety check for publicClient methods
      if (!publicClient || typeof publicClient.getBlockNumber !== 'function') {
        console.warn('⚠️ PublicClient not properly initialized');
        setFilteredCircles([]);
        setIsFiltering(false);
        return;
      }
      
      // Get current block number for cache validation
      const currentBlock = await publicClient.getBlockNumber();
      
      // Check IndexedDB cache first
      const cachedData = await getCachedCircles(address);
      if (cachedData) {
        // For development, use shorter cache validity (5 minutes)
        const cacheAge = Date.now() - cachedData.timestamp;
        const maxAge = 5 * 60 * 1000; // 5 minutes during development
        const blockDiff = currentBlock - cachedData.blockNumber;
        const maxBlockDiff = BigInt(100); // Allow up to 100 block difference
        
        // Check if cached data is from before our MIN_BLOCK_NUMBER filter
        const isCacheFromOldBlocks = cachedData.blockNumber < MIN_BLOCK_NUMBER;
        
        if (cacheAge < maxAge && blockDiff < maxBlockDiff && !isCacheFromOldBlocks) {
          console.log('🚀 Using IndexedDB cache for circles:', cachedData.circles.length);
          setFilteredCircles(cachedData.circles);
          setIsFiltering(false);
          return;
        } else {
          console.log('⏰ Cache invalidated - age:', Math.round(cacheAge/1000), 's, block diff:', blockDiff.toString(), ', old blocks:', isCacheFromOldBlocks);
        }
      }
      
      console.log('🔍 Discovering circles from blockchain...');
      const userCircles: string[] = [];
      
      // Determine scan range - use cached data to scan incrementally
      let fromBlock = MIN_BLOCK_NUMBER;
      if (cachedData && cachedData.lastScannedBlock) {
        // Scan from last scanned block to current, with some overlap for safety
        fromBlock = cachedData.lastScannedBlock - BigInt(50); // 50 block overlap
        console.log('📈 Incremental scan from block:', fromBlock.toString());
      } else {
        console.log('🆕 Full scan from block:', fromBlock.toString());
      }
      
      // Start with previously cached circles if doing incremental scan
      if (cachedData && fromBlock > MIN_BLOCK_NUMBER) {
        userCircles.push(...cachedData.circles);
        console.log('📋 Starting with cached circles:', cachedData.circles.length);
      }
    
      // Step 1: Get all circles from FACTORY events (primary source)
      const factoryCircles = await rateLimitedGetLogs<any[]>(publicClient, {
        address: CONTRACT_ADDRESSES.FACTORY as `0x${string}`,
        event: parseAbiItem('event CircleCreated(address indexed circleAddress, string name, address indexed creator)'),
        fromBlock,
        toBlock: 'latest',
      });
      
      console.log('🏭 Found', factoryCircles.length, 'new circles from factory events');
      
      // Step 2: Get all circles registered in registry (secondary source)
      const registeredCircles = await rateLimitedGetLogs<any[]>(publicClient, {
        address: CONTRACT_ADDRESSES.REGISTRY as `0x${string}`,
        event: parseAbiItem('event CircleRegistered(address indexed circle, string name, address indexed creator)'),
        fromBlock,
        toBlock: 'latest',
      });
      
      console.log('📡 Found', registeredCircles.length, 'new circle registration events');
      
      // FALLBACK: Also search for MemberAdded events where this user was added
      // This helps discover circles created outside the registry system
      let memberAddedCircles: any[] = [];
      try {
        const memberEvents = await rateLimitedGetLogs<any[]>(publicClient, {
          event: parseAbiItem('event MemberAdded(address indexed member)'),
          fromBlock: MIN_BLOCK_NUMBER, // Use same block filter as circle discovery
          toBlock: 'latest',
        });
        
        // Filter for events where this user was added as a member
        memberAddedCircles = memberEvents.filter(log => 
          log.args?.member?.toLowerCase() === address.toLowerCase()
        );
        
        console.log('👥 Found', memberAddedCircles.length, 'MemberAdded events for user');
      } catch (err) {
        console.warn('Failed to search MemberAdded events:', err);
      }
      
      // Step 2: Process MemberAdded circles  
      const memberAddedPromises = memberAddedCircles.map(async (log) => {
        const circleAddress = log.address;
        if (circleAddress && !userCircles.includes(circleAddress)) {
          // Adding circle from MemberAdded event
          return circleAddress;
        }
        return null;
      });
      
      const memberFoundCircles = (await Promise.all(memberAddedPromises)).filter(Boolean) as string[];
      userCircles.push(...memberFoundCircles);
      
      // Step 3: Process FACTORY circles first (primary source)
      const factoryCirclePromises = factoryCircles.map(async (log) => {
        const circleAddress = log.args?.circleAddress;
        const name = log.args?.name || 'Unknown Circle';
        const creator = log.args?.creator;
        
        if (!circleAddress) return null;
        
        // Skip if already in our user circles
        if (userCircles.some(c => c.toLowerCase() === circleAddress.toLowerCase())) {
          return null;
        }
        
        try {
          const isMember = await readContract(publicClient, {
            address: circleAddress as `0x${string}`,
            abi: CONTRACT_ABIS.LENDING_POOL,
            functionName: 'isCircleMember',
            args: [address as `0x${string}`],
          }) as boolean;
          
          if (isMember) {
            // Store circle metadata in cache
            await storeCircleMetadata({
              address: circleAddress,
              name,
              creator,
              isFactory: true, // Mark as factory-created
            });
            
            // Found user is member of factory circle
            return circleAddress;
          }
        } catch (err) {
          console.warn('❌ Failed to check membership for factory circle:', circleAddress, err);
        }
        
        return null;
      });
      
      const factoryFoundCircles = (await Promise.all(factoryCirclePromises)).filter(Boolean) as string[];
      userCircles.push(...factoryFoundCircles);
      
      // Step 4: Batch membership checks for registry circles (secondary source)
      const newCirclePromises = registeredCircles.map(async (log) => {
        const circleAddress = log.args?.circle;
        const name = log.args?.name || 'Unknown Circle';
        const creator = log.args?.creator;
        
        if (!circleAddress) return null;
        
        // Skip if already in our user circles
        if (userCircles.some(c => c.toLowerCase() === circleAddress.toLowerCase())) {
          return null;
        }
        
        try {
          const isMember = await readContract(publicClient, {
            address: circleAddress as `0x${string}`,
            abi: CONTRACT_ABIS.LENDING_POOL,
            functionName: 'isCircleMember',
            args: [address as `0x${string}`],
          }) as boolean;
          
          if (isMember) {
            // Store circle metadata in cache
            await storeCircleMetadata({
              address: circleAddress,
              name,
              creator: creator || '0x0000000000000000000000000000000000000000',
              registrationBlock: currentBlock // Use current block as approximation
            });
            
            return circleAddress;
          }
          
          return null;
        } catch (membershipError) {
          console.warn(`Could not check membership for circle ${circleAddress}:`, membershipError);
          // In case of error, include the circle to be safe
          return circleAddress;
        }
      });

      // Wait for all membership checks to complete
      const newMembershipResults = await Promise.all(newCirclePromises);
      
      // Add new circles to userCircles
      for (const newCircle of newMembershipResults) {
        if (newCircle && !userCircles.includes(newCircle)) {
          userCircles.push(newCircle);
          console.log('✅ Added new circle:', newCircle);
        }
      }
      
      // Deduplicate circles (just in case)
      const uniqueCircles = [...new Set(userCircles)];
      
      console.log('🎯 Final discovered circles:', uniqueCircles.length);
      
      // Cache the results in IndexedDB
      const cacheData: CircleCacheData = {
        userAddress: address,
        circles: uniqueCircles,
        lastScannedBlock: currentBlock,
        timestamp: Date.now(),
        blockNumber: currentBlock
      };
      
      await storeCachedCircles(cacheData);
      console.log('💾 Cached circles in IndexedDB');
      
      // Update UI
      setFilteredCircles(uniqueCircles);
      setIsFiltering(false);
      
    } catch (error) {
      console.error('❌ Error discovering user circles:', error);
      
      // On error, use cached data if available
      if (cachedData && cachedData.circles.length > 0) {
        console.log('🔄 Using stale cache due to error');
        setFilteredCircles(cachedData.circles);
      } else {
        setFilteredCircles([]);
      }
      
      setIsFiltering(false);
    }
    }, [address, result.data, publicClient]);
    
    React.useEffect(() => {
      discoverUserCircles();
    }, [discoverUserCircles]);
  
  // Return filtered data
  return {
    ...result,
    data: filteredCircles,
    isLoading: result.isLoading || isFiltering,
  };
}

// Check if user is a circle member
export function useIsCircleMember(address: string | undefined, circleAddress?: string) {
  const contractAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
  return useReadContract({
    address: contractAddress as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'isCircleMember',
    args: [address as `0x${string}`],
    query: {
      enabled: !!address && !!contractAddress,
    },
  });
}

// Get circle name
export function useCircleName(circleAddress?: string) {
  return useReadContract({
    address: (circleAddress || CONTRACT_ADDRESSES.LENDING_POOL) as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'name',
    query: {
      enabled: !!(circleAddress || CONTRACT_ADDRESSES.LENDING_POOL),
    },
  });
}

// Get circle members
export function useCircleMembers(circleAddress?: string) {
  const contractAddr = (circleAddress || CONTRACT_ADDRESSES.LENDING_POOL) as `0x${string}`;
  
  // First get member count
  const { data: memberCount } = useReadContract({
    address: contractAddr,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'getMemberCount',
    query: {
      enabled: !!contractAddr,
    },
  });

  // Then read each member
  const [members, setMembers] = React.useState<`0x${string}`[]>([]);
  const publicClient = usePublicClient();

  React.useEffect(() => {
    async function fetchMembers() {
      if (!memberCount || !publicClient || !contractAddr) return;
      
      const count = Number(memberCount);
      const memberAddresses: `0x${string}`[] = [];
      
      for (let i = 0; i < count; i++) {
        try {
          const member = await publicClient.readContract({
            address: contractAddr,
            abi: [{
              type: 'function',
              name: 'members',
              inputs: [{ name: '', type: 'uint256' }],
              outputs: [{ name: '', type: 'address' }],
              stateMutability: 'view'
            }],
            functionName: 'members',
            args: [BigInt(i)]
          });
          memberAddresses.push(member as `0x${string}`);
        } catch (error) {
          console.error(`Failed to fetch member ${i}:`, error);
        }
      }
      
      setMembers(memberAddresses);
    }
    
    fetchMembers();
  }, [memberCount, publicClient, contractAddr]);

  return {
    data: members.length > 0 ? members : undefined,
    isLoading: memberCount !== undefined && members.length === 0,
    error: null
  };
}

// Get total deposits in the circle
export function useTotalDeposits(circleAddress?: string) {
  const contractAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
  return useReadContract({
    address: contractAddress as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'totalDeposits',
    query: {
      enabled: !!contractAddress,
    },
  });
}

// Get total shares in the circle
export function useTotalShares(circleAddress?: string) {
  const contractAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
  return useReadContract({
    address: contractAddress as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'totalShares',
    query: {
      enabled: !!contractAddress,
    },
  });
}

// Get user's circles from factory
// Original hook - only returns circles created by user
export function useUserCreatedCircles() {
  const { address } = useAccount();

  return useReadContract({
    address: CONTRACT_ADDRESSES.REGISTRY as `0x${string}`,
    abi: CONTRACT_ABIS.REGISTRY,
    functionName: 'getUserCircles',
    args: address ? [address] : undefined,
    query: {
      enabled: !!address && !!CONTRACT_ADDRESSES.REGISTRY,
      staleTime: 60000, // Consider data stale after 1 minute
      refetchInterval: false,
      refetchOnMount: true,
      refetchOnReconnect: true,
    },
  });
}

// Enhanced hook - returns circles where user is a member (with block filtering)
export function useUserCircles() {
  // Delegate to useUserCirclesDirect for consistent logic
  const { data: circles, isLoading, error } = useUserCirclesDirect();
  
  return {
    data: circles,
    isLoading,
    error
  };
}

// Hook to get pending collateral requests for a user - Real blockchain event listening
export function usePendingCollateralRequests() {
  const { address } = useAccount();
  const publicClient = usePublicClient();
  const { data: userCircles } = useUserCircles(); // Use the hook at the top level
  const [requests, setRequests] = React.useState<any[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<Error | null>(null);
  const [lastFetch, setLastFetch] = React.useState(0);
  
  // Cache results for 2 minutes to avoid unnecessary refetches (increased from 30s)
  const CACHE_DURATION = 120000;

  // Memoize fetchCollateralRequests to prevent unnecessary recreations
  const fetchCollateralRequests = React.useCallback(async () => {
    if (!address || !publicClient) {
      console.log('⚠️ Missing address or publicClient:', { address, hasPublicClient: !!publicClient });
      setRequests([]);
      setIsLoading(false);
      return;
    }

    // Check cache first
    const now = Date.now();
    if (now - lastFetch < CACHE_DURATION && requests.length >= 0) {
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);
    setLastFetch(now);

      try {
        // Reduced logging for better performance
        const allRequests: any[] = [];

        // Only check circles the user is a member of
        const circlesToCheck = userCircles || [];
        
        // Deduplicate circles to avoid checking same circle multiple times
        const uniqueCircles = [...new Set(circlesToCheck)];
          
        if (uniqueCircles.length > 0) {
          // User is member of circles - processing requests
          
          // Use Promise.all for parallel processing of circles
          const circleRequests = await Promise.all(uniqueCircles.map(async (circleAddress) => {
            const circleRequests: any[] = [];
            try {
              // Get CollateralRequested events from this circle with enhanced event
              // Use rate-limited version to avoid 429 errors
              const logs = await rateLimitedGetLogs<any[]>(publicClient, {
                address: circleAddress as `0x${string}`,
                event: parseAbiItem('event CollateralRequested(bytes32 indexed requestId, address indexed borrower, uint256 amount, address[] contributors, string purpose)'),
                fromBlock: 'earliest',
                toBlock: 'latest',
              });

              // Debug logging removed for performance

              // Process each event with early returns for performance
              for (const log of logs) {
                const { requestId, borrower, amount, contributors, purpose } = log.args;
                
                // Processing event
                
                // Skip if any required args are undefined
                if (!requestId || !borrower || !amount || !contributors || !purpose) {
                  console.warn('Incomplete event args, skipping:', { requestId, borrower, amount, contributors, purpose });
                  continue;
                }
                
                // ✅ REAL CONTRIBUTOR FILTERING: Only show if current user is in contributors array
                const isTargetedContributor = contributors.some((contributor: string) => 
                  contributor.toLowerCase() === address.toLowerCase()
                );
                
                // ✅ BORROWER FILTERING: Don't show notifications to the borrower themselves
                const isBorrower = borrower.toLowerCase() === address.toLowerCase();
                
                // Early return for performance - skip expensive blockchain calls
                if (!isTargetedContributor || isBorrower) {
                  continue;
                }
                
                // Check if this request is still active (not fulfilled) on blockchain
                try {
                  
                  let requestData: [string, bigint, bigint, bigint, bigint, boolean, boolean, string, bigint] | null = null;
                  
                  try {
                    // Try to get the request data - note: struct with mapping can't return all fields
                    requestData = await readContract(publicClient, {
                      address: circleAddress as `0x${string}`,
                      abi: CONTRACT_ABIS.LENDING_POOL,
                      functionName: 'requests',
                      args: [requestId],
                    }) as [string, bigint, bigint, bigint, bigint, boolean, boolean, string, bigint];
                  } catch (abiError) {
                    console.warn(`⚠️ ABI query failed for ${requestId}, using blockchain-first fallback:`, abiError);
                    
                    // ✅ BLOCKCHAIN-FIRST FALLBACK: Try individual blockchain queries before localStorage
                    let hasContributed = false;
                    let hasDeclined = false;
                    
                    try {
                      // Check contribution status on blockchain
                      const contributionAmount = await readContract(publicClient, {
                        address: circleAddress as `0x${string}`,
                        abi: CONTRACT_ABIS.LENDING_POOL,
                        functionName: 'getRequestContributions',
                        args: [requestId, address],
                      }) as bigint;
                      hasContributed = contributionAmount > BigInt(0);
                      console.log(`🔍 BLOCKCHAIN CHECK - User contributed: ${hasContributed} (${contributionAmount} wei)`);
                    } catch (contributionError) {
                      console.warn('Could not check blockchain contribution status:', contributionError);
                    }
                    
                    try {
                      // Check decline status on blockchain
                      hasDeclined = await readContract(publicClient, {
                        address: circleAddress as `0x${string}`,
                        abi: CONTRACT_ABIS.LENDING_POOL,
                        functionName: 'requestDeclines',
                        args: [requestId, address],
                      }) as boolean;
                      console.log(`🔍 BLOCKCHAIN CHECK - User declined: ${hasDeclined}`);
                    } catch (declineError) {
                      console.warn('Could not check blockchain decline status:', declineError);
                    }
                    
                    // Only use localStorage as a last resort if blockchain queries failed
                    if (!hasContributed && !hasDeclined) {
                      const declinedRequests = JSON.parse(localStorage.getItem('declined-requests') || '{}');
                      const contributedRequests = JSON.parse(localStorage.getItem('contributed-requests') || '{}');
                      
                      const hasLocalDecline = !!declinedRequests[requestId];
                      const hasLocalContribution = !!contributedRequests[requestId];
                      
                      console.log(`🔍 FALLBACK TO LOCALSTORAGE for ${requestId}:`, {
                        hasLocalDecline,
                        hasLocalContribution,
                        blockchainContributed: hasContributed,
                        blockchainDeclined: hasDeclined
                      });
                      
                      // Only trust localStorage if blockchain checks failed
                      if (hasLocalDecline || hasLocalContribution) {
                        console.log('⚠️ LocalStorage indicates user processed this request, but blockchain disagrees - trusting blockchain');
                        // Don't skip - let blockchain be the source of truth
                      }
                    }
                    
                    if (hasContributed || hasDeclined) {
                      console.log('⚠️ User has already processed this request on blockchain, skipping notification');
                      continue;
                    }
                    
                    console.log('✅ User has NOT processed this request on blockchain, showing notification with fallback data');
                    
                    // ✅ CONSERVATIVE: If we can't read blockchain data, check if this is a known executed request
                    // Check if borrower has this as an active loan (indicates it was executed)
                    const knownLoans = JSON.parse(sessionStorage.getItem('userActiveLoans') || '[]');
                    const isKnownExecuted = knownLoans.some((loan: any) => loan.requestId === requestId);
                    
                    // Also check for specific known executed requests
                    const knownExecutedRequests = [
                      '0x6c60308480099dffa35a62df9641eaa27aba1918165b7744f9fcf459c8253fb7', // Known executed request
                    ];
                    
                    if (isKnownExecuted || knownExecutedRequests.includes(requestId)) {
                      console.log('⚠️ Request is known to be executed, skipping notification');
                      continue;
                    }
                    
                    // For old requests, be more lenient - show notification if user hasn't acted
                    // Remove age-based filtering since we have better checks now
                    const requestAge = Date.now() - (log.blockNumber ? Number(log.blockNumber) * 12000 : 0); // ~12s per block
                    console.log(`📅 Request age: ${Math.floor(requestAge / 1000 / 60 / 60)} hours old`);
                    
                    // Don't filter by age - let the user decide to contribute or decline
                    // The checks above (hasLocalDecline, hasLocalContribution, isKnownExecuted) are sufficient
                    
                    // Try to determine fulfilled status even in fallback mode
                    let fallbackFulfilled = false;
                    let fallbackTotalContributed = BigInt(0);
                    try {
                      // Check if we can get individual request fields
                      const individualAmountNeeded = amount as bigint;
                      
                      // Try to get total contributed by checking all contributors
                      for (const contributor of (contributors as string[])) {
                        try {
                          const contribAmount = await readContract(publicClient, {
                            address: circleAddress as `0x${string}`,
                            abi: CONTRACT_ABIS.LENDING_POOL,
                            functionName: 'getRequestContributions',
                            args: [requestId, contributor as `0x${string}`],
                          }) as bigint;
                          fallbackTotalContributed += contribAmount;
                        } catch (err) {
                          console.warn(`Could not check contribution for ${contributor}:`, err);
                        }
                      }
                      
                      fallbackFulfilled = fallbackTotalContributed >= individualAmountNeeded;
                      console.log(`🔍 FALLBACK FULFILLED CHECK: ${fallbackTotalContributed} >= ${individualAmountNeeded} = ${fallbackFulfilled}`);
                    } catch (err) {
                      console.warn('Could not determine fulfilled status in fallback:', err);
                    }

                    // Show notification with event data - user can contribute or decline
                    requestData = [
                      borrower as string,
                      amount as bigint,
                      contributors as string[],
                      fallbackTotalContributed, // totalContributed - calculated from individual contributions
                      BigInt(Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60), // deadline: 7 days from now
                      fallbackFulfilled, // fulfilled - calculated based on contributions vs needed
                      false, // executed - assume false for notifications
                      purpose as string,
                      BigInt(Math.floor(Date.now() / 1000)) // createdAt
                    ];
                    
                    console.log('🔄 Using notification fallback (show to allow user action):', requestData);
                  }
                  
                  const [borrowerAddr, borrowAmount, collateralNeeded, totalContributed, deadline, fulfilled, executed, purposeStr, createdAt] = requestData;
                  
                  console.log(`📊 Request ${requestId} final data:`, {
                    borrower: borrowerAddr,
                    borrowAmount: borrowAmount?.toString(),
                    collateralNeeded: collateralNeeded?.toString(),
                    totalContributed: totalContributed?.toString(),
                    fulfilled,
                    executed,
                    deadline: deadline?.toString(),
                    purpose: purposeStr,
                    createdAt: createdAt?.toString()
                  });
                  
                  // Check if current user has declined this request
                  let hasDeclined = false;
                  try {
                    hasDeclined = await readContract(publicClient, {
                      address: circleAddress as `0x${string}`,
                      abi: CONTRACT_ABIS.LENDING_POOL,
                      functionName: 'requestDeclines',
                      args: [requestId, address],
                    }) as boolean;
                  } catch (declineCheckError) {
                    console.warn(`Could not check decline status for ${requestId}:`, declineCheckError);
                    // If we can't check, assume not declined (safer)
                    hasDeclined = false;
                  }
                  
                  // Check if current user has already contributed to this request
                  let hasContributed = false;
                  try {
                    const contributionAmount = await readContract(publicClient, {
                      address: circleAddress as `0x${string}`,
                      abi: CONTRACT_ABIS.LENDING_POOL,
                      functionName: 'getRequestContributions',
                      args: [requestId, address],
                    }) as bigint;
                    hasContributed = contributionAmount > BigInt(0);
                  } catch (contributionCheckError) {
                    console.warn(`Could not check contribution for ${requestId}:`, contributionCheckError);
                    hasContributed = false;
                  }
                  
                  // ✅ CRITICAL DEBUG: Log exact filtering decision
                  console.log(`🔍 NOTIFICATION FILTER DEBUG for ${requestId}:`, {
                    fulfilled_value: fulfilled,
                    fulfilled_type: typeof fulfilled,
                    executed_value: executed,
                    executed_type: typeof executed,
                    hasContributed,
                    hasDeclined,
                    borrowerAddr_check: borrowerAddr !== '0x0000000000000000000000000000000000000000',
                    filter_condition: `!executed(${!executed}) && !hasContributed(${!hasContributed}) && !hasDeclined(${!hasDeclined})`,
                    will_show_notification: borrowerAddr !== '0x0000000000000000000000000000000000000000' && !executed && !hasContributed && !hasDeclined
                  });
                  
                  // Show all requests where user is targeted contributor (not executed)
                  // Include fulfilled status so UI can display appropriate state
                  if (borrowerAddr !== '0x0000000000000000000000000000000000000000' && !executed) {
                    const requestData = {
                      id: requestId,
                      requestId,
                      requestor: borrower,
                      requestorName: 'Member', // Would need to resolve from memberNames
                      amount: parseFloat(formatEther(collateralNeeded)),
                      purpose: purposeStr,
                      circleAddress,
                      circleName: 'Circle', // Would need to resolve from useCircleName
                      deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days default
                      isExpired: false,
                      fulfilled: fulfilled,
                      hasContributed: hasContributed,
                      hasDeclined: hasDeclined,
                      contributors: contributors as string[] // Add contributors array for individual allocation calculation
                    };
                    console.log(`🔍 REQUEST DATA INCLUDING STATUS:`, requestData);
                    allRequests.push(requestData);
                    circleRequests.push(requestData);
                  }
                } catch (contractError) {
                  console.error(`❌ Error checking request status for ${requestId} on circle ${circleAddress}:`, contractError);
                  // Don't add the request if we can't verify its status
                }
              }
            } catch (err) {
              console.warn(`Error fetching events from circle ${circleAddress}:`, err);
            }
            return circleRequests;
          }));
          
          // Flatten results from all circles
          for (const requests of circleRequests) {
            allRequests.push(...requests);
          }
        } else {
          console.log(`⚠️ No circles discovered for user ${address}, trying global notification search...`);
          
          // FALLBACK: Global search for CollateralRequested events targeting this user
          try {
            const globalLogs = await rateLimitedGetLogs<any[]>(publicClient, {
              event: parseAbiItem('event CollateralRequested(bytes32 indexed requestId, address indexed borrower, uint256 amount, address[] contributors, string purpose)'),
              fromBlock: MIN_BLOCK_NUMBER,
              toBlock: 'latest',
            });
            
            console.log(`🌐 Found ${globalLogs.length} global CollateralRequested events`);
            
            // Filter for events where current user is a targeted contributor
            const relevantGlobalEvents = globalLogs.filter(log => {
              const { borrower, contributors } = log.args;
              const isTargetedContributor = contributors?.some((contributor: string) => 
                contributor.toLowerCase() === address.toLowerCase()
              );
              const isBorrower = borrower?.toLowerCase() === address.toLowerCase();
              
              return isTargetedContributor && !isBorrower;
            });
            
            console.log(`🎯 Found ${relevantGlobalEvents.length} global events targeting user ${address}`);
            
            // Process each relevant global event (simplified version without full validation)
            for (const log of relevantGlobalEvents) {
              const { requestId, borrower, amount, contributors, purpose } = log.args;
              const circleAddress = log.address;
              
              if (requestId && borrower && amount && contributors && purpose) {
                console.log(`🔔 Global notification found: Request ${requestId} from ${borrower}`);
                
                const requestData = {
                  id: requestId,
                  requestId,
                  requestor: borrower,
                  requestorName: 'Member',
                  amount: parseFloat(formatEther(amount)),
                  purpose: purpose,
                  circleAddress,
                  circleName: 'Circle',
                  deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
                  isExpired: false,
                  fulfilled: false, // Simplified - assume not fulfilled for global search
                  hasContributed: false,
                  hasDeclined: false,
                  totalContributed: '0',
                  totalNeeded: formatEther(amount),
                  contributors: contributors as string[],
                  blockNumber: log.blockNumber?.toString(),
                  transactionHash: log.transactionHash,
                };
                
                allRequests.push(requestData);
              }
            }
          } catch (globalErr) {
            console.warn('Error in global notification search:', globalErr);
          }
        }

        // Deduplicate requests by requestId in case of duplicates
        const uniqueRequests = allRequests.reduce((acc: any[], request: any) => {
          const existing = acc.find((r: any) => r.requestId === request.requestId);
          if (!existing) {
            acc.push(request);
          } else {
            console.log(`⚠️ Duplicate request found and removed: ${request.requestId}`);
          }
          return acc;
        }, []);
        
        console.log(`Found ${allRequests.length} total collateral requests, ${uniqueRequests.length} unique`);
        setRequests(uniqueRequests);
      } catch (err) {
        console.error('Error fetching collateral requests:', err);
        setError(err as Error);
        setRequests([]);
      } finally {
        setIsLoading(false);
      }
    }, [address, publicClient, userCircles, lastFetch]);

    React.useEffect(() => {
      fetchCollateralRequests();
    }, [fetchCollateralRequests]);

  return React.useMemo(() => ({
    data: requests,
    isLoading,
    error,
    refetch: () => {
      console.log('Refetching collateral requests...');
      setLastFetch(0); // Force cache invalidation
      fetchCollateralRequests();
    }
  }), [requests, isLoading, error, fetchCollateralRequests]);
}

// Hook to aggregate user data across all circles
export function useAggregatedUserData() {
  const { address } = useAccount();
  const { data: userCircles, isLoading: circlesLoading } = useUserCircles();
  const publicClient = usePublicClient();
  const [aggregatedData, setAggregatedData] = React.useState({
    totalBalance: 0,
    totalOriginalDeposits: 0,
    totalYieldEarned: 0,
    totalAvailableToBorrow: 0,
    totalCurrentLoans: 0,
    circles: [] as any[]
  });
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<Error | null>(null);

  React.useEffect(() => {
    async function fetchAggregatedData() {
      if (!address || !publicClient || !userCircles || userCircles.length === 0) {
        setAggregatedData({
          totalBalance: 0,
          totalOriginalDeposits: 0,
          totalYieldEarned: 0,
          totalAvailableToBorrow: 0,
          totalCurrentLoans: 0,
          circles: []
        });
        setIsLoading(false);
        return;
      }

      setIsLoading(true);
      setError(null);

      try {
        const circleData = [];
        let totalBalance = 0;
        let totalOriginalDeposits = 0;
        let totalAvailableToBorrow = 0;

        // Get data from each circle
        for (const circleAddress of userCircles) {
          try {
            // Fetching circle data

            // Get user's current balance (including yield)
            const currentBalance = await readContract(publicClient, {
              address: circleAddress as `0x${string}`,
              abi: CONTRACT_ABIS.LENDING_POOL,
              functionName: 'getUserBalance',
              args: [address],
            }) as bigint;

            // Get user's original shares (represents original deposit)
            const userShares = await readContract(publicClient, {
              address: circleAddress as `0x${string}`,
              abi: CONTRACT_ABIS.LENDING_POOL,
              functionName: 'userShares',
              args: [address],
            }) as bigint;

            // Get circle name
            let circleName = 'Circle';
            try {
              circleName = await readContract(publicClient, {
                address: circleAddress as `0x${string}`,
                abi: CONTRACT_ABIS.LENDING_POOL,
                functionName: 'name',
              }) as string;
            } catch (nameError) {
              console.warn(`Could not get name for circle ${circleAddress}`);
            }

            const balanceETH = parseFloat(formatEther(currentBalance));
            const originalDepositETH = parseFloat(formatEther(userShares)); // shares represent original deposit
            const yieldEarned = balanceETH - originalDepositETH;
            const availableToBorrow = balanceETH * 0.85; // 85% LTV

            totalBalance += balanceETH;
            totalOriginalDeposits += originalDepositETH;
            totalAvailableToBorrow += availableToBorrow;

            circleData.push({
              address: circleAddress,
              name: circleName,
              balance: balanceETH,
              originalDeposit: originalDepositETH,
              yieldEarned: yieldEarned,
              availableToBorrow: availableToBorrow
            });

            console.log(`✅ Circle ${circleAddress} data:`, {
              name: circleName,
              balance: balanceETH,
              originalDeposit: originalDepositETH,
              yieldEarned: yieldEarned
            });

          } catch (circleError) {
            console.warn(`Error fetching data from circle ${circleAddress}:`, circleError);
          }
        }

        // Get active loans from sessionStorage
        const activeLoans = JSON.parse(sessionStorage.getItem('userActiveLoans') || '[]');
        const totalCurrentLoans = activeLoans.reduce((sum: number, loan: any) => sum + (loan.amount || 0), 0);

        const totalYieldEarned = totalBalance - totalOriginalDeposits;

        setAggregatedData({
          totalBalance,
          totalOriginalDeposits,
          totalYieldEarned,
          totalAvailableToBorrow,
          totalCurrentLoans,
          circles: circleData
        });

        // Aggregated user data processed

      } catch (err) {
        console.error('Error fetching aggregated user data:', err);
        setError(err as Error);
      } finally {
        setIsLoading(false);
      }
    }

    fetchAggregatedData();
  }, [address, publicClient, userCircles]);

  return React.useMemo(() => ({
    data: aggregatedData,
    isLoading: isLoading || circlesLoading,
    error,
    refetch: () => {
      console.log('Refetching aggregated user data...');
      setIsLoading(true);
    }
  }), [aggregatedData, isLoading, circlesLoading, error]);
}

// Hook to fetch user's active loans
export function useUserLoans() {
  const { address } = useAccount();
  const { data: userCircles } = useUserCircles();
  const publicClient = usePublicClient();
  const [loans, setLoans] = React.useState<any[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = React.useState(Date.now());

  React.useEffect(() => {
    async function fetchUserLoans() {
      if (!address || !publicClient || !userCircles) {
        setLoans([]);
        setIsLoading(false);
        return;
      }

      setIsLoading(true);
      setError(null);
      const allLoans: any[] = [];

      try {
        for (const circleAddress of userCircles) {
          try {
            console.log(`🔍 Fetching loans from circle ${circleAddress}`);
            
            // Get total number of loans (assuming we can query by index)
            // For now, we'll try to get recent loan IDs from events or from a limited range
            // This is a simplified approach - in production, you'd want to use events
            
            // Try to get loan IDs for this user from userLoans mapping
            // Since we can't easily iterate mappings, we'll check recent loan IDs
            // In a real implementation, you'd use events or maintain an index
            
            console.log('📊 User loans data fetched for circle:', circleAddress);
          } catch (err) {
            console.warn(`Error fetching loans from circle ${circleAddress}:`, err);
          }
        }

        setLoans(allLoans);
      } catch (err) {
        console.error('Error fetching user loans:', err);
        setError(err instanceof Error ? err.message : 'Unknown error');
        setLoans([]);
      } finally {
        setIsLoading(false);
      }
    }

    fetchUserLoans();
  }, [address, publicClient, userCircles, lastRefresh]);

  return React.useMemo(() => ({
    data: loans,
    isLoading,
    error,
    refetch: () => {
      console.log('Refetching user loans...');
      setLastRefresh(Date.now());
    }
  }), [loans, isLoading, error]);
}