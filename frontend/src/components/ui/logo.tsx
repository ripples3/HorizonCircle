'use client';

import { APP_NAME } from '@/constants';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  showText?: boolean;
}

export function Logo({ size = 'md', className = '', showText = true }: LogoProps) {
  const sizeClasses = {
    sm: 'w-6 h-6',
    md: 'w-8 h-8', 
    lg: 'w-12 h-12',
    xl: 'w-16 h-16'
  };

  const textSizeClasses = {
    sm: 'text-lg',
    md: 'text-xl',
    lg: 'text-2xl', 
    xl: 'text-3xl'
  };

  return (
    <div className={`flex items-center space-x-2 ${className}`}>
      {/* Logo Icon - Enhanced Horizon Circle Design */}
      <div className={`${sizeClasses[size]} rounded-full bg-gradient-green flex items-center justify-center animate-gentle-scale border-2 border-primary/20 shadow-lg`}>
        <div className="w-3/5 h-3/5 rounded-full bg-white flex items-center justify-center">
          <div className="w-1/2 h-1/2 rounded-full bg-primary/80"></div>
        </div>
      </div>
      
      {/* App Name */}
      {showText && (
        <span className={`${textSizeClasses[size]} font-bold text-primary animate-fade-in-soft`}>
          {APP_NAME}
        </span>
      )}
    </div>
  );
}