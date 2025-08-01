'use client';

import React from 'react';
import { clearCircleCache, getCircleCacheStats } from '@/utils/circleCache';

export default function CacheDebugPanel() {
  const [stats, setStats] = React.useState<{ userCircleCount: number; metadataCount: number } | null>(null);
  const [isClearing, setIsClearing] = React.useState(false);

  const refreshStats = async () => {
    try {
      const cacheStats = await getCircleCacheStats();
      setStats(cacheStats);
    } catch (error) {
      console.error('Failed to get cache stats:', error);
    }
  };

  const handleClearCache = async () => {
    if (!confirm('Clear all IndexedDB cache? This will force re-discovery of all circles.')) {
      return;
    }
    
    setIsClearing(true);
    try {
      await clearCircleCache();
      await refreshStats();
      alert('Cache cleared successfully! Refresh the page to see re-discovery.');
    } catch (error) {
      console.error('Failed to clear cache:', error);
      alert('Failed to clear cache. Check console for details.');
    } finally {
      setIsClearing(false);
    }
  };

  React.useEffect(() => {
    refreshStats();
    // Refresh stats every 10 seconds
    const interval = setInterval(refreshStats, 10000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="fixed bottom-4 right-4 bg-white border border-gray-300 rounded-lg p-4 shadow-lg max-w-sm z-50">
      <h3 className="font-bold text-sm mb-2">🗄️ IndexedDB Cache Debug</h3>
      
      {stats ? (
        <div className="text-sm space-y-2">
          <div>
            <strong>User Circle Records:</strong> {stats.userCircleCount}
          </div>
          <div>
            <strong>Circle Metadata:</strong> {stats.metadataCount}
          </div>
          
          <div className="flex gap-2 mt-3">
            <button
              onClick={refreshStats}
              className="px-2 py-1 bg-blue-500 text-white text-xs rounded hover:bg-blue-600"
            >
              Refresh
            </button>
            <button
              onClick={handleClearCache}
              disabled={isClearing}
              className="px-2 py-1 bg-red-500 text-white text-xs rounded hover:bg-red-600 disabled:opacity-50"
            >
              {isClearing ? 'Clearing...' : 'Clear Cache'}
            </button>
          </div>
        </div>
      ) : (
        <div className="text-sm text-gray-500">Loading cache stats...</div>
      )}
      
      <div className="mt-3 text-xs text-gray-400">
        Cache persists across browser restarts. 
        Clear if you need to force re-discovery.
      </div>
    </div>
  );
}