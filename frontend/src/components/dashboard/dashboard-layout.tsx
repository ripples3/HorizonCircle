'use client';

import React, { useState, useEffect, lazy, Suspense } from 'react';
import { usePrivy } from '@privy-io/react-auth';
import Sidebar from './sidebar';

// Lazy load heavy components
const DashboardContent = lazy(() => import('./dashboard-content'));
const DepositForm = lazy(() => import('@/components/lending/deposit-form'));
const BorrowForm = lazy(() => import('@/components/lending/borrow-form'));
const DirectLTVWithdraw = lazy(() => import('@/components/lending/direct-ltv-withdraw').then(mod => ({ default: mod.DirectLTVWithdraw })));
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useUserData } from '@/hooks/useUserData';
import { useUserCirclesDirect as useUserCircles, useUserCircleBalance } from '@/hooks/useBalance';
import { useAccount, useChainId, useSwitchChain } from 'wagmi';
import { useRequestCollateral } from '@/hooks/useTransactions';
import { formatEther } from 'viem';
import { LISK_CHAIN_ID } from '@/constants';
import CircleManagement from '@/components/circle/circle-management';
import CollateralNotification from '@/components/dashboard/collateral-notification';
// Lazy load heavy notification components  
const BorrowerRequests = lazy(() => import('@/components/lending/borrower-requests'));
const CollateralRequests = lazy(() => import('@/components/lending/collateral-requests'));

export default function DashboardLayout() {
  const { user, logout } = usePrivy();
  const { userData, loading, error } = useUserData();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [activeLoanAmount, setActiveLoanAmount] = useState(0);
  
  // Get wallet address and blockchain data
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  
  // Fallback to Privy wallet if wagmi doesn't detect it
  const walletAddress = address || user?.wallet?.address;
  const isWalletConnected = isConnected || !!walletAddress;
  
  // Removed excessive console logging and debug components for better performance
  
  const { data: userCircles } = useUserCircles();
  const hasCircles = Boolean(userCircles && userCircles.length > 0);
  
  // Collateral request hook (will use the address from the callback)
  const { 
    requestCollateral, 
    hash: requestHash,
    isPending: isRequestingCollateral, 
    isConfirming: isConfirmingRequest,
    isConfirmed: isRequestConfirmed,
    error: requestError 
  } = useRequestCollateral();

  // Handle collateral request completion
  React.useEffect(() => {
    if (isRequestConfirmed && requestHash) {
      // Collateral request confirmed - show user feedback only
      alert('Collateral request created! Members have been notified and can now contribute or decline. Check "Your Collateral Requests" to track progress.');
      // Navigate back to dashboard after successful request
      setTimeout(() => setActiveTab('dashboard'), 2000);
    }
  }, [isRequestConfirmed, requestHash]);

  // Handle collateral request errors
  React.useEffect(() => {
    if (requestError) {
      console.error('Collateral request error:', requestError);
      alert(`Transaction failed: ${requestError.message || 'Please try again.'}`);
    }
  }, [requestError]);

  // Get real blockchain balance from the user's first circle (or default test circle)
  const selectedCircle = React.useMemo(() => {
    if (userCircles && userCircles.length > 0) {
      return userCircles[0];
    }
    return null; // No default circle - user must create one
  }, [userCircles]);
  
  const { data: blockchainBalance, error: balanceError, isLoading: balanceLoading } = useUserCircleBalance(
    walletAddress as `0x${string}`, 
    selectedCircle || undefined
  );
  
  const realBalance = React.useMemo(() => {
    return blockchainBalance ? parseFloat(formatEther(blockchainBalance)) : 0;
  }, [blockchainBalance]);

  // Check network and chain switching
  const isOnLiskNetwork = chainId === LISK_CHAIN_ID;
  const { switchChain } = useSwitchChain();

  // Listen for loan execution events
  useEffect(() => {
    // Load existing loans from session storage on mount
    const existingLoans = JSON.parse(sessionStorage.getItem('userActiveLoans') || '[]');
    const totalAmount = existingLoans.reduce((sum: number, loan: any) => sum + loan.amount, 0);
    setActiveLoanAmount(totalAmount);
    
    // Listen for new loan executions
    const handleLoanExecuted = (event: CustomEvent) => {
      const { allLoans } = event.detail;
      const totalAmount = allLoans.reduce((sum: number, loan: any) => sum + loan.amount, 0);
      setActiveLoanAmount(totalAmount);
      // Dashboard updated with new loan amount
    };
    
    window.addEventListener('loanExecuted', handleLoanExecuted as EventListener);
    
    return () => {
      window.removeEventListener('loanExecuted', handleLoanExecuted as EventListener);
    };
  }, []);

  // Simplified loading state - use improved wallet detection
  if (!isWalletConnected || !walletAddress) {
    return (
      <div className="min-h-screen bg-gradient-light flex items-center justify-center p-4">
        <div className="text-center glass-subtle p-8 rounded-cow-lg">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-foreground">Connecting wallet...</p>
          <p className="text-xs text-muted-foreground mt-2">
            Wagmi: {isConnected ? 'connected' : 'disconnected'} | Privy: {!!user?.wallet?.address ? 'wallet ready' : 'no wallet'}
          </p>
        </div>
      </div>
    );
  }

  const handleDeposit = () => {
    setActiveTab('deposit');
  };

  const handleBorrow = () => {
    setActiveTab('borrow');
  };

  const handleViewCircle = () => {
    setActiveTab('circle');
  };

  const handleCreateCircle = () => {
    // After circle creation, refresh to show dashboard with new circle
    setActiveTab('dashboard');
    // The useUserCircles hook will automatically refresh and detect the new circle
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        if (loading) {
          return (
            <div className="flex items-center justify-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
            </div>
          );
        }

        // Show dashboard even if database fails - user has blockchain wallet
        if (error) {
          console.warn('Database error (continuing with blockchain data only):', error);
          // Continue with blockchain-only mode
        }

        return (
          <div>
            {!isOnLiskNetwork && (
              <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg mb-4 mx-6 mt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="flex items-center gap-2 text-orange-700">
                      <span className="font-medium">⚠️ Wrong Network</span>
                    </div>
                    <p className="text-sm text-orange-600 mt-1">
                      You&apos;re on chain {chainId}. Switch to Lisk (chain {LISK_CHAIN_ID}) to see your balance.
                    </p>
                  </div>
                  <Button
                    onClick={() => switchChain({ chainId: LISK_CHAIN_ID })}
                    variant="outline"
                    size="sm"
                    className="border-orange-600 text-orange-600 hover:bg-orange-100"
                  >
                    Switch to Lisk
                  </Button>
                </div>
              </div>
            )}
            {!isWalletConnected && (
              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg mb-4 mx-6 mt-6">
                <div className="flex items-center gap-2 text-yellow-700">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-yellow-600"></div>
                  <span className="font-medium">Connecting wallet...</span>
                </div>
              </div>
            )}
            {isWalletConnected && balanceLoading && (
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg mb-4 mx-6 mt-6">
                <div className="flex items-center gap-2 text-blue-700">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
                  <span className="font-medium">Loading balance...</span>
                </div>
              </div>
            )}
            {balanceError && (
              <div className="p-4 bg-red-50 border border-red-200 rounded-lg mb-4 mx-6 mt-6">
                <div className="flex items-center gap-2 text-red-700">
                  <span className="font-medium">⚠️ Balance Error</span>
                </div>
                <p className="text-sm text-red-600 mt-1">
                  {balanceError.message || 'Failed to load balance. Try refreshing.'}
                </p>
              </div>
            )}
            {error && (
              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg mb-4 mx-6 mt-6">
                <div className="flex items-center gap-2 text-yellow-700">
                  <span className="font-medium">⚠️ Database Unavailable</span>
                </div>
                <p className="text-sm text-yellow-600 mt-1">
                  Running in blockchain-only mode. All core functionality available, some features may be limited.
                </p>
              </div>
            )}
            {/* Simple notification for collateral requests */}
            <CollateralNotification onNavigateToBorrow={() => setActiveTab('borrow')} />
            
            {/* Defer heavy notifications until after dashboard loads */}
            <Suspense fallback={<div className="p-2 animate-pulse bg-muted rounded-cow text-xs">Loading notifications...</div>}>
              <div className="space-y-2">
                <BorrowerRequests />
              </div>
            </Suspense>
            <Suspense fallback={<div className="animate-pulse h-96 bg-gray-100 rounded-lg" />}>
              <DashboardContent
                user={{
                  balance: realBalance,
                  availableToBorrow: realBalance * 0.85,
                  currentLoan: activeLoanAmount,
                  yieldEarned: userData?.yieldEarned || 0
                }}
                onDeposit={handleDeposit}
                onBorrow={handleBorrow}
                onViewCircle={handleViewCircle}
                onCreateCircle={handleCreateCircle}
              />
            </Suspense>
          </div>
        );
      case 'deposit':
        return (
          <div className="p-6 flex justify-center">
            <Suspense fallback={<div className="animate-pulse h-64 w-96 bg-gray-100 rounded-lg" />}>
              <DepositForm
                onSuccess={(_amount) => {
                  setActiveTab('dashboard');
                }}
                onCancel={() => setActiveTab('dashboard')}
              />
            </Suspense>
          </div>
        );
      case 'borrow':
        return (
          <div className="p-6">
            <div className="space-y-6">
              {/* Collateral Requests Section */}
              <Suspense fallback={<div className="p-2 animate-pulse bg-muted rounded-cow text-xs">Loading collateral requests...</div>}>
                <CollateralRequests />
              </Suspense>
              
              <div className="flex justify-center">
                <div className="w-full max-w-4xl">
                  {/* Transaction Status Display */}
              {(isRequestingCollateral || isConfirmingRequest) && (
                <Card className="mb-4 border-blue-200 bg-blue-50">
                  <CardContent className="p-4">
                    <div className="flex items-center gap-3">
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
                      <div className="text-sm">
                        {isRequestingCollateral && "Waiting for wallet confirmation..."}
                        {isConfirmingRequest && "Creating collateral request on blockchain..."}
                      </div>
                    </div>
                    {requestHash && (
                      <div className="mt-2 text-xs text-blue-700">
                        Transaction: {requestHash.slice(0, 10)}...{requestHash.slice(-8)}
                      </div>
                    )}
                  </CardContent>
                </Card>
              )}
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Social Lending (Traditional) */}
                <Suspense fallback={<div className="animate-pulse h-96 bg-gray-100 rounded-lg" />}>
                  <BorrowForm
                    onSuccess={(_amount) => {
                      setActiveTab('dashboard');
                    }}
                    onCancel={() => setActiveTab('dashboard')}
                  onRequestHelp={async (borrowAmount: number, collateralAmount: number, circleAddress: string, contributors: { address: string; amount: number; selected: boolean }[]) => {
                    // Help requested for collateral
                    
                    if (!contributors || contributors.length === 0) {
                      alert('Please select at least one circle member to request help from');
                      return;
                    }

                    try {
                      // Extract addresses from contributors
                      const contributorAddresses = contributors.map(c => c.address);
                      
                      // Create blockchain transaction for collateral request
                      await requestCollateral(
                        borrowAmount.toString(),     // ✅ Original borrow amount
                        collateralAmount.toString(), // ✅ Collateral needed from members
                        contributorAddresses, // Array of contributor addresses
                        `Collateral request for loan from circle ${circleAddress.slice(0, 6)}...${circleAddress.slice(-4)} (${contributors.length} contributor${contributors.length > 1 ? 's' : ''})`, // Purpose
                        circleAddress // Target circle address
                      );
                      
                      // Multi-member collateral request transaction initiated
                      // Don't navigate immediately - let user see the transaction progress
                    } catch (error) {
                      console.error('Failed to request collateral:', error);
                      const errorMessage = error instanceof Error ? error.message : 'Failed to create collateral request. Please try again.';
                      alert(errorMessage);
                    }
                  }}
                />
                </Suspense>

                {/* Direct LTV Withdrawal (New) */}
                {hasCircles && userCircles && userCircles.length > 0 && (
                  <Suspense fallback={<div className="animate-pulse h-96 bg-gray-100 rounded-lg" />}>
                    <DirectLTVWithdraw 
                      circleAddress={userCircles[0]}
                    />
                  </Suspense>
                )}
              </div>
                </div>
              </div>
            </div>
          </div>
        );
      case 'circle':
        return <CircleManagement />;
      case 'analytics':
        return (
          <div className="p-6">
            <Card>
              <CardHeader>
                <CardTitle>Analytics</CardTitle>
                <CardDescription>
                  Track your earnings and borrowing history
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  <p>Analytics coming soon...</p>
                  <p className="text-sm">Charts and insights about your activity</p>
                </div>
              </CardContent>
            </Card>
          </div>
        );
      case 'activity':
        return (
          <div className="p-6">
            <Card>
              <CardHeader>
                <CardTitle>Activity Feed</CardTitle>
                <CardDescription>
                  All your transactions and circle activity
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  <p>Activity feed coming soon...</p>
                  <p className="text-sm">Real-time updates on your account</p>
                </div>
              </CardContent>
            </Card>
          </div>
        );
      case 'help':
        return (
          <div className="p-6">
            <Card>
              <CardHeader>
                <CardTitle>Help & Support</CardTitle>
                <CardDescription>
                  Learn how to use HorizonCircle effectively
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  <p>Help documentation coming soon...</p>
                  <p className="text-sm">FAQs and tutorials</p>
                </div>
              </CardContent>
            </Card>
          </div>
        );
      case 'settings':
        return (
          <div className="p-6">
            <Card>
              <CardHeader>
                <CardTitle>Settings</CardTitle>
                <CardDescription>
                  Manage your account preferences
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <h4 className="font-medium">Account Information</h4>
                  <p className="text-sm text-muted-foreground">
                    Email: {user?.email?.address || 'Not provided'}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    Wallet: {user?.wallet?.address || 'Not connected'}
                  </p>
                </div>
                <div className="pt-4">
                  <Button onClick={logout} variant="outline">
                    Disconnect
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        );
      default:
        return (
          <DashboardContent
            user={{
              balance: realBalance,
              availableToBorrow: realBalance * 0.85,
              currentLoan: activeLoanAmount,
              yieldEarned: userData?.yieldEarned || 0
            }}
            onDeposit={handleDeposit}
            onBorrow={handleBorrow}
            onViewCircle={handleViewCircle}
            onCreateCircle={handleCreateCircle}
          />
        );
    }
  };

  return (
    <div className="flex h-screen bg-background">
      <Sidebar 
        activeTab={activeTab} 
        onTabChange={setActiveTab}
        hasCircles={hasCircles}
      />
      <main className="flex-1 overflow-auto">
        {renderContent()}
      </main>
    </div>
  );
}