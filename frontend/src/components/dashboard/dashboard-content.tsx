'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { 
  TrendingUp, 
  DollarSign, 
  PiggyBank, 
  CreditCard, 
  Users,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react';
import { CURRENCY_SYMBOL, BASE_YIELD_RATE, BORROWING_RATE } from '@/constants';

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
  onViewCircle
}: DashboardContentProps) {
  const effectiveRate = user.currentLoan > 0 ? 
    ((BORROWING_RATE * user.currentLoan) - (BASE_YIELD_RATE * user.balance)) / user.currentLoan : 
    0;

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
            Deposit
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
            <CardTitle className="text-sm font-medium">USD Balance</CardTitle>
            <DollarSign className="w-4 h-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {CURRENCY_SYMBOL}{user.balance.toLocaleString()}
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
              {CURRENCY_SYMBOL}{user.availableToBorrow.toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">
              At {(effectiveRate * 100).toFixed(1)}% effective rate
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Current Loan</CardTitle>
            <ArrowDownRight className="w-4 h-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {CURRENCY_SYMBOL}{user.currentLoan.toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">
              {user.currentLoan > 0 ? 'Active loan' : 'No active loan'}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Yield Earned</CardTitle>
            <ArrowUpRight className="w-4 h-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              +{CURRENCY_SYMBOL}{user.yieldEarned.toLocaleString()}
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

        {/* Circle Activity */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="w-5 h-5 text-purple-600" />
              Circle Activity
            </CardTitle>
            <CardDescription>
              Your lending circle status and opportunities
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Circle Members</span>
              <span className="text-sm text-muted-foreground">Not in a circle</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Active Requests</span>
              <span className="text-sm text-muted-foreground">0</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Contributions Made</span>
              <span className="text-sm text-muted-foreground">0</span>
            </div>
            <Separator />
            <Button 
              variant="outline" 
              className="w-full gap-2"
              onClick={onViewCircle}
            >
              <Users className="w-4 h-4" />
              Join or Create Circle
            </Button>
          </CardContent>
        </Card>
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