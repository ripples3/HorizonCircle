'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Slider } from '@/components/ui/slider';
import { 
  CreditCard, 
  DollarSign, 
  TrendingDown, 
  Calculator, 
  Clock,
  CheckCircle,
  Users,
  Info
} from 'lucide-react';
import { 
  CURRENCY_SYMBOL, 
  BASE_YIELD_RATE, 
  BORROWING_RATE,
  DEFAULT_LTV
} from '@/constants';

interface BorrowFormProps {
  userBalance?: number;
  onSuccess?: (amount: number) => void;
  onCancel?: () => void;
  onRequestHelp?: (amount: number) => void;
}

export default function BorrowForm({ 
  userBalance = 1000, 
  onSuccess, 
  onCancel,
  onRequestHelp 
}: BorrowFormProps) {
  const [amount, setAmount] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [step, setStep] = useState<'input' | 'confirm' | 'processing' | 'success'>('input');

  const numericAmount = parseFloat(amount) || 0;
  const maxBorrowAmount = userBalance * DEFAULT_LTV;
  const isValidAmount = numericAmount > 0 && numericAmount <= maxBorrowAmount;
  const needsHelp = numericAmount > maxBorrowAmount;
  
  // Calculate rates
  const grossBorrowingCost = numericAmount * BORROWING_RATE;
  const yieldOffset = userBalance * BASE_YIELD_RATE;
  const netCost = grossBorrowingCost - yieldOffset;
  const effectiveRate = netCost / numericAmount;
  const monthlyPayment = (numericAmount + grossBorrowingCost) / 12;

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
      console.error('Borrow failed:', error);
      setStep('input');
    } finally {
      setIsLoading(false);
    }
  };

  const renderInputStep = () => (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="space-y-4">
        <div className="p-4 bg-blue-50 rounded-lg">
          <div className="flex items-center gap-2 mb-2">
            <Info className="w-4 h-4 text-blue-600" />
            <span className="text-sm font-medium text-blue-900">Your Collateral</span>
          </div>
          <div className="text-2xl font-bold text-blue-900">
            {CURRENCY_SYMBOL}{userBalance.toLocaleString()}
          </div>
          <p className="text-sm text-blue-600">
            Available to borrow: {CURRENCY_SYMBOL}{maxBorrowAmount.toLocaleString()} ({(DEFAULT_LTV * 100)}% LTV)
          </p>
        </div>

        <div className="space-y-2">
          <Label htmlFor="amount">Borrow Amount</Label>
          <div className="relative">
            <DollarSign className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input
              id="amount"
              type="number"
              placeholder="Enter amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="pl-10"
              min="1"
              max={maxBorrowAmount}
              step="0.01"
            />
          </div>
          <div className="px-2">
            <Slider
              value={[numericAmount]}
              onValueChange={(value) => setAmount(value[0].toString())}
              max={maxBorrowAmount}
              min={0}
              step={10}
              className="w-full"
            />
          </div>
          <p className="text-sm text-muted-foreground">
            Maximum: {CURRENCY_SYMBOL}{maxBorrowAmount.toLocaleString()}
          </p>
        </div>

        {needsHelp && (
          <div className="p-4 bg-purple-50 rounded-lg border border-purple-200">
            <div className="flex items-center gap-2 mb-2">
              <Users className="w-4 h-4 text-purple-600" />
              <span className="text-sm font-medium text-purple-900">Need More?</span>
            </div>
            <p className="text-sm text-purple-700 mb-3">
              You need {CURRENCY_SYMBOL}{(numericAmount - maxBorrowAmount).toLocaleString()} more in collateral
            </p>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => onRequestHelp?.(numericAmount)}
              className="w-full"
            >
              Request Help from Circle
            </Button>
          </div>
        )}
      </div>

      {numericAmount > 0 && isValidAmount && (
        <div className="space-y-4 p-4 bg-green-50 rounded-lg">
          <h4 className="font-medium text-green-900">Loan Terms</h4>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-green-600">Gross Rate</p>
              <p className="text-lg font-semibold text-green-900">
                {(BORROWING_RATE * 100).toFixed(1)}% APR
              </p>
            </div>
            <div>
              <p className="text-sm text-green-600">Yield Offset</p>
              <p className="text-lg font-semibold text-green-900">
                -{(BASE_YIELD_RATE * 100).toFixed(1)}% APY
              </p>
            </div>
          </div>
          <Separator />
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-sm text-green-600">Net Cost</span>
              <span className="font-semibold text-green-900">
                {CURRENCY_SYMBOL}{netCost.toFixed(2)}/year
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-green-600">Effective Rate</span>
              <Badge variant="secondary" className="text-green-600">
                {(effectiveRate * 100).toFixed(1)}% APR
              </Badge>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-green-600">Monthly Payment</span>
              <span className="font-semibold text-green-900">
                {CURRENCY_SYMBOL}{monthlyPayment.toFixed(2)}
              </span>
            </div>
          </div>
        </div>
      )}

      <div className="flex gap-2">
        <Button
          type="submit"
          disabled={!isValidAmount}
          className="flex-1 gap-2"
        >
          <Calculator className="w-4 h-4" />
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
        <p className="text-muted-foreground">Borrow Amount</p>
      </div>

      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <span className="text-sm">Loan Amount</span>
          <span className="font-medium">{CURRENCY_SYMBOL}{numericAmount.toLocaleString()}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Collateral Required</span>
          <span className="font-medium">{CURRENCY_SYMBOL}{userBalance.toLocaleString()}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Gross Interest Rate</span>
          <Badge variant="secondary" className="text-blue-600">
            {(BORROWING_RATE * 100).toFixed(1)}% APR
          </Badge>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Yield Offset</span>
          <Badge variant="secondary" className="text-green-600">
            -{(BASE_YIELD_RATE * 100).toFixed(1)}% APY
          </Badge>
        </div>
        <Separator />
        <div className="flex justify-between items-center font-semibold">
          <span>Effective Rate</span>
          <Badge className="text-purple-600">
            {(effectiveRate * 100).toFixed(1)}% APR
          </Badge>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Monthly Payment</span>
          <span className="font-medium">{CURRENCY_SYMBOL}{monthlyPayment.toFixed(2)}</span>
        </div>
      </div>

      <div className="space-y-3 p-4 bg-blue-50 rounded-lg">
        <div className="flex items-center gap-2 text-blue-700">
          <CheckCircle className="w-4 h-4" />
          <span className="text-sm font-medium">Instant Approval</span>
        </div>
        <div className="flex items-center gap-2 text-blue-700">
          <Clock className="w-4 h-4" />
          <span className="text-sm font-medium">Flexible Repayment</span>
        </div>
        <div className="flex items-center gap-2 text-blue-700">
          <TrendingDown className="w-4 h-4" />
          <span className="text-sm font-medium">Ultra-low effective rate</span>
        </div>
      </div>

      <div className="flex gap-2">
        <Button
          onClick={handleConfirm}
          disabled={isLoading}
          className="flex-1 gap-2"
        >
          <CheckCircle className="w-4 h-4" />
          Confirm Borrow
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
        <h3 className="text-lg font-semibold">Processing Your Loan</h3>
        <p className="text-muted-foreground">
          Setting up your loan terms and transferring funds...
        </p>
      </div>
      <div className="p-4 bg-blue-50 rounded-lg">
        <p className="text-sm text-blue-700">
          This usually takes 30-60 seconds. Your collateral is being locked.
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
        <h3 className="text-lg font-semibold text-green-600">Loan Approved!</h3>
        <p className="text-muted-foreground">
          {CURRENCY_SYMBOL}{numericAmount.toLocaleString()} has been transferred to your account
        </p>
      </div>
      <div className="p-4 bg-green-50 rounded-lg">
        <p className="text-sm text-green-700">
          Your effective rate is only {(effectiveRate * 100).toFixed(1)}% APR
        </p>
      </div>
    </div>
  );

  const getTitle = () => {
    switch (step) {
      case 'input': return 'Borrow Against Your Deposits';
      case 'confirm': return 'Confirm Loan';
      case 'processing': return 'Processing...';
      case 'success': return 'Success!';
      default: return 'Borrow Against Your Deposits';
    }
  };

  const getDescription = () => {
    switch (step) {
      case 'input': return 'Get instant access to funds at ultra-low rates';
      case 'confirm': return 'Review your loan terms';
      case 'processing': return 'Your loan is being processed';
      case 'success': return 'Your loan has been approved';
      default: return 'Get instant access to funds at ultra-low rates';
    }
  };

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <CreditCard className="w-5 h-5 text-blue-600" />
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