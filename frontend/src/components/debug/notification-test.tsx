'use client';

import React from 'react';
import { useAccount } from 'wagmi';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { usePendingCollateralRequests, useUserCirclesDirect } from '@/hooks/useBalance';

export default function NotificationTest() {
  const { address } = useAccount();
  const { data: pendingRequests, isLoading, error } = usePendingCollateralRequests();
  const { data: userCircles, isLoading: circlesLoading } = useUserCirclesDirect();

  if (!address) {
    return (
      <Card className="border-yellow-200 bg-yellow-50">
        <CardHeader>
          <CardTitle className="text-sm text-yellow-800">Notification Debug</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-xs text-yellow-700">No wallet connected</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-yellow-200 bg-yellow-50">
      <CardHeader>
        <CardTitle className="text-sm text-yellow-800">Notification Debug</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-2 text-xs text-yellow-700">
          <div><strong>Current Address:</strong> {address}</div>
          <div><strong>User Circles:</strong> {userCircles?.length || 0} circles</div>
          {userCircles && userCircles.length > 0 && (
            <div>
              {userCircles.map((circle) => (
                <div key={circle}>{circle}</div>
              ))}
            </div>
          )}
          <div><strong>Pending Requests:</strong> {pendingRequests?.length || 0}</div>
          <div><strong>Loading:</strong> {isLoading ? 'Yes' : 'No'}</div>
          <div><strong>Error:</strong> {error?.message || 'None'}</div>
          
          {pendingRequests && pendingRequests.length > 0 && (
            <div>
              <strong>Request Details:</strong>
              <pre className="mt-1 text-xs overflow-auto">
                {JSON.stringify(pendingRequests, null, 2)}
              </pre>
            </div>
          )}
          
          <div className="mt-2 p-2 bg-blue-100 rounded">
            <strong>🆕 FRESH START:</strong>
            <br />Now using new factory with Morpho fixes: 0xdfEf...2959
            <br />Create a new circle to test the fixed contribution system!
          </div>

          <div className="mt-2">
            <Button
              onClick={() => {
                // Clear all cached data
                localStorage.clear();
                sessionStorage.clear();
                
                // Reload page for fresh start
                window.location.reload();
              }}
              size="sm"
              className="text-xs bg-red-600 hover:bg-red-700 text-white"
            >
              🗑️ Clear All Data & Refresh
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}