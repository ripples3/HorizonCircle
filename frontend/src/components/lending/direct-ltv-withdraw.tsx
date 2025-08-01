'use client';

import { useState } from 'react';
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';
import { useUserData } from '@/hooks/useUserData';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Loader2, Zap } from 'lucide-react';

interface DirectLTVWithdrawProps {
  circleAddress: string;
}

export function DirectLTVWithdraw({ circleAddress }: DirectLTVWithdrawProps) {
  const [borrowAmount, setBorrowAmount] = useState('');
  const [error, setError] = useState('');
  
  const { userData } = useUserData();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // Get user's balance in the circle
  const userCircleBalance = userData?.circleBalances?.find(
    balance => balance.circleAddress.toLowerCase() === circleAddress.toLowerCase()
  )?.balance || 0;

  // Calculate maximum borrowable amount (85% LTV)
  const maxBorrowAmount = (userCircleBalance * 0.85);

  const handleBorrow = async () => {
    if (!borrowAmount || parseFloat(borrowAmount) <= 0) {
      setError('Please enter a valid borrow amount');
      return;
    }

    const borrowAmountWei = parseEther(borrowAmount);
    const maxBorrowAmountWei = parseEther(maxBorrowAmount.toString());

    if (borrowAmountWei > maxBorrowAmountWei) {
      setError(`Amount exceeds 85% LTV limit of ${maxBorrowAmount.toFixed(6)} ETH`);
      return;
    }

    setError('');

    try {
      await writeContract({
        address: circleAddress as `0x${string}`,
        abi: CONTRACT_ABIS.LENDING_POOL,
        functionName: 'directLTVWithdraw',
        args: [borrowAmountWei],
      });
    } catch (err) {
      console.error('Direct LTV withdrawal error:', err);
      setError('Transaction failed. Please try again.');
    }
  };

  const isLoading = isPending || isConfirming;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Zap className="w-5 h-5 text-blue-500" />
          Direct LTV Withdrawal
        </CardTitle>
        <CardDescription>
          Withdraw up to 85% of your deposit value directly without social lending
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <div className="flex justify-between text-sm text-gray-600">
            <span>Your Deposit:</span>
            <span>{userCircleBalance.toFixed(6)} ETH</span>
          </div>
          <div className="flex justify-between text-sm text-gray-600">
            <span>Maximum Withdrawable (85% LTV):</span>
            <span>{maxBorrowAmount.toFixed(6)} ETH</span>
          </div>
        </div>

        <div className="space-y-2">
          <label htmlFor="borrowAmount" className="text-sm font-medium text-gray-700">
            Withdrawal Amount (ETH)
          </label>
          <Input
            id="borrowAmount"
            type="number"
            step="0.000001"
            max={maxBorrowAmount.toString()}
            placeholder="0.000000"
            value={borrowAmount}
            onChange={(e) => setBorrowAmount(e.target.value)}
            disabled={isLoading}
          />
          <div className="flex justify-between text-xs text-gray-500">
            <span>Min: 0.000001 ETH</span>
            <button
              type="button"
              onClick={() => setBorrowAmount(maxBorrowAmount.toString())}
              className="text-blue-500 hover:text-blue-700"
              disabled={isLoading}
            >
              Use Max
            </button>
          </div>
        </div>

        {error && (
          <div className="text-sm text-red-600 bg-red-50 p-2 rounded">
            {error}
          </div>
        )}

        {writeError && (
          <div className="text-sm text-red-600 bg-red-50 p-2 rounded">
            Transaction Error: {writeError.message}
          </div>
        )}

        {isSuccess && (
          <div className="text-sm text-green-600 bg-green-50 p-2 rounded">
            ✅ Direct withdrawal successful! You have received {borrowAmount} ETH.
          </div>
        )}

        <div className="space-y-2">
          <h4 className="text-sm font-medium text-gray-700">How it works:</h4>
          <ul className="text-xs text-gray-600 space-y-1">
            <li>• Withdraws WETH from your Morpho vault deposit</li>
            <li>• Swaps WETH to wstETH via Velodrome DEX</li>
            <li>• Uses wstETH as collateral in Morpho lending market</li>
            <li>• Borrows WETH and sends as ETH to you</li>
            <li>• No social lending approval required</li>
          </ul>
        </div>

        <Button
          onClick={handleBorrow}
          disabled={isLoading || !borrowAmount || parseFloat(borrowAmount) <= 0 || userCircleBalance === 0}
          className="w-full"
        >
          {isLoading ? (
            <>
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              {isPending ? 'Confirming...' : 'Processing...'}
            </>
          ) : (
            <>
              <Zap className="w-4 h-4 mr-2" />
              Withdraw {borrowAmount || '0'} ETH
            </>
          )}
        </Button>

        <div className="text-xs text-gray-500 text-center">
          This creates a collateralized loan using your own deposit
        </div>
      </CardContent>
    </Card>
  );
}