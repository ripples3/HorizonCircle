'use client';

import { usePrivy } from '@privy-io/react-auth';
import { useEffect, lazy, Suspense } from 'react';
import ConnectButton from "@/components/auth/connect-button";

// Lazy load heavy components
const DashboardLayout = lazy(() => import("@/components/dashboard/dashboard-layout"));

// Lazy load database config only when needed
const loadDatabase = () => import('@/config/supabase').then(mod => mod.db);

export default function Home() {
  const { ready, authenticated, user } = usePrivy();
  
  // Debug logging
  console.log('🔍 Home Page State:', { ready, authenticated, user: user ? 'present' : 'null' });

  // Create user record when authenticated (lazy loaded)
  useEffect(() => {
    if (authenticated && user) {
      const createUserRecord = async () => {
        try {
          const walletAddress = user.wallet?.address || `privy-${user.id}`;
          const db = await loadDatabase();
          
          await db.upsertUser({
            wallet_address: walletAddress,
            email: user.email?.address || null,
          });
        } catch (err) {
          console.error('User record creation failed:', err);
        }
      };

      createUserRecord();
    }
  }, [authenticated, user]);

  if (!ready) {
    return (
      <div className="min-h-screen bg-gradient-light flex items-center justify-center">
        <div className="text-center glass-subtle p-8 rounded-cow-lg">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-3"></div>
          <p className="text-foreground text-sm">Initializing...</p>
        </div>
      </div>
    );
  }

  if (!authenticated) {
    return <ConnectButton />;
  }

  return (
    <div>
      <Suspense fallback={<div className="animate-pulse h-screen bg-background" />}>
        <DashboardLayout />
      </Suspense>
    </div>
  );
}