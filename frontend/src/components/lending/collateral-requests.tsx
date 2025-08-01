'use client';

import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Bell, CheckCircle, RefreshCw } from 'lucide-react';
import { useAccount, useWriteContract } from 'wagmi';
import { CURRENCY_SYMBOL } from '@/constants';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';
import { useContributeToRequest, useDeclineRequest } from '@/hooks/useTransactions';
import { usePendingCollateralRequests } from '@/hooks/useBalance';

interface CollateralRequest {
  id: string;
  requestId: string; // Blockchain request ID (bytes32)
  requestor: string;
  requestorName: string;
  amount: number;
  purpose: string;
  circleAddress: string;
  circleName: string;
  deadline: Date;
  isExpired: boolean;
  fulfilled?: boolean;
  hasContributed?: boolean;
  hasDeclined?: boolean;
  contributors?: string[]; // List of requested contributors
}

export default function CollateralRequests() {
  const { address } = useAccount();
  const [processedRequests, setProcessedRequests] = React.useState<Set<string>>(new Set());
  
  // Memoize processed requests loading to prevent re-runs on every render
  const processedRequestsFromStorage = React.useMemo(() => {
    if (!address) return new Set<string>();
    
    const declinedRequests = JSON.parse(localStorage.getItem('declined-requests') || '{}');
    const contributedRequests = JSON.parse(localStorage.getItem('contributed-requests') || '{}');
    
    return new Set([
      ...Object.keys(declinedRequests),
      ...Object.keys(contributedRequests)
    ]);
  }, [address]);

  // Load previously processed requests from localStorage on mount
  React.useEffect(() => {
    setProcessedRequests(processedRequestsFromStorage);
  }, [processedRequestsFromStorage]);
  
  // Use real blockchain event listening to get collateral requests
  const { data: pendingRequests, isLoading: requestsLoading, error: requestsError, refetch } = usePendingCollateralRequests();
  
  // Memoize all requests processing
  const allRequests = React.useMemo(() => {
    // Use real blockchain events with proper contributor filtering
    if (pendingRequests && pendingRequests.length > 0) {
      return pendingRequests as CollateralRequest[];
    }
    // No fallback to mock data - only show real events
    return [];
  }, [pendingRequests]);

  // Memoize first request to prevent unnecessary re-renders
  const firstRequest = React.useMemo(() => allRequests[0], [allRequests]);
  
  // Hook for contributing to requests - we'll use the first request's circle address
  const { 
    hash: contributeHash,
    isPending: isContributing, 
    isConfirming: isConfirmingContribute,
    isConfirmed: isContributeConfirmed,
    error: contributeError 
  } = useContributeToRequest(firstRequest?.circleAddress);
  
  // Direct writeContract hook for flexible circle address handling
  const { writeContract } = useWriteContract();
  
  // Hook for declining requests
  const { 
    declineRequest, 
    hash: declineHash,
    isPending: isDeclining, 
    isConfirming: isConfirmingDecline,
    isConfirmed: isDeclineConfirmed,
    error: declineError 
  } = useDeclineRequest(firstRequest?.circleAddress);

  // Memoize calculation functions to prevent recreations (must be before early returns)
  const getIndividualAllocation = React.useCallback((request: CollateralRequest): number => {
    const contributorCount = request.contributors?.length || 1;
    return request.amount / contributorCount;
  }, []);

  // Get individual contribution amount (fixed - no editing allowed)
  const getContributionAmount = React.useCallback((request: CollateralRequest): number => {
    return getIndividualAllocation(request);
  }, [getIndividualAllocation]);

  // Memoize handlers to prevent re-renders (must be before early returns)
  const handleContribute = React.useCallback(async (request: CollateralRequest) => {
    if (isContributing || isConfirmingContribute) {
      return; // Prevent multiple clicks during transaction
    }

    try {
      const targetAddress = request.circleAddress || CONTRACT_ADDRESSES.LENDING_POOL;
      
      if (!targetAddress) {
        throw new Error('Circle contract address not provided');
      }

      await writeContract({
        address: targetAddress as `0x${string}`,
        abi: CONTRACT_ABIS.LENDING_POOL,
        functionName: 'contributeToRequest',
        args: [request.requestId as `0x${string}`],
      });
      
    } catch (error: any) {
      console.error('❌ CONTRIBUTION ERROR:', error);
      alert(`Failed to contribute: ${error?.message || 'Unknown error'}. Check console for details.`);
    }
  }, [isContributing, isConfirmingContribute, writeContract]);

  const handleDecline = React.useCallback(async (request: CollateralRequest) => {
    if (isDeclining || isConfirmingDecline) {
      return; // Prevent multiple clicks during transaction
    }

    try {
      await declineRequest(request.requestId);
    } catch (error) {
      console.error('Failed to initiate decline transaction:', error);
      alert('Failed to start decline transaction. Please try again.');
    }
  }, [isDeclining, isConfirmingDecline, declineRequest]);

  // Memoize filtered display requests
  const displayRequests = React.useMemo(() => 
    allRequests.filter(request => !processedRequests.has(request.id)),
    [allRequests, processedRequests]
  );

  // Handle successful contribution
  React.useEffect(() => {
    if (isContributeConfirmed && contributeHash && firstRequest) {
      setProcessedRequests(prev => new Set([...prev, firstRequest.id]));
      
      const message = [
        `✅ Successfully contributed ${CURRENCY_SYMBOL}${getContributionAmount(firstRequest).toFixed(8)} to help ${firstRequest.requestorName}!`,
        ``,
        `📊 Your contribution will earn 5% APY`,
        `🔗 Transaction: ${contributeHash.slice(0, 10)}...${contributeHash.slice(-8)}`,
        ``,
        `${firstRequest.requestorName} will be notified of your help.`
      ].join('\\n');
      
      alert(message);
      
      setTimeout(() => {
        refetch();
      }, 3000);
    }
  }, [isContributeConfirmed, contributeHash, firstRequest, refetch, getContributionAmount]);

  // Handle contribution errors
  React.useEffect(() => {
    if (contributeError) {
      console.error('Contribution error:', contributeError);
      alert(`Failed to contribute: ${contributeError.message || 'Please try again.'}`);
    }
  }, [contributeError]);

  // Handle successful decline
  React.useEffect(() => {
    if (isDeclineConfirmed && declineHash && firstRequest) {
      setProcessedRequests(prev => new Set([...prev, firstRequest.id]));
      alert(`Successfully declined request from ${firstRequest.requestorName}. This decline has been recorded on the blockchain.`);
      
      setTimeout(() => {
        refetch();
      }, 3000);
    }
  }, [isDeclineConfirmed, declineHash, firstRequest, refetch]);

  // Handle decline errors
  React.useEffect(() => {
    if (declineError) {
      console.error('Decline error:', declineError);
      alert(`Failed to decline request: ${declineError.message || 'Please try again.'}`);
    }
  }, [declineError]);

  // Early returns after all hooks
  if (!address) {
    return null;
  }

  // Show loading state
  if (requestsLoading) {
    return (
      <Card className="border-dashed glass-subtle">
        <CardContent className="pt-3 pb-3">
          <div className="text-center text-sm text-muted-foreground py-2">
            <Bell className="w-4 h-4 mx-auto mb-1 opacity-30" />
            <p className="text-xs">Loading collateral requests...</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  // Show error state
  if (requestsError) {
    return (
      <Card className="border-dashed border-red-200 glass-subtle">
        <CardContent className="pt-3 pb-3">
          <div className="text-center text-sm text-red-600 py-2">
            <Bell className="w-4 h-4 mx-auto mb-1 opacity-30" />
            <p className="text-xs">Error loading requests: {requestsError.message}</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (displayRequests.length === 0) {
    return (
      <Card className="border-dashed glass-subtle">
        <CardContent className="pt-3 pb-3">
          <div className="text-center text-sm text-muted-foreground py-2">
            <Bell className="w-4 h-4 mx-auto mb-1 opacity-30" />
            <p className="text-xs">No pending collateral requests</p>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => refetch()}
              className="mt-1 text-xs h-6 px-2"
            >
              <RefreshCw className="w-3 h-3 mr-1" />
              Refresh
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-2">
      {displayRequests.map((request) => (
        <Card key={request.id} className="glass-subtle border-soft rounded-cow">
          <CardContent className="p-3">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-3">
                <div className="w-6 h-6 bg-primary/10 rounded-full flex items-center justify-center">
                  <Bell className="w-3 h-3 text-primary" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-primary text-sm">
                      {request.requestorName}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      requests {CURRENCY_SYMBOL}{request.amount.toFixed(8)}
                    </span>
                    <span className="text-xs text-accent bg-accent/10 px-2 py-1 rounded-cow">
                      Your share: {CURRENCY_SYMBOL}{getContributionAmount(request).toFixed(8)}
                    </span>
                    {request.fulfilled ? (
                      <Badge variant="outline" className="text-green-700 border-green-300 text-xs bg-green-50">
                        Fulfilled
                      </Badge>
                    ) : request.hasContributed ? (
                      <Badge variant="outline" className="text-blue-700 border-blue-300 text-xs bg-blue-50">
                        Contributed
                      </Badge>
                    ) : request.hasDeclined ? (
                      <Badge variant="outline" className="text-gray-700 border-gray-300 text-xs bg-gray-50">
                        Declined
                      </Badge>
                    ) : (
                      <Badge variant="outline" className="text-orange-700 border-orange-300 text-xs">
                        6 days left
                      </Badge>
                    )}
                  </div>
                  <div className="text-xs text-orange-600 mt-1">
                    From {request.circleName} • {request.fulfilled ? 'Request already fulfilled by others' : 'Help earn 5% APY'}
                  </div>
                </div>
              </div>
              
              <div className="flex gap-2">
                <Button
                  size="sm"
                  onClick={() => handleContribute(request)}
                  disabled={isContributing || isConfirmingContribute || request.fulfilled || request.hasContributed || request.hasDeclined}
                  className="bg-orange-600 hover:bg-orange-700 text-white text-xs px-3 disabled:opacity-50"
                >
                  {(isContributing || isConfirmingContribute) ? (
                    <>
                      <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-white mr-1"></div>
                      {isContributing ? 'Confirming...' : 'Processing...'}
                    </>
                  ) : (
                    <>
                      <CheckCircle className="w-3 h-3 mr-1" />
                      Contribute
                    </>
                  )}
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => handleDecline(request)}
                  disabled={isContributing || isConfirmingContribute || isDeclining || isConfirmingDecline || request.fulfilled || request.hasContributed || request.hasDeclined}
                  className="text-orange-600 hover:bg-orange-100 text-xs px-2 disabled:opacity-50"
                >
                  {(isDeclining || isConfirmingDecline) ? (
                    <>
                      <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-orange-600 mr-1"></div>
                      {isDeclining ? 'Confirming...' : 'Processing...'}
                    </>
                  ) : (
                    'Decline'
                  )}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}