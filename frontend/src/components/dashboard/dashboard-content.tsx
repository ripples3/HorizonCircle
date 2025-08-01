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
import { NotificationTest } from '@/components/notification-test';
import { RepayForm } from '@/components/lending/repay-form';

// Individual circle display component  
function CircleDisplay({ circleAddress, index }: { circleAddress: string, index: number }) {
  const { address } = useAccount();
  const { data: circleName, isLoading: nameLoading } = useCircleName(circleAddress);
  const { data: userBalance, isLoading: balanceLoading } = useUserCircleBalance(address, circleAddress);
  
  // Get the user's actual balance from smart contract
  const balanceInEth = userBalance ? parseFloat(formatEther(userBalance)) : 0;
  
  // Memoize the balance display to prevent re-renders
  const balanceDisplay = React.useMemo(() => ({
    circleAddress,
    balanceInEth,
    isLoading: balanceLoading
  }), [circleAddress, balanceInEth, balanceLoading]);
  
  return (
    <div className="p-3 border rounded-lg bg-purple-50 border-purple-200">
      <div className="flex items-center justify-between mb-2">
        <div>
          <div className="font-medium text-purple-900">
            {nameLoading ? `Circle ${index + 1}` : (circleName || `Circle ${index + 1}`)}
          </div>
          <div className="text-xs text-purple-600">
            {circleAddress.slice(0, 6)}...{circleAddress.slice(-4)}
          </div>
        </div>
        <div className="text-right">
          <div className="text-sm font-medium text-purple-900">
            {balanceLoading ? 'Loading...' : `${CURRENCY_SYMBOL}${balanceInEth.toFixed(8)}`}
          </div>
          <div className="text-xs text-purple-600">
            Available: {CURRENCY_SYMBOL}{(balanceInEth * 0.85).toFixed(8)}
          </div>
        </div>
      </div>
      
      <div className="grid grid-cols-3 gap-2 text-xs">
        <div>
          <span className="text-purple-600">Balance:</span>
          <div className="font-medium">
            {balanceLoading ? 'Loading...' : `${CURRENCY_SYMBOL}${balanceInEth.toFixed(8)}`}
          </div>
        </div>
        <div>
          <span className="text-purple-600">Yield:</span>
          <div className="font-medium text-green-600">
            +{CURRENCY_SYMBOL}0.00000000
          </div>
        </div>
        <div>
          <span className="text-purple-600">Growth:</span>
          <div className="font-medium">0.00%</div>
        </div>
      </div>
    </div>
  );
}

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

export default function DashboardContent({ 
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
}: DashboardContentProps) {
  // Check if user has any circles
  const { data: userCircles, isLoading: circlesLoading, error: circlesError } = useUserCircles();
  const hasCircles = userCircles && Array.isArray(userCircles) && userCircles.length > 0;
  
  // Get aggregated data across all circles
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

  // Show loading while checking circles or data
  if (circlesLoading || dataLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

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
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Dashboard</h2>
          <p className="text-gray-600 mt-1">Welcome back to your financial overview</p>
        </div>
        <div className="flex gap-2">
          <Button onClick={onDeposit} className="gap-2">
            <PiggyBank className="w-4 h-4" />
            Earn
          </Button>
          <Button onClick={onBorrow} variant="outline" className="gap-2">
            <CreditCard className="w-4 h-4" />
            Borrow
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">ETH Balance</CardTitle>
            <Coins className="w-4 h-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {dataLoading ? 'Loading...' : `${CURRENCY_SYMBOL}${aggregatedData?.totalBalance?.toFixed(8) || '0.00000000'}`}
            </div>
            <p className="text-xs text-muted-foreground">
              Earning {(BASE_YIELD_RATE * 100).toFixed(1)}% APY
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Available to Borrow</CardTitle>
            <CreditCard className="w-4 h-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {dataLoading ? 'Loading...' : `${CURRENCY_SYMBOL}${aggregatedData?.totalAvailableToBorrow?.toFixed(8) || '0.00000000'}`}
            </div>
            <p className="text-xs text-muted-foreground">
              At 0.0% effective rate
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Current Loans</CardTitle>
            <ArrowDownRight className="w-4 h-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {dataLoading ? 'Loading...' : `${CURRENCY_SYMBOL}${aggregatedData?.totalCurrentLoans?.toFixed(8) || '0.00000000'}`}
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

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Yield Earned</CardTitle>
            <ArrowUpRight className="w-4 h-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              {dataLoading ? 'Loading...' : `+${CURRENCY_SYMBOL}${aggregatedData?.totalYieldEarned?.toFixed(8) || '0.00000000'}`}
            </div>
            <p className="text-xs text-muted-foreground">
              Total earned this month
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Rate Overview */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-blue-600" />
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
              <Badge variant="secondary" className="text-blue-600">
                {(BORROWING_RATE * 100).toFixed(1)}% APR
              </Badge>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Your Effective Rate</span>
              <Badge variant="secondary" className="text-purple-600">
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
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="w-5 h-5 text-purple-600" />
              Your Circles ({userCircles?.length || 0})
            </CardTitle>
            <CardDescription>
              Individual circle balances and performance
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {userCircles && userCircles.length > 0 ? (
              <>
                {userCircles.map((circleAddress, index) => (
                  <CircleDisplay key={circleAddress} circleAddress={circleAddress} index={index} />
                ))}
                <Separator />
                <Button 
                  variant="outline" 
                  className="w-full gap-2"
                  onClick={onViewCircle}
                >
                  <Users className="w-4 h-4" />
                  Manage Circles
                </Button>
              </>
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
          <Card>
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
                <div key={loan.id || index} className="p-3 border rounded-lg bg-orange-50 border-orange-200">
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
                  
                  <div className="text-xs text-orange-600 mb-3">
                    <div><strong>Purpose:</strong> {loan.purpose || 'N/A'}</div>
                    <div><strong>Started:</strong> {loan.startTime ? new Date(loan.startTime).toLocaleDateString() : 'N/A'}</div>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-sm text-orange-700">Ready to repay?</span>
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
        
        {/* Debug Panel - Remove in production */}
        <NotificationTest />
      </div>

      {/* Recent Transactions */}
      <Card>
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
}