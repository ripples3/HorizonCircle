'use client';

import { useState, useEffect } from 'react';
import { usePrivy } from '@privy-io/react-auth';
import { db } from '@/config/supabase';
import { User } from '@/types';

export function useUserData() {
  const { user: privyUser, authenticated } = usePrivy();
  const [userData, setUserData] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!authenticated || !privyUser) {
      setLoading(false);
      return;
    }

    const fetchUserData = async () => {
      try {
        setLoading(true);
        setError(null);

        // Get wallet address from external wallet or embedded wallet
        const walletAddress = privyUser.linkedAccounts?.find(account => 
          account.type === 'wallet'
        )?.address || privyUser.wallet?.address || `privy-${privyUser.id}`;
        
        console.log('Fetching user data for address:', walletAddress);
        console.log('Privy user:', privyUser);
        
        // Try to get existing user
        let user = await db.getUser(walletAddress);
        console.log('Existing user from DB:', user);
        
        // If user doesn't exist, create one
        if (!user) {
          console.log('Creating new user in DB...');
          user = await db.upsertUser({
            wallet_address: walletAddress,
            email: privyUser.email?.address,
            balance: 0,
            available_to_borrow: 0,
            current_loan: 0,
            yield_earned: 0,
          });
          console.log('Created user:', user);
        }

        setUserData(user);
      } catch (err) {
        console.error('Error fetching user data:', err);
        setError('Failed to load user data');
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, [authenticated, privyUser]);

  const updateUserData = async (updates: Partial<User>) => {
    if (!userData) return;

    try {
      // Convert from camelCase User type to snake_case database format
      const updatedUser = await db.upsertUser({
        wallet_address: userData.walletAddress,
        email: userData.email,
        balance: updates.balance ?? userData.balance,
        available_to_borrow: updates.availableToBorrow ?? userData.availableToBorrow,
        current_loan: updates.currentLoan ?? userData.currentLoan,
        yield_earned: updates.yieldEarned ?? userData.yieldEarned,
        circle_id: updates.circleId ?? userData.circleId,
      });
      setUserData(updatedUser);
      return updatedUser;
    } catch (err) {
      console.error('Error updating user data:', err);
      setError('Failed to update user data');
      throw err;
    }
  };

  return {
    userData,
    loading,
    error,
    updateUserData,
    refetch: () => {
      if (authenticated && privyUser) {
        const walletAddress = privyUser.wallet?.address || `privy-${privyUser.id}`;
        db.getUser(walletAddress).then(setUserData);
      }
    }
  };
}