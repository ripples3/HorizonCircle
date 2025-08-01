'use client';

import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Bell, RefreshCw } from 'lucide-react';
import { usePendingCollateralRequests } from '@/hooks/useBalance';

interface CollateralNotificationProps {
  onNavigateToBorrow: () => void;
}

export default function CollateralNotification({ onNavigateToBorrow }: CollateralNotificationProps) {
  const { data: requests, isLoading, error, refetch } = usePendingCollateralRequests();
  
  // Show loading state
  if (isLoading) {
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
  if (error) {
    return (
      <Card className="border-dashed border-red-200 glass-subtle">
        <CardContent className="pt-3 pb-3">
          <div className="text-center text-sm text-red-600 py-2">
            <Bell className="w-4 h-4 mx-auto mb-1 opacity-30" />
            <p className="text-xs">Error loading requests: {error.message}</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  // Show no requests state with refresh button (what should be on dashboard)
  if (!requests || requests.length === 0) {
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

  // If there ARE requests, don't show anything on dashboard (they'll see it in borrow menu)
  return null;
}