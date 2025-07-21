'use client';

import { usePrivy } from '@privy-io/react-auth';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { APP_NAME } from '@/constants';

interface ConnectButtonProps {
  className?: string;
}

export default function ConnectButton({ className }: ConnectButtonProps) {
  const { ready, authenticated, user, login, logout } = usePrivy();

  if (!ready) {
    return (
      <Card className={className}>
        <CardContent className="pt-6">
          <div className="flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (authenticated) {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle>Welcome to {APP_NAME}</CardTitle>
          <CardDescription>
            Connected as {user?.email?.address || user?.wallet?.address}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={logout} variant="outline" className="w-full">
            Disconnect
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className={className}>
      <CardHeader className="text-center">
        <CardTitle className="text-2xl">{APP_NAME}</CardTitle>
        <CardDescription>
          DeFi-powered cooperative lending platform
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <Button onClick={login} className="w-full" size="lg">
          Get Started
        </Button>
        <p className="text-sm text-muted-foreground text-center">
          Connect with email or wallet to start saving and borrowing
        </p>
      </CardContent>
    </Card>
  );
}