'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Users, Plus, Copy, Share2, Settings, UserPlus, Eye, EyeOff } from 'lucide-react';
import { useState } from 'react';
import { useUserCircles, useCircleName, useCircleMembers } from '@/hooks/useBalance';
import { useAccount, useReadContract } from 'wagmi';
import { useAddMember } from '@/hooks/useTransactions';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';
import CreateCircle from '@/components/circle/create-circle';

export default function CircleManagement() {
  const [showAddMember, setShowAddMember] = useState(false);
  const [memberAddress, setMemberAddress] = useState('');
  const [selectedCircleIndex, setSelectedCircleIndex] = useState(0);
  const [showMembersList, setShowMembersList] = useState(false);
  const [notification, setNotification] = useState<{message: string, type: 'success' | 'info'} | null>(null);
  const { address } = useAccount();
  
  const { data: userCircles, isLoading: circlesLoading } = useUserCircles();
  const hasCircles = userCircles && Array.isArray(userCircles) && userCircles.length > 0;
  
  // Get data for the selected circle
  const selectedCircle = hasCircles ? userCircles[selectedCircleIndex] : null;
  const { data: circleName } = useCircleName(selectedCircle || undefined);
  const { data: circleMembers } = useCircleMembers(selectedCircle || undefined);
  
  // Check if current user is the creator
  const { data: circleCreator } = useReadContract({
    address: selectedCircle as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'creator',
    query: {
      enabled: !!selectedCircle,
    },
  });
  
  const isCreator = circleCreator && address && circleCreator.toLowerCase() === address.toLowerCase();
  
  // Hook for adding members
  const { addMember, isPending: isAddingMember, isConfirmed: memberAdded } = useAddMember(selectedCircle || '');

  console.log('Circle Management Debug:', {
    userCircles,
    hasCircles,
    selectedCircleIndex,
    selectedCircle,
    circleName,
    circleMembers,
    memberCount: circleMembers?.length,
    totalCircles: userCircles?.length
  });

  const showNotification = (message: string, type: 'success' | 'info' = 'success') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  };

  const handleCopyAddress = (address: string) => {
    navigator.clipboard.writeText(address);
    showNotification('Address copied to clipboard!', 'success');
  };

  const handleAddMember = async () => {
    if (!isValidAddress(memberAddress)) {
      showNotification('Please enter a valid Ethereum address', 'info');
      return;
    }
    
    try {
      await addMember(memberAddress);
      showNotification(`Adding member ${memberAddress.slice(0, 10)}...${memberAddress.slice(-4)} to circle`, 'success');
      setMemberAddress('');
      setShowAddMember(false);
    } catch (error) {
      console.error('Failed to add member:', error);
      showNotification('Failed to add member. Please try again.', 'info');
    }
  };

  const isValidAddress = (address: string) => {
    return /^0x[a-fA-F0-9]{40}$/.test(address);
  };

  if (circlesLoading) {
    return (
      <div className="p-6">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      </div>
    );
  }

  if (!hasCircles) {
    return (
      <div className="p-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="w-5 h-5" />
              No Circles Yet
            </CardTitle>
            <CardDescription>
              Create your first savings circle to start building your financial community
            </CardDescription>
          </CardHeader>
          <CardContent>
            <CreateCircle onSuccess={() => window.location.reload()} />
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Notification */}
      {notification && (
        <div className={`p-3 rounded-lg border ${
          notification.type === 'success' 
            ? 'bg-green-50 border-green-200 text-green-700' 
            : 'bg-blue-50 border-blue-200 text-blue-700'
        }`}>
          {notification.message}
        </div>
      )}

      {/* Circle Selector */}
      {hasCircles && (
        <Card>
          <CardHeader>
            <CardTitle>Choose Your Circle</CardTitle>
            <CardDescription>
              {userCircles.length === 1 
                ? "You have 1 circle. This is your active circle:" 
                : `You have ${userCircles.length} circles. Select one to manage:`
              }
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 gap-2">
              {userCircles.map((circle, index) => (
                <div key={circle} className="flex items-center space-x-2">
                  <Button
                    variant={selectedCircleIndex === index ? "default" : "outline"}
                    onClick={() => setSelectedCircleIndex(index)}
                    className="flex-1 justify-start text-left"
                  >
                    <Users className="w-4 h-4 mr-2" />
                    <span className="font-medium">Circle {index + 1}</span>
                    <span className="ml-2 text-sm opacity-70">
                      {circle.slice(0, 6)}...{circle.slice(-4)}
                    </span>
                  </Button>
                  {selectedCircleIndex === index && (
                    <Badge variant="default">Active</Badge>
                  )}
                </div>
              ))}
            </div>
            {userCircles.length > 1 && (
              <div className="mt-4 p-3 bg-blue-50 rounded-lg">
                <p className="text-sm text-blue-700">
                  <strong>Tip:</strong> You can switch between circles to manage different savings groups.
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Circle Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="w-5 h-5" />
            {circleName || 'Your Circle'}
            <Badge variant="secondary">Active</Badge>
          </CardTitle>
          <CardDescription>
            Manage your savings circle and invite family & friends
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Circle Address */}
          <div className="space-y-2">
            <Label className="text-sm font-medium">Circle Address</Label>
            <div className="flex items-center gap-2">
              <Input 
                value={selectedCircle || 'Loading...'} 
                readOnly 
                className="font-mono text-sm"
              />
              <Button 
                variant="outline" 
                size="sm" 
                onClick={() => selectedCircle && handleCopyAddress(selectedCircle)}
                disabled={!selectedCircle}
              >
                <Copy className="w-4 h-4" />
              </Button>
            </div>
            <p className="text-xs text-muted-foreground">
              Share this address for others to join your circle
            </p>
          </div>

          {/* Members Section */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <span className="text-sm font-medium">Members</span>
                <p className="text-xs text-muted-foreground">
                  {circleMembers?.length || 1} active members
                </p>
              </div>
              <div className="flex items-center gap-2">
                <Badge variant="outline">
                  {circleMembers?.length || 1} / 50
                </Badge>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setShowMembersList(!showMembersList)}
                  className="p-2"
                >
                  {showMembersList ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </Button>
              </div>
            </div>
            
            {/* Members List */}
            {showMembersList && circleMembers && circleMembers.length > 0 && (
              <div className="space-y-2 p-3 bg-gray-50 rounded-lg border">
                <h4 className="text-sm font-medium text-gray-700 mb-2">Circle Members:</h4>
                <div className="space-y-2">
                  {circleMembers.map((member: string, index: number) => (
                    <div key={member} className="flex items-center justify-between p-2 bg-white rounded border">
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center">
                          <span className="text-xs font-medium text-blue-600">{index + 1}</span>
                        </div>
                        <code className="text-xs font-mono text-gray-600">
                          {member.slice(0, 6)}...{member.slice(-4)}
                        </code>
                        {member.toLowerCase() === address?.toLowerCase() && (
                          <Badge variant="secondary" className="text-xs px-1 py-0">You</Badge>
                        )}
                      </div>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleCopyAddress(member)}
                        className="p-1 h-auto"
                      >
                        <Copy className="w-3 h-3" />
                      </Button>
                    </div>
                  ))}
                </div>
                <p className="text-xs text-gray-500 mt-2">
                  Click the copy icon to copy full addresses
                </p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Add Member Section */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <UserPlus className="w-5 h-5" />
            Add Circle Members
          </CardTitle>
          <CardDescription>
            Any circle member can add new members by wallet address
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {!showAddMember ? (
            <div className="space-y-4">
              <Button 
                variant="outline" 
                className="gap-2 w-full"
                onClick={() => setShowAddMember(true)}
                disabled={!selectedCircle}
              >
                <UserPlus className="w-4 h-4" />
                Add Member by Address
              </Button>
              <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg">
                <p className="text-sm text-amber-700">
                  <strong>How it works:</strong> As a circle member, you can add trusted friends and family 
                  by entering their wallet address. They&apos;ll need to have a crypto wallet to participate.
                </p>
              </div>
              <div className="p-4 bg-blue-50 rounded-lg">
                <p className="text-sm text-blue-700">
                  <strong>Pro tip:</strong> Start with family members and close friends who you trust. 
                  They&apos;re more likely to help when you need collateral for larger purchases.
                </p>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="memberAddress">Wallet Address</Label>
                <Input
                  id="memberAddress"
                  type="text"
                  placeholder="0x742d35Cc6634C0532925a3b8D3Ac19b"
                  value={memberAddress}
                  onChange={(e) => setMemberAddress(e.target.value)}
                  className="font-mono"
                />
                <p className="text-xs text-muted-foreground">
                  Enter the complete wallet address (42 characters starting with 0x)
                </p>
              </div>
              <div className="flex gap-2">
                <Button 
                  onClick={handleAddMember}
                  disabled={!memberAddress || !isValidAddress(memberAddress)}
                  className="gap-2"
                >
                  <UserPlus className="w-4 h-4" />
                  Add Member
                </Button>
                <Button 
                  variant="outline" 
                  onClick={() => {
                    setShowAddMember(false);
                    setMemberAddress('');
                  }}
                >
                  Cancel
                </Button>
              </div>
              {memberAddress && !isValidAddress(memberAddress) && (
                <p className="text-xs text-red-600">
                  Please enter a valid Ethereum wallet address
                </p>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Create Another Circle */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Plus className="w-5 h-5" />
            Create Another Circle
          </CardTitle>
          <CardDescription>
            Start a new savings circle for different groups
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
              <p className="text-sm text-green-700">
                <strong>Multi-Circle Benefits:</strong> Create separate circles for family, friends, 
                work colleagues, or different savings goals. Each circle operates independently.
              </p>
            </div>
            <CreateCircle onSuccess={() => window.location.reload()} />
          </div>
        </CardContent>
      </Card>

      {/* Circle Settings */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="w-5 h-5" />
            Circle Settings
          </CardTitle>
          <CardDescription>
            Configure your circle preferences
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <Button variant="outline" className="w-full justify-start gap-2">
              <Settings className="w-4 h-4" />
              Manage Circle Settings
            </Button>
            <div className="text-xs text-muted-foreground">
              More management features coming soon...
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}