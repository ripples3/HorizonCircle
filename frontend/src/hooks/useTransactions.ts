import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';
import { parseUnits } from 'viem';

export function useDeposit() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const deposit = async (amount: string) => {
    if (!CONTRACT_ADDRESSES.LENDING_POOL) {
      throw new Error('Lending pool contract not deployed');
    }

    // Convert amount to USDC units (6 decimals)
    const amountInUnits = parseUnits(amount, 6);

    writeContract({
      address: CONTRACT_ADDRESSES.LENDING_POOL as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'deposit',
      args: [amountInUnits],
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

export function useBorrow() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const borrow = async (amount: string) => {
    if (!CONTRACT_ADDRESSES.LENDING_POOL) {
      throw new Error('Lending pool contract not deployed');
    }

    // Convert amount to USDC units (6 decimals)
    const amountInUnits = parseUnits(amount, 6);

    writeContract({
      address: CONTRACT_ADDRESSES.LENDING_POOL as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'borrow',
      args: [amountInUnits],
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    borrow,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}

export function useRepay() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const repay = async (amount: string) => {
    if (!CONTRACT_ADDRESSES.LENDING_POOL) {
      throw new Error('Lending pool contract not deployed');
    }

    // Convert amount to USDC units (6 decimals)
    const amountInUnits = parseUnits(amount, 6);

    writeContract({
      address: CONTRACT_ADDRESSES.LENDING_POOL as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'repay',
      args: [amountInUnits],
    });
  };

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    repay,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error,
  };
}