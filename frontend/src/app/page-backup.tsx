'use client';

import { usePrivy } from '@privy-io/react-auth';
import { useEffect } from 'react';
import ConnectButton from "@/components/auth/connect-button";
import DashboardLayout from "@/components/dashboard/dashboard-layout";
import { db } from '@/config/supabase';

export default function Home() {
  const { ready, authenticated, user } = usePrivy();
  
  // Debug logging
  console.log('🔍 Home Page State:', { ready, authenticated, user: user ? 'present' : 'null' });

  // Create user record when authenticated
  useEffect(() => {
    if (authenticated && user) {
      const createUserRecord = async () => {
        try {
          const walletAddress = user.wallet?.address || `privy-${user.id}`;
          console.log('👤 Creating user record for:', walletAddress);
          
          const { data, error } = await db
            .from('users')
            .upsert({
              privy_user_id: user.id,
              wallet_address: walletAddress,
              email: user.email?.address || null,
              name: user.wallet?.address?.slice(0, 8) + '...' || `User ${user.id.slice(-4)}`,
              created_at: new Date().toISOString()
            }, {
              onConflict: 'privy_user_id'
            });

          if (error) {
            console.error('❌ Error creating user record:', error);
          } else {
            console.log('✅ User record created/updated:', data);
          }
        } catch (err) {
          console.error('❌ Exception creating user record:', err);
        }
      };

      createUserRecord();
    }
  }, [authenticated, user]);

  if (!ready) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!authenticated) {
    return <ConnectButton />;
  }

  return <DashboardLayout />;
}