'use client';

import React, { useState } from 'react';
import { useRepayLoan } from '@/hooks/useTransactions';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

interface RepayFormProps {
  loanId: string;
  loanAmount: number;
  circleAddress?: string;
  onSuccess?: () => void;
}

export function RepayForm({ loanId, loanAmount, circleAddress, onSuccess }: RepayFormProps) {
  const [repaymentAmount, setRepaymentAmount] = useState('');
  const [error, setError] = useState<string | null>(null);
  
  const {
    repayLoan,
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    error: transactionError,
  } = useRepayLoan(circleAddress);

  // Handle successful repayment
  React.useEffect(() => {
    if (isConfirmed && hash) {
      console.log(`✅ Loan ${loanId} repaid successfully with hash: ${hash}`);
      setRepaymentAmount('');
      setError(null);
      
      // Notify parent component
      if (onSuccess) {
        onSuccess();
      }
      
      // Update localStorage to mark loan as repaid
      try {
        const storedLoans = localStorage.getItem('userActiveLoans');
        if (storedLoans) {
          const loans = JSON.parse(storedLoans);
          const updatedLoans = loans.filter((loan: any) => loan.id !== loanId);
          localStorage.setItem('userActiveLoans', JSON.stringify(updatedLoans));
          
          // Trigger dashboard update
          window.dispatchEvent(new CustomEvent('loanRepaid', { 
            detail: { loanId, transactionHash: hash } 
          }));
        }
      } catch (storageError) {
        console.warn('Failed to update loan storage:', storageError);
      }
    }
  }, [isConfirmed, hash, loanId, onSuccess]);

  const handleRepayment = async () => {
    setError(null);
    
    if (!repaymentAmount || parseFloat(repaymentAmount) <= 0) {
      setError('Please enter a valid repayment amount');
      return;
    }

    try {
      await repayLoan(loanId, repaymentAmount);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Repayment failed');
    }
  };

  const formatAmount = (amount: number) => {
    return amount.toFixed(6);
  };

  return (
    <div className="space-y-4 p-4 border rounded-lg bg-card">
      <div className="space-y-2">
        <h3 className="text-lg font-semibold">Repay Loan</h3>
        <p className="text-sm text-muted-foreground">
          Loan Amount: {formatAmount(loanAmount)} ETH
        </p>
        <p className="text-xs text-muted-foreground">
          Note: Repayments are converted to wstETH collateral for capital efficiency
        </p>
      </div>

      <div className="space-y-2">
        <Label htmlFor="repayAmount">Repayment Amount (ETH)</Label>
        <Input
          id="repayAmount"
          type="number"
          step="0.000001"
          min="0"
          placeholder="0.000000"
          value={repaymentAmount}
          onChange={(e) => setRepaymentAmount(e.target.value)}
          disabled={isPending || isConfirming}
        />
      </div>

      {error && (
        <div className="text-sm text-red-600 bg-red-50 p-2 rounded">
          {error}
        </div>
      )}

      {transactionError && (
        <div className="text-sm text-red-600 bg-red-50 p-2 rounded">
          Transaction Error: {transactionError.message}
        </div>
      )}

      {hash && (
        <div className="text-sm text-blue-600 bg-blue-50 p-2 rounded">
          Transaction Hash: {hash}
        </div>
      )}

      <Button
        onClick={handleRepayment}
        disabled={isPending || isConfirming || !repaymentAmount}
        className="w-full"
      >
        {isPending ? 'Preparing...' : 
         isConfirming ? 'Confirming...' : 
         isConfirmed ? 'Repayment Complete!' : 
         'Repay Loan'}
      </Button>

      {isConfirmed && (
        <div className="text-sm text-green-600 bg-green-50 p-2 rounded">
          ✅ Loan repayment successful! Your ETH has been converted to wstETH collateral.
        </div>
      )}
    </div>
  );
}