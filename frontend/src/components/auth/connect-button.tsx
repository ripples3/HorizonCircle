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
    <Card className={`${className} border-0 shadow-2xl bg-gradient-to-br from-blue-50 to-indigo-50 overflow-hidden relative`}>
      <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-400 to-indigo-400 rounded-full blur-3xl opacity-20"></div>
      <div className="absolute bottom-0 left-0 w-40 h-40 bg-gradient-to-tr from-indigo-400 to-blue-400 rounded-full blur-3xl opacity-20"></div>
      
      <CardHeader className="text-center space-y-6 pt-12 pb-8 relative z-10">
        <div className="space-y-2">
          <CardTitle className="text-5xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
            {APP_NAME}
          </CardTitle>
          <CardDescription className="text-2xl font-semibold text-gray-800">
            Friends with benefits
          </CardDescription>
        </div>
        
        <div className="flex justify-center space-x-2 py-4">
          <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-400 to-blue-500 flex items-center justify-center text-white font-bold animate-pulse">
            💙
          </div>
          <div className="w-12 h-12 rounded-full bg-gradient-to-br from-indigo-400 to-indigo-500 flex items-center justify-center text-white font-bold animate-pulse delay-100">
            🤝
          </div>
          <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-indigo-400 flex items-center justify-center text-white font-bold animate-pulse delay-200">
            💰
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="space-y-6 pb-12 px-8 relative z-10">
        <div className="space-y-4 text-center">
          <p className="text-lg font-medium text-gray-700 leading-relaxed">
            Get help from people who know you.
          </p>
          <p className="text-lg font-medium text-gray-700 leading-relaxed">
            Support people you trust.
          </p>
          <p className="text-lg font-medium text-gray-700 leading-relaxed">
            Build your circle's financial future together.
          </p>
        </div>
        
        <Button 
          onClick={login} 
          className="w-full h-14 text-lg font-semibold bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 transform hover:scale-105 transition-all duration-200 shadow-lg"
          size="lg"
        >
          Join Your Circle
        </Button>
      </CardContent>
    </Card>
  );
}