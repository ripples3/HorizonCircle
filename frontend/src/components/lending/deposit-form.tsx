'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { 
  CreditCard, 
  DollarSign, 
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

interface DepositFormProps {
  onSuccess?: (amount: number) => void;
  onCancel?: () => void;
}

export default function DepositForm({ onSuccess, onCancel }: DepositFormProps) {
  const [amount, setAmount] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [step, setStep] = useState<'input' | 'confirm' | 'processing' | 'success'>('input');

  const numericAmount = parseFloat(amount) || 0;
  const isValidAmount = numericAmount >= MIN_DEPOSIT_AMOUNT && numericAmount <= MAX_DEPOSIT_AMOUNT;
  const annualYield = numericAmount * BASE_YIELD_RATE;
  const monthlyYield = annualYield / 12;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValidAmount) return;

    setStep('confirm');
  };

  const handleConfirm = async () => {
    setStep('processing');
    setIsLoading(true);

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 2000));
      
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
      <div className="space-y-2">
        <Label htmlFor="amount">Deposit Amount</Label>
        <div className="relative">
          <DollarSign className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
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
          Minimum: {CURRENCY_SYMBOL}{MIN_DEPOSIT_AMOUNT.toLocaleString()} • 
          Maximum: {CURRENCY_SYMBOL}{MAX_DEPOSIT_AMOUNT.toLocaleString()}
        </p>
      </div>

      {numericAmount > 0 && (
        <div className="space-y-4 p-4 bg-blue-50 rounded-lg">
          <h4 className="font-medium text-blue-900">Projected Earnings</h4>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-blue-600">Monthly</p>
              <p className="text-lg font-semibold text-blue-900">
                +{CURRENCY_SYMBOL}{monthlyYield.toFixed(2)}
              </p>
            </div>
            <div>
              <p className="text-sm text-blue-600">Annual</p>
              <p className="text-lg font-semibold text-blue-900">
                +{CURRENCY_SYMBOL}{annualYield.toFixed(2)}
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
          {CURRENCY_SYMBOL}{numericAmount.toLocaleString()}
        </div>
        <p className="text-muted-foreground">Deposit Amount</p>
      </div>

      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <span className="text-sm">Deposit Amount</span>
          <span className="font-medium">{CURRENCY_SYMBOL}{numericAmount.toLocaleString()}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Processing Fee</span>
          <span className="font-medium">{CURRENCY_SYMBOL}0.00</span>
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

      <div className="flex gap-2">
        <Button
          onClick={handleConfirm}
          disabled={isLoading}
          className="flex-1 gap-2"
        >
          <CheckCircle className="w-4 h-4" />
          Confirm Deposit
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
          {CURRENCY_SYMBOL}{numericAmount.toLocaleString()} has been added to your account
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
      case 'input': return 'Deposit Funds';
      case 'confirm': return 'Confirm Deposit';
      case 'processing': return 'Processing...';
      case 'success': return 'Success!';
      default: return 'Deposit Funds';
    }
  };

  const getDescription = () => {
    switch (step) {
      case 'input': return 'Add funds to your account and start earning yield';
      case 'confirm': return 'Review your deposit details';
      case 'processing': return 'Your deposit is being processed';
      case 'success': return 'Your deposit has been completed';
      default: return 'Add funds to your account and start earning yield';
    }
  };

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <DollarSign className="w-5 h-5 text-green-600" />
          {getTitle()}
        </CardTitle>
        <CardDescription>{getDescription()}</CardDescription>
      </CardHeader>
      <CardContent>
        {step === 'input' && renderInputStep()}
        {step === 'confirm' && renderConfirmStep()}
        {step === 'processing' && renderProcessingStep()}
        {step === 'success' && renderSuccessStep()}
      </CardContent>
    </Card>
  );
}