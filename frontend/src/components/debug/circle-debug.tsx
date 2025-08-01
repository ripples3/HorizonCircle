'use client';

import { useState } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { CONTRACT_ABIS } from '@/config/web3';

export default function CircleDebug() {
  const [circleAddress, setCircleAddress] = useState('');
  const { address: userAddress } = useAccount();
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isSuccess } = useWaitForTransactionReceipt({ hash });

  // Check if user is member
  const { data: isMember, refetch: refetchMember } = useReadContract({
    address: circleAddress as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'isCircleMember',
    args: [userAddress],
    query: { enabled: !!circleAddress && !!userAddress }
  });

  // Check who is creator
  const { data: creator } = useReadContract({
    address: circleAddress as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'creator',
    query: { enabled: !!circleAddress }
  });

  // Get all members
  const { data: members } = useReadContract({
    address: circleAddress as `0x${string}`,
    abi: CONTRACT_ABIS.LENDING_POOL,
    functionName: 'getMembers',
    query: { enabled: !!circleAddress }
  });

  const addSelfAsMember = async () => {
    if (!circleAddress || !userAddress) return;

    console.log('🔧 Adding self as member:', { circleAddress, userAddress });
    writeContract({
      address: circleAddress as `0x${string}`,
      abi: CONTRACT_ABIS.LENDING_POOL,
      functionName: 'addMember',
      args: [userAddress],
    });
  };

  // Refetch data when transaction succeeds
  if (isSuccess) {
    refetchMember();
  }

  return (
    <Card className="w-full max-w-2xl mx-auto mt-4">
      <CardHeader>
        <CardTitle>🔧 Circle Debug Tool</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-2">Circle Address:</label>
          <Input
            value={circleAddress}
            onChange={(e) => setCircleAddress(e.target.value)}
            placeholder="0x..."
            className="font-mono"
          />
        </div>

        {circleAddress && (
          <div className="space-y-2 text-sm">
            <div><strong>Your Address:</strong> {userAddress}</div>
            <div><strong>Circle Creator:</strong> {creator as string}</div>
            <div><strong>You are creator:</strong> {creator === userAddress ? '✅ YES' : '❌ NO'}</div>
            <div><strong>You are member:</strong> {isMember ? '✅ YES' : '❌ NO'}</div>
            <div><strong>All Members:</strong> {members ? (members as string[]).length : 0}</div>
            {members && (
              <div className="ml-4 font-mono text-xs">
                {(members as string[]).map((member, i) => (
                  <div key={i}>{member}</div>
                ))}
              </div>
            )}
          </div>
        )}

        {circleAddress && !isMember && creator === userAddress && (
          <div className="p-4 bg-yellow-50 border border-yellow-200 rounded">
            <p className="text-yellow-800 mb-2">
              ⚠️ You're the creator but not a member! This is a deployment bug.
            </p>
            <Button 
              onClick={addSelfAsMember} 
              disabled={isPending}
              className="bg-yellow-600 hover:bg-yellow-700"
            >
              {isPending ? 'Adding...' : '🔧 Add Myself as Member'}
            </Button>
          </div>
        )}

        {isSuccess && (
          <div className="p-4 bg-green-50 border border-green-200 rounded">
            <p className="text-green-800">✅ Successfully added as member!</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}