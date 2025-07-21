'use client';

import { useState } from 'react';
import { usePrivy } from '@privy-io/react-auth';
import Sidebar from './sidebar';
import DashboardContent from './dashboard-content';
import DepositForm from '@/components/lending/deposit-form';
import BorrowForm from '@/components/lending/borrow-form';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import DatabaseTest from '@/components/debug/database-test';
import { useUserData } from '@/hooks/useUserData';

export default function DashboardLayout() {
  const { user, logout } = usePrivy();
  const { userData, loading, error, updateUserData } = useUserData();
  const [activeTab, setActiveTab] = useState('dashboard');

  const handleDeposit = () => {
    setActiveTab('deposit');
  };

  const handleBorrow = () => {
    setActiveTab('borrow');
  };

  const handleViewCircle = () => {
    setActiveTab('circle');
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        if (loading) {
          return (
            <div className="flex items-center justify-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            </div>
          );
        }

        if (error) {
          return (
            <div className="flex items-center justify-center h-64">
              <div className="text-red-600">Error: {error}</div>
            </div>
          );
        }

        return (
          <div>
            <DatabaseTest />
            <DashboardContent
              user={{
                balance: userData?.balance || 0,
                availableToBorrow: userData?.available_to_borrow || 0,
                currentLoan: userData?.current_loan || 0,
                yieldEarned: userData?.yield_earned || 0
              }}
              onDeposit={handleDeposit}
              onBorrow={handleBorrow}
              onViewCircle={handleViewCircle}
            />
          </div>
        );
      case 'deposit':
        return (
          <div className="p-6 flex justify-center">
            <DepositForm
              onSuccess={(amount) => {
                console.log('Deposit successful:', amount);
                setActiveTab('dashboard');
              }}
              onCancel={() => setActiveTab('dashboard')}
            />
          </div>
        );
      case 'borrow':
        return (
          <div className="p-6 flex justify-center">
            <BorrowForm
              userBalance={userData?.balance || 0}
              onSuccess={(amount) => {
                console.log('Borrow successful:', amount);
                setActiveTab('dashboard');
              }}
              onCancel={() => setActiveTab('dashboard')}
              onRequestHelp={(amount) => {
                console.log('Help requested for:', amount);
                setActiveTab('circle');
              }}
            />
          </div>
        );
      case 'circle':
        return (
          <div className="p-6">
            <Card>
              <CardHeader>
                <CardTitle>Your Lending Circle</CardTitle>
                <CardDescription>
                  Join or create a circle to access social lending features
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8 text-muted-foreground">
                  <p>Circle management coming soon...</p>
                  <p className="text-sm">Invite friends and family to join</p>
                </div>
              </CardContent>
            </Card>
          </div>
        );
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
            onDeposit={handleDeposit}
            onBorrow={handleBorrow}
            onViewCircle={handleViewCircle}
          />
        );
    }
  };

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar 
        activeTab={activeTab} 
        onTabChange={setActiveTab} 
      />
      <main className="flex-1 overflow-auto">
        {renderContent()}
      </main>
    </div>
  );
}