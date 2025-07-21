'use client';

import { usePrivy } from '@privy-io/react-auth';
import { useEffect } from 'react';
import ConnectButton from "@/components/auth/connect-button";
import DashboardLayout from "@/components/dashboard/dashboard-layout";
import { db } from '@/config/supabase';

export default function Home() {
  const { ready, authenticated, user } = usePrivy();

  // Create user record when authenticated
  useEffect(() => {
    if (authenticated && user) {
      const createUserRecord = async () => {
        try {
          const walletAddress = user.wallet?.address || `privy-${user.id}`;
          await db.upsertUser({
            wallet_address: walletAddress,
            email: user.email?.address,
            balance: 0,
            available_to_borrow: 0,
            current_loan: 0,
            yield_earned: 0,
          });
        } catch (error) {
          console.error('Failed to create user record:', error);
        }
      };

      createUserRecord();
    }
  }, [authenticated, user]);

  if (!ready) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!authenticated) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <div className="max-w-md w-full">
          <ConnectButton />
        </div>
      </div>
    );
  }

  return <DashboardLayout />;
}
