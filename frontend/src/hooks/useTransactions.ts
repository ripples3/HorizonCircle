import React, { useState, useEffect } from 'react';
import { useWriteContract, useWaitForTransactionReceipt, useAccount, usePublicClient, useWalletClient } from 'wagmi';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';
import { parseEther, formatEther, parseAbiItem } from 'viem';
import { readContract, deployContract } from 'viem/actions';

export function useDeposit() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const deposit = async (amount: string, circleAddress?: string) => {
    const targetContract = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
    
    if (!targetContract) {
      throw new Error('Lending pool contract not deployed');
    }

    // Convert amount to ETH units (18 decimals) - deployed contracts use ETH
    const amountInWei = parseEther(amount);

    writeContract({
      address: targetContract as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'deposit',
      args: [],
      value: amountInWei, // Send ETH value with the transaction
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    deposit,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

export function useWithdraw() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const withdraw = async (shares: string) => {
    if (!CONTRACT_ADDRESSES.LENDING_POOL) {
      throw new Error('Lending pool contract not deployed');
    }

    // Convert shares to wei units (18 decimals)
    const sharesInWei = parseEther(shares);

    writeContract({
      address: CONTRACT_ADDRESSES.LENDING_POOL as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'withdraw',
      args: [sharesInWei],
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    withdraw,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

export function useRequestCollateral() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { address: userAddress } = useAccount();
  const publicClient = usePublicClient();

  const requestCollateral = async (
    borrowAmount: string, 
    collateralAmount: string, 
    contributors: string[], 
    purpose: string, 
    circleAddress?: string
  ) => {
    const targetAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
    
    if (!targetAddress) {
      throw new Error('Circle contract address not provided');
    }
    
    // Check minimum contribution requirements (using constant)
    const MIN_CONTRIBUTION_WEI = parseEther('0.000001'); // 0.000001 ETH minimum from LiskConfig.sol
    const collateralAmountInWei = parseEther(collateralAmount);
    const amountPerContributor = collateralAmountInWei / BigInt(contributors.length);
    
    if (amountPerContributor < MIN_CONTRIBUTION_WEI) {
      const minContributionEth = formatEther(MIN_CONTRIBUTION_WEI);
      const currentContributionEth = formatEther(amountPerContributor);
      throw new Error(
        `Each contributor needs at least ${minContributionEth} ETH, but current allocation is ${currentContributionEth} ETH per contributor. ` +
        `Either reduce the number of contributors or increase the total collateral amount.`
      );
    }
    
    // Check for existing active requests to prevent spam
    try {
      
      if (!publicClient || !userAddress) {
        throw new Error('Wallet not connected');
      }
      
      // Get recent CollateralRequested events for this borrower
      const logs = await publicClient.getLogs({
        address: targetAddress as `0x${string}`,
        event: parseAbiItem('event CollateralRequested(bytes32 indexed requestId, address indexed borrower, uint256 amount, address[] contributors, string purpose)'),
        fromBlock: 'earliest',
        toBlock: 'latest',
        args: {
          borrower: userAddress
        }
      });
      
      // Simplified anti-spam: Check for overlapping requests from last 24 hours
      const oneDayAgo = Math.floor(Date.now() / 1000) - (24 * 60 * 60);
      
      for (const log of logs) {
        const { requestId, contributors: existingContributors } = log.args;
        
        if (!requestId || !existingContributors) continue;
        
        // Simple time-based filter: only check recent requests
        const blockNumber = log.blockNumber;
        if (blockNumber && blockNumber < oneDayAgo * 1000) {
          continue; // Skip old requests
        }
        
        // Check if any of the new contributors are already in recent requests
        const hasOverlap = contributors.some(newContrib => 
          existingContributors.some((existing: string) => 
            existing.toLowerCase() === newContrib.toLowerCase()
          )
        );
        
        if (hasOverlap) {
          const overlappingContributors = contributors.filter(newContrib => 
            existingContributors.some((existing: string) => 
              existing.toLowerCase() === newContrib.toLowerCase()
            )
          );
          
          throw new Error(`You have a recent request to: ${overlappingContributors.join(', ')}. Please wait 24 hours before creating another request to the same contributors.`);
        }
      }
    } catch (validationError) {
      // Re-throw validation errors to prevent the transaction
      throw validationError;
    }

    // Convert amounts to wei units (18 decimals)
    const borrowAmountInWei = parseEther(borrowAmount);

    // Ensure contributors are properly typed as addresses
    const contributorAddresses = contributors.map(addr => addr as `0x${string}`);

    // Calculate equal amounts for each contributor (using variable already declared above)
    const contributorAmounts = contributors.map(() => amountPerContributor);
    
    // Adjust last contributor to handle any rounding remainder
    const totalAllocated = amountPerContributor * BigInt(contributors.length - 1);
    contributorAmounts[contributors.length - 1] = collateralAmountInWei - totalAllocated;

    writeContract({
      address: targetAddress as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'requestCollateral',
      args: [borrowAmountInWei, collateralAmountInWei, contributorAddresses, contributorAmounts, purpose],
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    requestCollateral,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

export function useContributeToRequest(circleAddress?: string) {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const contribute = async (requestId: string) => {
    const targetAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
    
    if (!targetAddress) {
      throw new Error('Circle contract address not provided');
    }

    console.log(`🤝 Contributing to request ${requestId} (amount determined by smart contract)`);
    writeContract({
      address: targetAddress as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'contributeToRequest',
      args: [requestId as `0x${string}`], // No amount - uses expected contribution from contract
      // No value parameter - uses existing vault deposits
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    contribute,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

export function useDeclineRequest(circleAddress?: string) {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const declineRequest = async (requestId: string) => {
    const targetAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
    
    if (!targetAddress) {
      throw new Error('Circle contract address not provided');
    }

    writeContract({
      address: targetAddress as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'declineRequest',
      args: [requestId as `0x${string}`],
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    declineRequest,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

export function useCreateCircle() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { address: userAddress } = useAccount();
  
  const [deploymentStep, setDeploymentStep] = useState<'idle' | 'creating' | 'complete'>('idle');
  const [deployedCircleAddress, setDeployedCircleAddress] = useState<string | null>(null);

  const createCircle = async (name: string, initialMembers: `0x${string}`[] = []) => {
    if (!userAddress) {
      throw new Error('Wallet not connected');
    }

    console.log('🏭 Creating circle via factory...', { name, initialMembers });
    
    setDeploymentStep('creating');

    try {
      // Use the deployed factory - industry standard approach
      writeContract({
        address: CONTRACT_ADDRESSES.FACTORY as `0x${string}`,
        abi: CONTRACT_ABIS.FACTORY,
        functionName: 'createCircle',
        args: [name, initialMembers],
      });
      
      console.log('🚀 Circle creation transaction submitted...');

    } catch (error) {
      console.error('❌ Circle creation failed:', error);
      setDeploymentStep('idle');
      throw error;
    }
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  // Update step when creation completes
  useEffect(() => {
    if (isConfirmed && deploymentStep === 'creating') {
      setDeploymentStep('complete');
      console.log('✅ Circle created successfully via factory');
    }
  }, [isConfirmed, deploymentStep]);

  return {
    createCircle,
    hash,
    isPending,
    isConfirming,
    isConfirmed: deploymentStep === 'complete',
    error,
    deployedCircleAddress,
    deploymentStep,
  };
}

export function useAddMember(circleAddress: string) {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const addMember = async (newMemberAddress: string) => {
    if (!circleAddress) {
      throw new Error('Circle address is required');
    }

    console.log('🔧 Adding member to circle:', { circleAddress, newMemberAddress });
    writeContract({
      address: circleAddress as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'addMember',
      args: [newMemberAddress as `0x${string}`],
    });
  };

  // Helper function to add yourself as a member (for deployment bugs)
  const addSelfAsMember = async (userAddress: string) => {
    console.log('🔧 Emergency: Adding self as member due to deployment bug');
    return addMember(userAddress);
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    addMember,
    addSelfAsMember,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

// Execute a fulfilled collateral request to create a loan
export function useExecuteRequest() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const executeRequest = (contractAddress: string, requestId: string) => {
    console.log(`🚀 Executing request ${requestId} on contract ${contractAddress}`);
    writeContract({
      address: contractAddress as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'executeRequest',
      args: [requestId as `0x${string}`],
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    executeRequest,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

// Repay a loan with ETH (gets converted to wstETH collateral)
export function useRepayLoan(circleAddress?: string) {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const repayLoan = async (loanId: string, amount: string) => {
    const targetAddress = circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
    
    if (!targetAddress) {
      throw new Error('Circle contract address not provided');
    }

    // Convert amount to wei units (18 decimals)
    const amountInWei = parseEther(amount);

    console.log(`💰 Repaying loan ${loanId} with ${amount} ETH on contract ${targetAddress}`);
    writeContract({
      address: targetAddress as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'repayLoan',
      args: [loanId as `0x${string}`],
      value: amountInWei, // Send ETH value with the transaction
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    repayLoan,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}