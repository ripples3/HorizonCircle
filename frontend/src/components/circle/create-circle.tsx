'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Users, Plus, CheckCircle } from 'lucide-react';
import { useCreateCircle } from '@/hooks/useTransactions';
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
import { CONTRACT_ADDRESSES, CONTRACT_ABIS } from '@/config/web3';
import { clearCircleCache } from '@/utils/circleCache';

interface CreateCircleProps {
  onSuccess?: (circleName: string) => void;
  onCancel?: () => void;
}

export default function CreateCircle({ onSuccess, onCancel }: CreateCircleProps) {
  const [circleName, setCircleName] = useState('');
  const [step, setStep] = useState<'input' | 'processing' | 'success' | 'manual-register'>('input');
  const [isLoading, setIsLoading] = useState(false);
  const [deployedCircleAddress, setDeployedCircleAddress] = useState<string>('');

  // Web3 transaction hooks
  const { address } = useAccount();
  const { createCircle, isPending, isConfirming, isConfirmed, error, deploymentStep } = useCreateCircle();
  const { writeContract: registerCircle, data: registerHash, isPending: isRegistering } = useWriteContract();
  const { isSuccess: isRegisterConfirmed } = useWaitForTransactionReceipt({ hash: registerHash });

  const isValidName = circleName.trim().length >= 3 && circleName.trim().length <= 50;

  // Watch for transaction confirmation
  useEffect(() => {
    if (isConfirmed && step === 'processing') {
      setStep('success');
      setIsLoading(false);
      
      // Clear cache to ensure new circle appears immediately
      clearCircleCache().then(() => {
        console.log('✅ Circle cache cleared after successful creation');
      }).catch((error) => {
        console.warn('⚠️ Failed to clear circle cache:', error);
      });
      
      setTimeout(() => {
        onSuccess?.(circleName);
      }, 1500);
    }
  }, [isConfirmed, step, circleName, onSuccess]);

  // Watch for transaction errors
  useEffect(() => {
    if (error && step === 'processing') {
      console.error('Circle creation error:', error);
      setStep('input');
      setIsLoading(false);
    }
  }, [error, step]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log('🔥 BUTTON CLICKED - handleSubmit called');
    console.log('🔥 Circle name:', circleName);
    console.log('🔥 Is valid name:', isValidName);
    
    if (!isValidName) {
      console.log('🔥 Invalid name, returning early');
      return;
    }

    console.log('🔥 Setting step to processing');
    setStep('processing');
    setIsLoading(true);

    try {
      console.log('🔥 About to call createCircle with:', circleName.trim());
      
      // Industry standard: Direct deployment + auto-registry integration
      // Include creator as a member (required by factory initialization)
      const initialMembers = address ? [address as `0x${string}`] : [];
      await createCircle(circleName.trim(), initialMembers);
      
      console.log('🔥 Circle deployment initiated, waiting for confirmation...');
      // The useEffect will handle success/error cases
    } catch (error) {
      console.error('🔥 Circle creation failed:', error);
      
      // Show user-friendly error message
      const errorMessage = (error as Error).message;
      if (errorMessage.includes('status code 400')) {
        alert('❌ Transaction failed during signing. This might be a network issue.\n\n✅ Try refreshing the page and trying again.\n\n💡 Make sure your wallet is connected to Lisk network.');
      } else if (errorMessage.includes('User rejected')) {
        alert('Transaction was cancelled.');
      } else {
        alert('Circle creation failed: ' + errorMessage);
      }
      
      setStep('input');
      setIsLoading(false);
    }
  };

  if (step === 'processing') {
    return (
      <Card className="w-full max-w-md mx-auto">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="w-5 h-5 text-blue-600" />
            Creating Your Circle
          </CardTitle>
          <CardDescription>Setting up your lending circle...</CardDescription>
        </CardHeader>
        <CardContent className="text-center space-y-6">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <div className="space-y-2">
            <h3 className="text-lg font-semibold">
              {deploymentStep === 'creating' && isPending ? 'Waiting for Factory Signature' :
               deploymentStep === 'creating' && isConfirming ? 'Creating Circle via Factory' :
               'Processing Transaction'}
            </h3>
            <p className="text-muted-foreground">
              {deploymentStep === 'creating' && isPending ? 'Please sign the circle creation transaction in your wallet' :
               deploymentStep === 'creating' && isConfirming ? 'Circle is being created and deployed to blockchain...' :
               `Creating "${circleName}" using factory pattern...`}
            </p>
          </div>
          <div className="p-4 bg-blue-50 rounded-lg">
            <p className="text-sm text-blue-700">
              {isPending ? 'Check your wallet for the signature request.' :
               'This usually takes 30-60 seconds. Please don\'t close this window.'}
            </p>
          </div>
          {error && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-700">
                <strong>Error:</strong> {error.message || 'Transaction failed'}
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    );
  }

  if (step === 'success') {
    return (
      <Card className="w-full max-w-md mx-auto">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CheckCircle className="w-5 h-5 text-green-600" />
            Circle Created Successfully!
          </CardTitle>
          <CardDescription>Your lending circle is ready to use</CardDescription>
        </CardHeader>
        <CardContent className="text-center space-y-6">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
            <CheckCircle className="w-8 h-8 text-green-600" />
          </div>
          <div className="space-y-2">
            <h3 className="text-lg font-semibold text-green-600">Circle Created!</h3>
            <p className="text-muted-foreground">
              &quot;{circleName}&quot; has been created successfully. You can now start depositing funds and inviting members.
            </p>
          </div>
          <div className="space-y-3 p-4 bg-green-50 rounded-lg">
            <div className="flex items-center gap-2 text-green-700">
              <Users className="w-4 h-4" />
              <span className="text-sm font-medium">You are the circle starter</span>
            </div>
            <div className="flex items-center gap-2 text-green-700">
              <Plus className="w-4 h-4" />
              <span className="text-sm font-medium">Ready for deposits and members</span>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Users className="w-5 h-5 text-blue-600" />
          Create Circle
        </CardTitle>
        <CardDescription>
          Start your own cooperative savings circle with friends and family
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="circleName">Circle Name</Label>
            <div className="relative">
              <Users className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="circleName"
                type="text"
                placeholder="My Family Circle"
                value={circleName}
                onChange={(e) => setCircleName(e.target.value)}
                className="pl-10"
                disabled={isLoading}
                maxLength={50}
              />
            </div>
            <p className="text-sm text-muted-foreground">
              Choose a memorable name for your savings circle (3-50 characters)
            </p>
          </div>

          <div className="space-y-3 p-4 bg-blue-50 rounded-lg">
            <div className="flex items-center gap-2 text-blue-700">
              <Users className="w-4 h-4" />
              <span className="text-sm font-medium">You&apos;ll seed the circle</span>
            </div>
            <div className="flex items-center gap-2 text-blue-700">
              <Plus className="w-4 h-4" />
              <span className="text-sm font-medium">Invite members later</span>
            </div>
          </div>

          <div className="flex gap-2">
            <Button
              type="submit"
              disabled={!isValidName || isLoading}
              className="flex-1 gap-2"
            >
              <Plus className="w-4 h-4" />
              Create Circle
            </Button>
            {onCancel && (
              <Button
                type="button"
                variant="outline"
                onClick={onCancel}
                disabled={isLoading}
              >
                Cancel
              </Button>
            )}
          </div>
        </form>
      </CardContent>
    </Card>
  );
}