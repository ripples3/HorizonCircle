'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { 
  CreditCard, 
  Coins, 
  TrendingUp, 
  Shield, 
  Clock,
  CheckCircle
} from 'lucide-react';
import { 
  CURRENCY_SYMBOL, 
  BASE_YIELD_RATE, 
  MIN_DEPOSIT_AMOUNT, 
  MAX_DEPOSIT_AMOUNT,
  TOKEN_SYMBOL
} from '@/constants';
import { useDeposit } from '@/hooks/useTransactions';

// Helper component to display circle name
function CircleOption({ circleAddress }: { circleAddress: string }) {
  const { data: circleName, isLoading } = useCircleName(circleAddress);
  
  // Create a user-friendly fallback name from address
  const fallbackName = `Circle ${circleAddress.slice(0, 6)}...${circleAddress.slice(-4)}`;
  
  return (
    <span>
      {isLoading ? 'Loading...' : (circleName || fallbackName)}
      <span className="ml-2 text-sm opacity-70">
        {circleAddress.slice(0, 6)}...{circleAddress.slice(-4)}
      </span>
    </span>
  );
}
import { CONTRACT_ADDRESSES } from '@/config/web3';
import { useChainId, useSwitchChain } from 'wagmi';
import { LISK_CHAIN_ID } from '@/constants';
import { useUserCirclesDirect as useUserCircles, useCircleName } from '@/hooks/useBalance';
// Note: Select component not available, using buttons instead

interface DepositFormProps {
  onSuccess?: (amount: number) => void;
  onCancel?: () => void;
}

export default function DepositForm({ onSuccess, onCancel }: DepositFormProps) {
  const [amount, setAmount] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [step, setStep] = useState<'input' | 'confirm' | 'processing' | 'success'>('input');
  const [selectedCircle, setSelectedCircle] = useState<string>('');

  // Get user's circles
  const { data: userCircles } = useUserCircles();
  const hasCircles = userCircles && Array.isArray(userCircles) && userCircles.length > 0;
  
  // Set default circle on load
  React.useEffect(() => {
    if (hasCircles && userCircles && !selectedCircle) {
      setSelectedCircle(userCircles[0]);
    } else if (!hasCircles && !selectedCircle) {
      setSelectedCircle(CONTRACT_ADDRESSES.LENDING_POOL);
    }
  }, [hasCircles, userCircles, selectedCircle]);

  // Web3 transaction hook
  const { deposit, isPending, isConfirming, isConfirmed, error } = useDeposit();
  
  // Network checking
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();
  const isWrongNetwork = chainId !== LISK_CHAIN_ID;

  const numericAmount = parseFloat(amount) || 0;
  const isValidAmount = numericAmount >= MIN_DEPOSIT_AMOUNT && numericAmount <= MAX_DEPOSIT_AMOUNT;
  const annualYield = numericAmount * BASE_YIELD_RATE;
  const monthlyYield = annualYield / 12;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValidAmount) return;

    setStep('confirm');
  };

  const handleSwitchNetwork = async () => {
    try {
      await switchChain({ chainId: LISK_CHAIN_ID });
    } catch (error) {
      console.error('Failed to switch network:', error);
    }
  };

  const handleConfirm = async () => {
    // Check network first
    if (isWrongNetwork) {
      await handleSwitchNetwork();
      return;
    }

    setStep('processing');
    setIsLoading(true);

    try {
      console.log('Starting deposit transaction...');
      console.log('Amount:', amount);
      console.log('Contract address:', selectedCircle);
      console.log('Current network:', chainId);
      
      // Call the real Web3 transaction
      await deposit(amount, selectedCircle);
      
      setStep('success');
      setTimeout(() => {
        onSuccess?.(numericAmount);
      }, 1500);
    } catch (error) {
      console.error('Deposit failed:', error);
      setStep('input');
    } finally {
      setIsLoading(false);
    }
  };

  const renderInputStep = () => (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Always show selected circle for transparency */}
      <div className="space-y-2">
        <Label>Depositing to Circle</Label>
        {hasCircles && userCircles && userCircles.length > 1 ? (
          <div className="space-y-2">
            <div className="text-sm text-muted-foreground mb-2">
              Choose which circle to deposit your funds into:
            </div>
            {userCircles.map((circle) => (
              <Button
                key={circle}
                type="button"
                variant={selectedCircle === circle ? "default" : "outline"}
                className="w-full justify-start text-left p-3 h-auto"
                onClick={() => setSelectedCircle(circle)}
              >
                <CircleOption circleAddress={circle} />
              </Button>
            ))}
          </div>
        ) : (
          <div className="p-3 border rounded-lg bg-blue-50 border-blue-200">
            <div className="flex items-center justify-between">
              <div>
                <div className="font-medium text-blue-900">
                  <CircleOption circleAddress={selectedCircle} />
                </div>
                <div className="text-xs text-blue-600 mt-1">
                  Your funds will be deposited here
                </div>
              </div>
              <Badge variant="secondary" className="text-blue-700">
                Selected
              </Badge>
            </div>
          </div>
        )}
      </div>
      
      <div className="space-y-2">
        <Label htmlFor="amount">Deposit Amount</Label>
        <div className="relative">
          <Coins className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
          <Input
            id="amount"
            type="number"
            placeholder="Enter amount"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="pl-10"
            min={MIN_DEPOSIT_AMOUNT}
            max={MAX_DEPOSIT_AMOUNT}
            step="0.01"
          />
        </div>
        <p className="text-sm text-muted-foreground">
          Minimum: {CURRENCY_SYMBOL}{MIN_DEPOSIT_AMOUNT.toFixed(8)} • 
          Maximum: {CURRENCY_SYMBOL}{MAX_DEPOSIT_AMOUNT.toFixed(8)}
        </p>
      </div>

      {numericAmount > 0 && (
        <div className="space-y-4 p-4 bg-blue-50 rounded-lg">
          <h4 className="font-medium text-blue-900">Projected Earnings</h4>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-blue-600">Monthly</p>
              <p className="text-lg font-semibold text-blue-900">
                +{CURRENCY_SYMBOL}{monthlyYield.toFixed(8)}
              </p>
            </div>
            <div>
              <p className="text-sm text-blue-600">Annual</p>
              <p className="text-lg font-semibold text-blue-900">
                +{CURRENCY_SYMBOL}{annualYield.toFixed(8)}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2 text-sm text-blue-700">
            <TrendingUp className="w-4 h-4" />
            {(BASE_YIELD_RATE * 100).toFixed(1)}% APY
          </div>
        </div>
      )}

      <div className="flex gap-2">
        <Button
          type="submit"
          disabled={!isValidAmount}
          className="flex-1 gap-2"
        >
          <CreditCard className="w-4 h-4" />
          Continue
        </Button>
        {onCancel && (
          <Button type="button" variant="outline" onClick={onCancel}>
            Cancel
          </Button>
        )}
      </div>
    </form>
  );

  const renderConfirmStep = () => (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <div className="text-3xl font-bold">
          {CURRENCY_SYMBOL}{numericAmount.toFixed(8)}
        </div>
        <p className="text-muted-foreground">Deposit Amount</p>
      </div>

      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <span className="text-sm">Deposit Amount</span>
          <span className="font-medium">{CURRENCY_SYMBOL}{numericAmount.toFixed(8)}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Circle</span>
          <span className="font-medium text-sm">
            <CircleOption circleAddress={selectedCircle} />
          </span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Processing Fee</span>
          <span className="font-medium">{CURRENCY_SYMBOL}0.00000000</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Interest Rate</span>
          <Badge variant="secondary" className="text-green-600">
            {(BASE_YIELD_RATE * 100).toFixed(1)}% APY
          </Badge>
        </div>
        <Separator />
        <div className="flex justify-between items-center font-semibold">
          <span>Total</span>
          <span>{CURRENCY_SYMBOL}{numericAmount.toLocaleString()}</span>
        </div>
      </div>

      <div className="space-y-3 p-4 bg-green-50 rounded-lg">
        <div className="flex items-center gap-2 text-green-700">
          <Shield className="w-4 h-4" />
          <span className="text-sm font-medium">Secure & Insured</span>
        </div>
        <div className="flex items-center gap-2 text-green-700">
          <Clock className="w-4 h-4" />
          <span className="text-sm font-medium">Instant Processing</span>
        </div>
        <div className="flex items-center gap-2 text-green-700">
          <TrendingUp className="w-4 h-4" />
          <span className="text-sm font-medium">Start earning immediately</span>
        </div>
      </div>

      {isWrongNetwork && (
        <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
          <div className="flex items-center gap-2 text-orange-700 mb-2">
            <Shield className="w-4 h-4" />
            <span className="font-medium">Wrong Network</span>
          </div>
          <p className="text-sm text-orange-600 mb-3">
            Please switch to Lisk network to continue. You&apos;re currently on network {chainId}.
          </p>
        </div>
      )}

      <div className="flex gap-2">
        <Button
          onClick={handleConfirm}
          disabled={isLoading}
          className="flex-1 gap-2"
          variant={isWrongNetwork ? "secondary" : "default"}
        >
          <CheckCircle className="w-4 h-4" />
          {isWrongNetwork ? 'Switch to Lisk Network' : 'Confirm Deposit'}
        </Button>
        <Button
          variant="outline"
          onClick={() => setStep('input')}
          disabled={isLoading}
        >
          Back
        </Button>
      </div>
    </div>
  );

  const renderProcessingStep = () => (
    <div className="text-center space-y-6">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
      <div className="space-y-2">
        <h3 className="text-lg font-semibold">Processing Your Deposit</h3>
        <p className="text-muted-foreground">
          Converting your payment to {TOKEN_SYMBOL}...
        </p>
      </div>
      <div className="p-4 bg-blue-50 rounded-lg">
        <p className="text-sm text-blue-700">
          This usually takes 30-60 seconds. Please don&apos;t close this window.
        </p>
      </div>
    </div>
  );

  const renderSuccessStep = () => (
    <div className="text-center space-y-6">
      <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
        <CheckCircle className="w-8 h-8 text-green-600" />
      </div>
      <div className="space-y-2">
        <h3 className="text-lg font-semibold text-green-600">Deposit Successful!</h3>
        <p className="text-muted-foreground">
          {CURRENCY_SYMBOL}{numericAmount.toFixed(8)} has been added to your account
        </p>
      </div>
      <div className="p-4 bg-green-50 rounded-lg">
        <p className="text-sm text-green-700">
          Your funds are now earning {(BASE_YIELD_RATE * 100).toFixed(1)}% APY
        </p>
      </div>
    </div>
  );

  const getTitle = () => {
    switch (step) {
      case 'input': return 'Earn';
      case 'confirm': return 'Confirm Deposit';
      case 'processing': return 'Processing...';
      case 'success': return 'Success!';
      default: return 'Earn';
    }
  };

  const getDescription = () => {
    switch (step) {
      case 'input': return 'Deposit funds and start earning yield on your ETH';
      case 'confirm': return 'Review your deposit details';
      case 'processing': return 'Your deposit is being processed';
      case 'success': return 'Your deposit has been completed';
      default: return 'Deposit funds and start earning yield on your ETH';
    }
  };

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Coins className="w-5 h-5 text-green-600" />
          {getTitle()}
        </CardTitle>
        <CardDescription>{getDescription()}</CardDescription>
      </CardHeader>
      <CardContent>
        <React.Fragment key={step}>
          {step === 'input' && renderInputStep()}
          {step === 'confirm' && renderConfirmStep()}
          {step === 'processing' && renderProcessingStep()}
          {step === 'success' && renderSuccessStep()}
        </React.Fragment>
      </CardContent>
    </Card>
  );
}