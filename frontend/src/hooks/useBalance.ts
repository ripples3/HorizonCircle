import { useReadContract } from 'wagmi';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';

export function useUSDCBalance(address: string | undefined) {
  return useReadContract({
    address: CONTRACT_ADDRESSES.USDC_TOKEN as `0x${string}`,
    abi: CONTRACT_ABIS.USDC,
    functionName: 'balanceOf',
    args: [address as `0x${string}`],
    query: {
      enabled: !!address,
    },
  });
}

export function useUserLendingData(address: string | undefined) {
  return useReadContract({
    address: CONTRACT_ADDRESSES.LENDING_POOL as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'getUserData',
    args: [address as `0x${string}`],
    query: {
      enabled: !!address && !!CONTRACT_ADDRESSES.LENDING_POOL,
    },
  });
}