'use client';

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { 
  TrendingUp, 
  Coins, 
  PiggyBank, 
  CreditCard, 
  Users,
  ArrowUpRight,
  ArrowDownRight,
  DollarSign
} from 'lucide-react';
import { CURRENCY_SYMBOL, BASE_YIELD_RATE, BORROWING_RATE } from '@/constants';
import { useUserCirclesDirect as useUserCircles, useAggregatedUserData, useCircleName, useUserCircleBalance } from '@/hooks/useBalance';
import { formatEther } from 'viem';
import { useAccount } from 'wagmi';
import CreateCircle from '@/components/circle/create-circle';
import { RepayForm } from '@/components/lending/repay-form';

// Individual circle display component with React.memo for performance
const CircleDisplay = React.memo(({ circleAddress, index }: { circleAddress: string, index: number }) => {
  const { address } = useAccount();
  const { data: circleName, isLoading: nameLoading } = useCircleName(circleAddress);
  const { data: userBalance, isLoading: balanceLoading } = useUserCircleBalance(address, circleAddress);
  
  // Get the user's actual balance from smart contract
  const balanceInEth = userBalance ? parseFloat(formatEther(userBalance)) : 0;
  
  // Memoize expensive calculations
  const calculations = React.useMemo(() => ({
    balanceFormatted: `${CURRENCY_SYMBOL}${balanceInEth.toFixed(8)}`,
    availableFormatted: `${CURRENCY_SYMBOL}${(balanceInEth * 0.85).toFixed(8)}`
  }), [balanceInEth]);
  
  return (
    <div className="p-2 border rounded-cow glass-subtle border-soft animate-gentle-scale">
      <div className="flex items-center justify-between mb-2">
        <div>
          <div className="font-medium text-primary text-sm">
            {nameLoading ? `Circle ${index + 1}` : (circleName || `Circle ${index + 1}`)}
          </div>
          <div className="text-xs text-accent">
            {circleAddress.slice(0, 6)}...{circleAddress.slice(-4)}
          </div>
        </div>
        <div className="text-right">
          <div className="text-sm font-medium text-primary">
            {balanceLoading ? 'Loading...' : calculations.balanceFormatted}
          </div>
          <div className="text-xs text-accent">
            Available: {calculations.availableFormatted}
          </div>
        </div>
      </div>
      
      <div className="grid grid-cols-3 gap-1 text-xs mt-1">
        <div>
          <span className="text-accent">Balance:</span>
          <div className="font-medium text-xs">
            {balanceLoading ? 'Loading...' : calculations.balanceFormatted}
          </div>
        </div>
        <div>
          <span className="text-accent">Yield:</span>
          <div className="font-medium text-green-600 text-xs">
            +{CURRENCY_SYMBOL}0.00000000
          </div>
        </div>
        <div>
          <span className="text-accent">Growth:</span>
          <div className="font-medium text-xs">0.00%</div>
        </div>
      </div>
    </div>
  );
});

interface DashboardContentProps {
  user?: {
    balance: number;
    availableToBorrow: number;
    currentLoan: number;
    yieldEarned: number;
  };
  onDeposit: () => void;
  onBorrow: () => void;
  onViewCircle: () => void;
  onCreateCircle?: () => void;
}

const DashboardContent = React.memo(({ 
  user = {
    balance: 0,
    availableToBorrow: 0,
    currentLoan: 0,
    yieldEarned: 0
  },
  onDeposit,
  onBorrow,
  onViewCircle,
  onCreateCircle
}: DashboardContentProps) => {
  // Check if user has any circles - but don't block dashboard render
  const { data: userCircles, isLoading: circlesLoading, error: circlesError } = useUserCircles();
  const hasCircles = userCircles && Array.isArray(userCircles) && userCircles.length > 0;
  
  // Load data immediately but show progressive UI
  const [shouldLoadData, setShouldLoadData] = React.useState(true);
  
  // Get aggregated data only after initial render
  const { data: aggregatedData, isLoading: dataLoading } = useAggregatedUserData();
  
  // Track active loans from sessionStorage
  const [activeLoans, setActiveLoans] = React.useState<any[]>([]);
  const [showRepayForm, setShowRepayForm] = React.useState<string | null>(null);

  // Load active loans from sessionStorage
  React.useEffect(() => {
    const loadActiveLoans = () => {
      try {
        const storedLoans = sessionStorage.getItem('userActiveLoans');
        if (storedLoans) {
          const loans = JSON.parse(storedLoans);
          // Dashboard loaded active loans
          setActiveLoans(loans);
        } else {
          setActiveLoans([]);
        }
      } catch (error) {
        console.warn('Error loading active loans:', error);
        setActiveLoans([]);
      }
    };

    // Load on mount
    loadActiveLoans();

    // Listen for loan execution events
    const handleLoanExecuted = (_event: CustomEvent) => {
      // Dashboard received loanExecuted event
      loadActiveLoans(); // Reload from storage
    };

    const handleLoanRepaid = (_event: CustomEvent) => {
      // Dashboard received loanRepaid event
      loadActiveLoans(); // Reload from storage
    };

    window.addEventListener('loanExecuted', handleLoanExecuted as EventListener);
    window.addEventListener('loanRepaid', handleLoanRepaid as EventListener);

    // Cleanup
    return () => {
      window.removeEventListener('loanExecuted', handleLoanExecuted as EventListener);
      window.removeEventListener('loanRepaid', handleLoanRepaid as EventListener);
    };
  }, []);


  // Memoize circle detection to reduce re-computations
  const circleStatus = React.useMemo(() => ({
    hasCircles,
    shouldShowCreate: (!hasCircles || circlesError),
    userCircles: userCircles || []
  }), [hasCircles, circlesError, userCircles]);

  const effectiveRate = user.currentLoan > 0 ? 
    ((BORROWING_RATE * user.currentLoan) - (BASE_YIELD_RATE * user.balance)) / user.currentLoan : 
    0;

  // Show dashboard shell immediately, load data progressively
  const showLoader = circlesLoading && !shouldLoadData;

  // Show circle creation if user has no circles OR if there's an RPC error
  if (circleStatus.shouldShowCreate) {
    return (
      <div className="flex-1 space-y-6 p-6">
        <div className="text-center space-y-4 mb-8">
          <h1 className="text-3xl font-bold">Welcome to HorizonCircle!</h1>
          <p className="text-muted-foreground max-w-md mx-auto">
            Create or join a savings circle to start saving and borrowing with your community.
          </p>
          {circlesError && (
            <div className="p-3 bg-orange-50 border border-orange-200 rounded-lg max-w-md mx-auto">
              <p className="text-sm text-orange-700">
                Unable to check existing circles. You can still create a new one!
              </p>
            </div>
          )}
        </div>
        <CreateCircle onSuccess={onCreateCircle} />
      </div>
    );
  }

  return (
    <div className="p-4 space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-foreground">Dashboard</h2>
          <p className="text-muted-foreground text-sm">Welcome back to your financial overview</p>
        </div>
        <div className="flex gap-2">
          <Button onClick={onDeposit} className="gap-2 btn-interactive">
            <PiggyBank className="w-4 h-4" />
            Earn
          </Button>
          <Button onClick={onBorrow} variant="outline" className="gap-2 btn-interactive">
            <CreditCard className="w-4 h-4" />
            Borrow
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="glass-card-light border-soft rounded-cow card-hover animate-stagger-in">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-1">
            <CardTitle className="text-sm font-medium">ETH Balance</CardTitle>
            <Coins className="w-4 h-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-xl font-bold">
              {dataLoading ? 
                `${CURRENCY_SYMBOL}0.00000000` :
                `${CURRENCY_SYMBOL}${aggregatedData?.totalBalance?.toFixed(8) || '0.00000000'}`
              }
            </div>
            <p className="text-xs text-muted-foreground">
              Earning {(BASE_YIELD_RATE * 100).toFixed(1)}% APY
            </p>
          </CardContent>
        </Card>

        <Card className="glass-card-light border-soft rounded-cow card-hover animate-stagger-in animate-stagger-1">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-1">
            <CardTitle className="text-sm font-medium">Available to Borrow</CardTitle>
            <CreditCard className="w-4 h-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-xl font-bold">
              {dataLoading ? 
                `${CURRENCY_SYMBOL}0.00000000` :
                `${CURRENCY_SYMBOL}${aggregatedData?.totalAvailableToBorrow?.toFixed(8) || '0.00000000'}`
              }
            </div>
            <p className="text-xs text-muted-foreground">
              At 0.0% effective rate
            </p>
          </CardContent>
        </Card>

        <Card className="glass-card-light border-soft rounded-cow card-hover animate-stagger-in animate-stagger-2">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-1">
            <CardTitle className="text-sm font-medium">Current Loans</CardTitle>
            <ArrowDownRight className="w-4 h-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-xl font-bold">
              {dataLoading ? 
                `${CURRENCY_SYMBOL}0.00000000` :
                `${CURRENCY_SYMBOL}${aggregatedData?.totalCurrentLoans?.toFixed(8) || '0.00000000'}`
              }
            </div>
            <p className="text-xs text-muted-foreground">
              {(aggregatedData?.totalCurrentLoans || 0) > 0 ? (
                <span className="text-orange-600 font-medium">Your active loans</span>
              ) : (
                'No active loans'
              )}
            </p>
            {(aggregatedData?.totalCurrentLoans || 0) > 0 && (
              <div className="mt-2 space-y-1">
                <div className="text-xs text-muted-foreground">
                  <span className="font-medium">From:</span> Circle contributors
                </div>
                <div className="text-xs text-green-600">
                  <span className="font-medium">Rate:</span> ~0.1% APR effective
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="glass-card-light border-soft rounded-cow card-hover animate-stagger-in animate-stagger-3">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-1">
            <CardTitle className="text-sm font-medium">Yield Earned</CardTitle>
            <ArrowUpRight className="w-4 h-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              {dataLoading ? 
                `+${CURRENCY_SYMBOL}0.00000000` :
                `+${CURRENCY_SYMBOL}${aggregatedData?.totalYieldEarned?.toFixed(8) || '0.00000000'}`
              }
            </div>
            <p className="text-xs text-muted-foreground">
              Total earned this month
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Rate Overview */}
        <Card className="glass-card-light border-soft rounded-cow card-hover animate-stagger-in">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-primary" />
              Rate Overview
            </CardTitle>
            <CardDescription>
              Current market rates and your effective cost
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Savings Rate</span>
              <Badge variant="secondary" className="text-green-600">
                {(BASE_YIELD_RATE * 100).toFixed(1)}% APY
              </Badge>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Borrowing Rate</span>
              <Badge variant="secondary" className="text-accent">
                {(BORROWING_RATE * 100).toFixed(1)}% APR
              </Badge>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Your Effective Rate</span>
              <Badge variant="secondary" className="text-primary">
                {(effectiveRate * 100).toFixed(1)}% APR
              </Badge>
            </div>
            <Separator />
            <div className="text-sm text-muted-foreground">
              Your effective rate factors in the yield you earn on your collateral
            </div>
          </CardContent>
        </Card>

        {/* Circle Breakdown */}
        <Card className="glass-card-light border-soft rounded-cow card-hover animate-stagger-in">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="w-5 h-5 text-primary" />
              Your Circles ({userCircles?.length || 0})
            </CardTitle>
            <CardDescription>
              Individual circle balances and performance
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {shouldLoadData && userCircles && userCircles.length > 0 ? (
              <>
                {userCircles.map((circleAddress, index) => (
                  <CircleDisplay key={circleAddress} circleAddress={circleAddress} index={index} />
                ))}
                <Separator />
                <Button 
                  variant="outline" 
                  className="w-full gap-2"
                  onClick={onViewCircle}
                  className="btn-interactive"
                >
                  <Users className="w-4 h-4" />
                  Manage Circles
                </Button>
              </>
            ) : !shouldLoadData ? (
              <div className="space-y-3">
                <div className="animate-pulse bg-gray-100 h-16 rounded-lg"></div>
                <div className="animate-pulse bg-gray-100 h-8 w-32 rounded mx-auto"></div>
              </div>
            ) : (
              <>
                <div className="text-center py-4 text-muted-foreground">
                  <Users className="w-12 h-12 mx-auto mb-3 opacity-30" />
                  <p className="text-sm">No circles found</p>
                  <p className="text-xs mt-1">Create or join a circle to start</p>
                </div>
                <Button 
                  variant="outline" 
                  className="w-full gap-2"
                  onClick={onViewCircle}
                  className="btn-interactive"
                >
                  <Users className="w-4 h-4" />
                  Create or Join Circle
                </Button>
              </>
            )}
          </CardContent>
        </Card>

        {/* Active Loans Management */}
        {activeLoans.length > 0 && (
          <Card className="glass-card-light border-soft rounded-cow card-hover animate-stagger-in">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <DollarSign className="w-5 h-5 text-orange-600" />
                Loan Management
              </CardTitle>
              <CardDescription>
                Manage your active loans and repayments
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {activeLoans.map((loan, index) => (
                <div key={loan.id || index} className="p-3 border rounded-cow glass-subtle border-soft">
                  <div className="flex items-center justify-between mb-2">
                    <div>
                      <div className="font-medium text-orange-900">
                        {CURRENCY_SYMBOL}{loan.amount?.toFixed(8) || '0.00000000'}
                      </div>
                      <div className="text-xs text-orange-600">
                        Loan #{(loan.id?.slice(0, 8) || 'unknown')}...
                      </div>
                    </div>
                    <Badge variant="outline" className="text-orange-700 border-orange-300">
                      Active
                    </Badge>
                  </div>
                  
                  <div className="text-xs text-accent mb-3">
                    <div><strong>Purpose:</strong> {loan.purpose || 'N/A'}</div>
                    <div><strong>Started:</strong> {loan.startTime ? new Date(loan.startTime).toLocaleDateString() : 'N/A'}</div>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-sm text-accent">Ready to repay?</span>
                    <Button
                      size="sm"
                      variant={showRepayForm === loan.id ? "outline" : "default"}
                      onClick={() => setShowRepayForm(showRepayForm === loan.id ? null : loan.id)}
                      className="text-xs"
                    >
                      {showRepayForm === loan.id ? 'Cancel' : 'Repay Loan'}
                    </Button>
                  </div>

                  {showRepayForm === loan.id && (
                    <div className="mt-3">
                      <RepayForm
                        loanId={loan.id}
                        loanAmount={loan.amount || 0}
                        circleAddress={loan.circleAddress}
                        onSuccess={() => setShowRepayForm(null)}
                      />
                    </div>
                  )}
                </div>
              ))}
            </CardContent>
          </Card>
        )}
        
      </div>

      {/* Recent Transactions */}
      <Card className="glass-card-light border-soft rounded-cow animate-gentle-scale">
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
          <CardDescription>
            Your latest deposits, borrows, and repayments
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            <CreditCard className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>No recent activity</p>
            <p className="text-sm">Your transactions will appear here</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
});

export default DashboardContent;