'use client';

import { PrivyProvider } from '@privy-io/react-auth';
import { WagmiProvider } from '@privy-io/wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactNode } from 'react';
import { wagmiConfig, liskChain } from '@/config/web3';

interface Props {
  children: ReactNode;
}

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30000, // 30 seconds
      refetchInterval: false,
      refetchOnWindowFocus: false,
      retry: 2,
      retryDelay: 3000,
    },
  },
});

export default function PrivyProviderWrapper({ children }: Props) {
  const privyAppId = process.env.NEXT_PUBLIC_PRIVY_APP_ID;
  
  // If no Privy app ID is set, render a fallback
  if (!privyAppId || privyAppId === 'demo-app-id') {
    return (
      <QueryClientProvider client={queryClient}>
        <WagmiProvider config={wagmiConfig}>
          <div className="min-h-screen bg-gradient-to-br from-red-50 to-red-100 flex items-center justify-center p-4">
            <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-6">
              <h2 className="text-xl font-bold text-red-600 mb-4">Configuration Required</h2>
              <p className="text-gray-700 mb-4">
                Please set up your Privy app ID in the environment variables to enable authentication.
              </p>
              <div className="bg-gray-100 p-3 rounded text-sm">
                <code>NEXT_PUBLIC_PRIVY_APP_ID=your_app_id_here</code>
              </div>
            </div>
          </div>
        </WagmiProvider>
      </QueryClientProvider>
    );
  }

  return (
    <PrivyProvider
      appId={privyAppId}
      config={{
        // Customize Privy's appearance and behavior
        appearance: {
          theme: 'light',
          accentColor: '#3B82F6',
        },
        // Optimize login methods for faster loading
        loginMethods: ['wallet', 'email'],
        // Simplified embedded wallet config
        embeddedWallets: {
          createOnLogin: 'users-without-wallets',
          noPromptOnSignature: true,
        },
        // Network configuration - force Lisk for embedded wallets
        supportedChains: [liskChain],
        defaultChain: liskChain,
      }}
    >
      <QueryClientProvider client={queryClient}>
        <WagmiProvider config={wagmiConfig}>
          {children}
        </WagmiProvider>
      </QueryClientProvider>
    </PrivyProvider>
  );
}