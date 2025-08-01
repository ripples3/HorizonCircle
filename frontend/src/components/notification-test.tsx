'use client';

import { useAccount } from 'wagmi';
import { usePendingCollateralRequests, useUserCirclesDirect as useUserCircles } from '@/hooks/useBalance';
import { Button } from '@/components/ui/button';

export function NotificationTest() {
  const { address } = useAccount();
  const { data: userCircles, isLoading: circlesLoading } = useUserCircles();
  const { requests, isLoading, error } = usePendingCollateralRequests();
  
  const handleRefresh = () => {
    window.location.reload();
  };
  
  const handleClearLocalStorage = () => {
    // Clear potentially stale localStorage data
    localStorage.removeItem('contributed-requests');
    localStorage.removeItem('declined-requests');
    console.log('✅ Cleared localStorage contribution/decline data');
    alert('Cleared localStorage data. Refreshing...');
    window.location.reload();
  };
  
  return (
    <div className="p-4 bg-gray-100 rounded-lg space-y-2">
      <h3 className="font-bold">Notification Debug Panel</h3>
      <div className="text-sm space-y-1">
        <p>Current Address: {address || 'Not connected'}</p>
        <p>User Circles: {userCircles?.length || 0} circles</p>
        <p>User Circles Loading: {circlesLoading ? 'Yes' : 'No'}</p>
        {userCircles && userCircles.length > 0 && (
          <ul className="pl-4">
            {userCircles.map((circle, i) => (
              <li key={i}>{circle}</li>
            ))}
          </ul>
        )}
        <p>Pending Requests: {requests?.length || 0}</p>
        <p>Loading: {isLoading ? 'Yes' : 'No'}</p>
        <p>Error: {error ? error.message : 'None'}</p>
        
        {requests && requests.length > 0 && (
          <div className="mt-2">
            <p className="font-semibold">Requests:</p>
            {requests.map((req, i) => (
              <div key={i} className="text-xs bg-white p-2 rounded mt-1">
                <p>ID: {req.requestId?.slice(0, 10)}...</p>
                <p>Amount: {req.amount} ETH</p>
                <p>Purpose: {req.purpose}</p>
              </div>
            ))}
          </div>
        )}
      </div>
      
      <div className="flex gap-2">
        <Button onClick={handleRefresh} size="sm">
          Refresh Page
        </Button>
        <Button onClick={handleClearLocalStorage} size="sm" variant="outline">
          Clear localStorage
        </Button>
      </div>
    </div>
  );
}