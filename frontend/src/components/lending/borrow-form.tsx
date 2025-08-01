'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Slider } from '@/components/ui/slider';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  CreditCard, 
  Coins, 
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
  DEFAULT_LTV,
  LISK_CHAIN_ID
} from '@/constants';
import { useChainId, useSwitchChain, useAccount } from 'wagmi';
import { formatEther } from 'viem';
import { useUserCirclesDirect as useUserCircles, useUserCircleBalance, useCircleName, useCircleMembers } from '@/hooks/useBalance';
import { useReadContract } from 'wagmi';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';
import { useMemberNames, MemberInfo } from '@/utils/memberNames';

interface BorrowFormProps {
  onSuccess?: (amount: number) => void;
  onCancel?: () => void;
  onRequestHelp?: (borrowAmount: number, collateralAmount: number, circleAddress: string, contributors: MemberContribution[]) => void;
}

export default function BorrowForm({ 
  onSuccess, 
  onCancel,
  onRequestHelp 
}: BorrowFormProps) {
  const [amount, setAmount] = useState('');
  const [selectedCircle, setSelectedCircle] = useState<string>('');
  const [isLoading, setIsLoading] = useState(false);
  const [step, setStep] = useState<'input' | 'confirm' | 'processing' | 'success'>('input');
  const [memberContributions, setMemberContributions] = useState<MemberContribution[]>([]);
  
  const { address } = useAccount();
  const { data: userCircles } = useUserCircles();
  const { data: circleBalance } = useUserCircleBalance(address, selectedCircle);
  const { data: circleName } = useCircleName(selectedCircle);
  
  const userBalance = circleBalance ? parseFloat(formatEther(circleBalance)) : 0;

  const numericAmount = parseFloat(amount) || 0;
  const maxBorrowAmount = userBalance * DEFAULT_LTV;
  const needsHelp = numericAmount > maxBorrowAmount;
  const isValidAmount = numericAmount > 0 && (needsHelp || numericAmount <= maxBorrowAmount);
  
  // Calculate Morpho over-collateralization requirement
  const morphoLTV = 0.85; // Morpho's 85% LTV ratio
  const collateralNeededForMorpho = needsHelp ? numericAmount / morphoLTV : 0;
  const userCollateralValue = userBalance; // User's existing collateral
  
  // Calculate member contribution needed (accounting for 85% LTV on their contributions too)  
  const memberCollateralNeeded = needsHelp ? collateralNeededForMorpho - userCollateralValue : 0;
  const shortfall = needsHelp ? memberCollateralNeeded / morphoLTV : 0; // Members must contribute more since only 85% counts
  
  // Debug logging for button state
  const selectedContributions = memberContributions.filter(m => m.selected);
  const isCollateralValid = !needsHelp || selectedContributions.length > 0;
  
  React.useEffect(() => {
    console.log('🔧 Button Debug:', {
      isValidAmount,
      selectedCircle: !!selectedCircle,
      needsHelp,
      memberContributions: memberContributions.length,
      selectedContributions: selectedContributions.length,
      isCollateralValid
    });
  }, [isValidAmount, selectedCircle, needsHelp, memberContributions.length, selectedContributions.length, isCollateralValid]);
  
  // Calculate rates
  const grossBorrowingCost = numericAmount * BORROWING_RATE;
  const yieldOffset = userBalance * BASE_YIELD_RATE;
  const netCost = grossBorrowingCost - yieldOffset;
  const effectiveRate = netCost / numericAmount;
  const monthlyPayment = (numericAmount + grossBorrowingCost) / 12;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValidAmount) return;

    if (needsHelp) {
      // For insufficient collateral, we need to validate the collateral request
      const selectedContributions = memberContributions.filter(m => m.selected);
      
      if (selectedContributions.length === 0) {
        alert('Please select at least one member and allocate amounts for collateral help');
        return;
      }
      
      const totalAllocated = selectedContributions.reduce((sum, m) => sum + m.amount, 0);
      const isValidAllocation = Math.abs(totalAllocated - shortfall) < 0.0000001; // More lenient precision
      
      console.log('🔧 Validation Debug:', {
        totalAllocated,
        shortfall,
        difference: totalAllocated - shortfall,
        isValidAllocation
      });
      
      if (!isValidAllocation) {
        alert(`Please allocate exactly ${CURRENCY_SYMBOL}${shortfall.toFixed(8)} among selected members`);
        return;
      }
      
      // Proceed to confirmation for collateral request
      setStep('confirm');
    } else {
      // For sufficient collateral, proceed directly to confirmation
      setStep('confirm');
    }
  };

  const handleConfirm = async () => {
    setStep('processing');
    setIsLoading(true);

    try {
      if (needsHelp) {
        // Insufficient collateral - create collateral request
        const selectedContributions = memberContributions.filter(m => m.selected);
        console.log('Creating collateral request with contributions:', selectedContributions);
        
        await onRequestHelp?.(numericAmount, shortfall, selectedCircle, selectedContributions);
        
        setStep('success');
        setTimeout(() => {
          onSuccess?.(numericAmount);
        }, 1500);
      } else {
        // Sufficient collateral - direct borrow
        // TODO: Implement direct borrow transaction here
        console.log('Direct borrow with sufficient collateral:', numericAmount);
        
        // Simulate direct borrow transaction
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        setStep('success');
        setTimeout(() => {
          onSuccess?.(numericAmount);
        }, 1500);
      }
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
        <div className="space-y-2">
          <Label htmlFor="circle-select">Select Circle</Label>
          <Select value={selectedCircle} onValueChange={setSelectedCircle}>
            <SelectTrigger>
              <SelectValue placeholder="Choose a circle" />
            </SelectTrigger>
            <SelectContent>
              {userCircles && userCircles.length > 0 ? (
                userCircles.map((circleAddr: string, index: number) => (
                  <CircleSelectItem 
                    key={`circle-${circleAddr}-${index}`} 
                    address={circleAddr} 
                    index={index} 
                  />
                ))
              ) : (
                <SelectItem key="no-circles" value="no-circles" disabled>
                  No circles found
                </SelectItem>
              )}
            </SelectContent>
          </Select>
        </div>
        
        {selectedCircle && (
          <CollateralDisplay 
            circleAddress={selectedCircle}
            circleName={circleName as string}
            userBalance={userBalance}
            maxBorrowAmount={maxBorrowAmount}
          />
        )}

        <div className="space-y-2">
          <Label htmlFor="amount">Borrow Amount</Label>
          <div className="relative">
            <Coins className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input
              id="amount"
              type="number"
              placeholder="Enter amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="pl-10"
              min="0"
              step="any"
            />
          </div>
          <div className="px-2">
            <Slider
              value={[numericAmount]}
              onValueChange={(value) => setAmount(value[0].toString())}
              max={Math.max(maxBorrowAmount, numericAmount) * 1.5} // Allow 50% more than current amount or max borrowable
              min={0}
              step={maxBorrowAmount / 100}
              className="w-full"
            />
          </div>
          <p className="text-sm text-muted-foreground">
            Maximum: {CURRENCY_SYMBOL}{maxBorrowAmount.toFixed(8)}
          </p>
        </div>

        {needsHelp && selectedCircle && (
          <>
            <MorphoCollateralizationInfo 
              requestedLoan={numericAmount}
              userCollateral={userBalance}
              collateralNeeded={collateralNeededForMorpho}
              shortfall={shortfall}
              morphoLTV={morphoLTV}
            />
            <SocialCollateralRequest
              shortfall={shortfall}
              circleAddress={selectedCircle}
              circleName={circleName as string}
              requestedAmount={numericAmount}
              memberContributions={memberContributions}
              setMemberContributions={setMemberContributions}
            />
          </>
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
                {CURRENCY_SYMBOL}{netCost.toFixed(8)}/year
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
                {CURRENCY_SYMBOL}{monthlyPayment.toFixed(8)}
              </span>
            </div>
          </div>
        </div>
      )}

      <div className="flex gap-2">
        <Button
          type="submit"
          disabled={!isValidAmount || !selectedCircle || (needsHelp && selectedContributions.length === 0)}
          className="flex-1 gap-2"
        >
          <Calculator className="w-4 h-4" />
          {needsHelp ? 'Request Collateral Help' : 'Confirm Borrow'}
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
        <p className="text-muted-foreground">Borrow Amount</p>
      </div>

      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <span className="text-sm">Loan Amount</span>
          <span className="font-medium">{CURRENCY_SYMBOL}{numericAmount.toLocaleString()}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm">Collateral Required</span>
          <span className="font-medium">{CURRENCY_SYMBOL}{userBalance.toFixed(8)}</span>
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
          <span className="font-medium">{CURRENCY_SYMBOL}{monthlyPayment.toFixed(8)}</span>
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
          {CURRENCY_SYMBOL}{numericAmount.toFixed(8)} has been transferred to your account
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

function CircleSelectItem({ address, index }: { address: string; index: number }) {
  const { data: circleName } = useCircleName(address);
  const displayName = circleName || `Circle ${index + 1}`;
  
  return (
    <SelectItem value={address}>
      <div className="flex flex-col">
        <span className="font-medium">{displayName}</span>
        <span className="text-xs text-muted-foreground">
          {address.slice(0, 6)}...{address.slice(-4)}
        </span>
      </div>
    </SelectItem>
  );
}

function CollateralDisplay({ 
  circleAddress, 
  circleName, 
  userBalance, 
  maxBorrowAmount 
}: { 
  circleAddress: string; 
  circleName: string; 
  userBalance: number; 
  maxBorrowAmount: number; 
}) {
  return (
    <div className="p-4 bg-blue-50 rounded-lg">
      <div className="flex items-center gap-2 mb-2">
        <Info className="w-4 h-4 text-blue-600" />
        <span className="text-sm font-medium text-blue-900">
          Collateral in {circleName || 'Selected Circle'}
        </span>
      </div>
      <div className="text-2xl font-bold text-blue-900">
        {CURRENCY_SYMBOL}{userBalance.toFixed(8)}
      </div>
      <p className="text-sm text-blue-600">
        Available to borrow: {CURRENCY_SYMBOL}{maxBorrowAmount.toFixed(8)} ({(DEFAULT_LTV * 100)}% LTV)
      </p>
      <div className="text-xs text-blue-500 mt-1">
        {circleAddress.slice(0, 6)}...{circleAddress.slice(-4)}
      </div>
    </div>
  );
}

interface MemberContribution {
  address: string;
  amount: number;
  selected: boolean;
}

function SocialCollateralRequest({
  shortfall,
  circleAddress,
  circleName,
  requestedAmount,
  memberContributions,
  setMemberContributions
}: {
  shortfall: number;
  circleAddress: string;
  circleName: string;
  requestedAmount: number;
  memberContributions: MemberContribution[];
  setMemberContributions: React.Dispatch<React.SetStateAction<MemberContribution[]>>;
}) {
  const { data: circleMembers } = useCircleMembers(circleAddress);
  const { address: currentUser } = useAccount();
  
  // Filter out current user from member list
  const availableMembers = React.useMemo(() => {
    if (!circleMembers || !currentUser) return [];
    return circleMembers.filter((member: string) => 
      member.toLowerCase() !== currentUser.toLowerCase()
    );
  }, [circleMembers, currentUser]);
  
  // Get member names for the available members
  const memberInfos = useMemberNames(availableMembers);

  // Initialize member contributions when members are loaded
  React.useEffect(() => {
    if (memberInfos.length > 0 && memberContributions.length === 0) {
      const initialContributions = memberInfos.map(member => ({
        address: member.address,
        amount: 0,
        selected: false
      }));
      setMemberContributions(initialContributions);
    }
  }, [memberInfos, memberContributions.length]);

  // Calculate totals
  const selectedContributions = memberContributions.filter(m => m.selected);
  const totalAllocated = selectedContributions.reduce((sum, m) => sum + m.amount, 0);
  const remainingAmount = Math.max(0, shortfall - totalAllocated);
  const isValidAllocation = Math.abs(totalAllocated - shortfall) < 0.00000001; // Handle floating point precision

  // Auto-distribute remaining amount equally among selected members
  const autoDistribute = () => {
    if (selectedContributions.length === 0) return;
    
    const amountPerMember = shortfall / selectedContributions.length;
    setMemberContributions(prev => 
      prev.map(member => 
        member.selected 
          ? { ...member, amount: amountPerMember }
          : member
      )
    );
  };

  // Toggle member selection
  const toggleMember = (address: string) => {
    setMemberContributions(prev =>
      prev.map(member =>
        member.address === address
          ? { ...member, selected: !member.selected, amount: member.selected ? 0 : member.amount }
          : member
      )
    );
  };

  // Update member amount
  const updateAmount = (address: string, amount: number) => {
    setMemberContributions(prev =>
      prev.map(member =>
        member.address === address
          ? { ...member, amount: Math.max(0, amount) }
          : member
      )
    );
  };

  const getMemberInfo = (address: string) => {
    return memberInfos.find(info => info.address === address);
  };

  return (
    <div className="p-4 bg-purple-50 rounded-lg border border-purple-200">
      <div className="flex items-center gap-2 mb-3">
        <Users className="w-4 h-4 text-purple-600" />
        <span className="text-sm font-medium text-purple-900">Request Collateral Help</span>
      </div>
      
      <div className="space-y-3 mb-4">
        <div className="flex justify-between text-sm">
          <span className="text-purple-700">Requested Loan:</span>
          <span className="font-medium text-purple-900">
            {CURRENCY_SYMBOL}{requestedAmount.toFixed(8)}
          </span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-purple-700">Additional Collateral Needed:</span>
          <span className="font-medium text-purple-900">
            {CURRENCY_SYMBOL}{shortfall.toFixed(8)}
          </span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-purple-700">Total Allocated:</span>
          <span className={`font-medium ${isValidAllocation ? 'text-green-700' : 'text-orange-700'}`}>
            {CURRENCY_SYMBOL}{totalAllocated.toFixed(8)}
          </span>
        </div>
        {remainingAmount > 0 && (
          <div className="flex justify-between text-sm">
            <span className="text-purple-700">Remaining:</span>
            <span className="font-medium text-orange-700">
              {CURRENCY_SYMBOL}{remainingAmount.toFixed(8)}
            </span>
          </div>
        )}
      </div>

      {memberContributions.length > 0 && (
        <div className="space-y-3 mb-4">
          <div className="flex items-center justify-between">
            <Label className="text-sm font-medium text-purple-900">
              Select members and allocate amounts:
            </Label>
            {selectedContributions.length > 0 && (
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={autoDistribute}
                className="text-xs text-purple-600 hover:text-purple-800"
              >
                Auto-distribute
              </Button>
            )}
          </div>
          
          <div className="space-y-2 max-h-48 overflow-y-auto">
            {memberContributions.map((contribution) => {
              const memberInfo = getMemberInfo(contribution.address);
              if (!memberInfo) return null;
              
              return (
                <div 
                  key={contribution.address}
                  className={`p-3 rounded-lg border ${contribution.selected ? 'bg-purple-100 border-purple-300' : 'bg-white border-purple-200'}`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={contribution.selected}
                        onChange={() => toggleMember(contribution.address)}
                        className="rounded border-purple-300 text-purple-600 focus:ring-purple-500"
                      />
                      <div>
                        <div className="font-medium text-sm text-purple-900">
                          {memberInfo.displayName}
                        </div>
                        <div className="text-xs text-purple-600">
                          {contribution.address.slice(0, 6)}...{contribution.address.slice(-4)}
                        </div>
                      </div>
                    </div>
                    {contribution.selected && (
                      <div className="flex items-center gap-1">
                        <span className="text-xs text-purple-700">{CURRENCY_SYMBOL}</span>
                        <input
                          type="number"
                          step="any"
                          min="0"
                          max={shortfall}
                          value={contribution.amount}
                          onChange={(e) => updateAmount(contribution.address, parseFloat(e.target.value) || 0)}
                          className="w-24 px-2 py-1 text-xs border border-purple-300 rounded focus:ring-purple-500 focus:border-purple-500"
                          placeholder="0.0"
                        />
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      <div className="text-xs text-purple-600 mb-3 p-2 bg-purple-100 rounded">
        <strong>How it works:</strong> Friends use their existing vault deposits (currently earning 5% APY). 
        Their contributions become wstETH collateral in Morpho, earning staking yield while securing your loan!
      </div>

      <div className="text-xs text-purple-600 mb-3 p-2 bg-purple-100 rounded">
        <strong>Win-Win:</strong> You get the loan you need. Friends earn higher yield on their deposits. 
        Everyone benefits from the over-collateralized DeFi system!
      </div>
    </div>
  );
}

function MorphoCollateralizationInfo({
  requestedLoan,
  userCollateral,
  collateralNeeded,
  shortfall,
  morphoLTV
}: {
  requestedLoan: number;
  userCollateral: number;
  collateralNeeded: number;
  shortfall: number;
  morphoLTV: number;
}) {
  return (
    <div className="p-4 bg-blue-50 rounded-lg border border-blue-200 mb-4">
      <div className="flex items-center gap-2 mb-3">
        <Info className="w-4 h-4 text-blue-600" />
        <span className="text-sm font-medium text-blue-900">Morpho Over-Collateralization Required</span>
      </div>
      
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-blue-700">Loan Amount:</span>
          <span className="font-medium text-blue-900">{CURRENCY_SYMBOL}{requestedLoan.toFixed(6)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-blue-700">Morpho LTV Ratio:</span>
          <span className="font-medium text-blue-900">{(morphoLTV * 100)}%</span>
        </div>
        <div className="flex justify-between">
          <span className="text-blue-700">Total Collateral Needed:</span>
          <span className="font-medium text-blue-900">{CURRENCY_SYMBOL}{collateralNeeded.toFixed(6)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-blue-700">Your Collateral:</span>
          <span className="font-medium text-blue-900">{CURRENCY_SYMBOL}{userCollateral.toFixed(6)}</span>
        </div>
        <div className="border-t border-blue-200 pt-2">
          <div className="flex justify-between">
            <span className="text-blue-700 font-medium">Need from Friends:</span>
            <span className="font-bold text-blue-900">{CURRENCY_SYMBOL}{shortfall.toFixed(6)}</span>
          </div>
        </div>
      </div>
      
      <div className="mt-3 p-2 bg-blue-100 rounded text-xs text-blue-700">
        <strong>Why over-collateralized?</strong> Morpho requires {(morphoLTV * 100)}% LTV for safety. 
        Friends' contributions become productive collateral earning staking yield!
      </div>
    </div>
  );
}

