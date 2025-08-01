'use client';

import { usePrivy } from '@privy-io/react-auth';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Logo } from '@/components/ui/logo';
import { APP_NAME } from '@/constants';

interface ConnectButtonProps {
  className?: string;
}

export default function ConnectButton({ className }: ConnectButtonProps) {
  const { ready, authenticated, user, login, logout } = usePrivy();

  if (!ready) {
    return (
      <div className="min-h-screen bg-gradient-light flex items-center justify-center p-4">
        <Card className={`${className} max-w-sm glass-subtle rounded-cow-lg`}>
          <CardContent className="pt-6">
            <div className="flex items-center justify-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (authenticated) {
    return (
      <div className="min-h-screen bg-gradient-light flex items-center justify-center p-4">
        <Card className={`${className} max-w-sm glass-subtle rounded-cow-lg`}>
          <CardHeader>
            <CardTitle>Welcome to {APP_NAME}</CardTitle>
            <CardDescription>
              Connected as {user?.email?.address || user?.wallet?.address}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={logout} variant="outline" className="w-full rounded-cow">
              Disconnect
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-light flex items-center justify-center p-4">
      <Card className={`${className} max-w-sm w-full glass-subtle border-soft rounded-cow-lg`}>
        <CardHeader className="text-center space-y-4 pt-6 pb-4">
          <div className="flex justify-center mb-6">
            <Logo size="xl" showText={false} />
          </div>
          <div className="space-y-2">
            <CardTitle className="text-3xl font-bold text-primary">
              {APP_NAME}
            </CardTitle>
            <CardDescription className="text-lg text-muted-foreground">
              Friends with benefits
            </CardDescription>
          </div>
          
          <div className="flex justify-center space-x-2 py-2">
            <div className="w-10 h-10 rounded-full bg-gradient-mint flex items-center justify-center animate-gentle-scale">
              <span className="text-white text-sm">💙</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-gradient-green flex items-center justify-center animate-gentle-scale">
              <span className="text-white text-sm">🤝</span>
            </div>
            <div className="w-10 h-10 rounded-full bg-accent flex items-center justify-center animate-gentle-scale">
              <span className="text-white text-sm">💰</span>
            </div>
          </div>
        </CardHeader>
        
        <CardContent className="space-y-4 pb-6 px-6">
          <div className="space-y-2 text-center">
            <p className="text-sm text-foreground">
              Get help from people who know you.
            </p>
            <p className="text-sm text-foreground">
              Support people you trust.
            </p>
            <p className="text-sm text-foreground">
              Build your circle's financial future together.
            </p>
          </div>
          
          <Button 
            onClick={login} 
            className="w-full h-10 text-sm font-medium bg-primary hover:bg-primary/90 animate-gentle-scale rounded-cow"
          >
            Join Your Circle
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}