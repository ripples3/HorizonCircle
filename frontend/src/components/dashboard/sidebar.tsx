'use client';

import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { APP_NAME } from '@/constants';
import { 
  Home, 
  PiggyBank, 
  CreditCard, 
  Users, 
  HelpCircle, 
  Settings,
  TrendingUp,
  Activity
} from 'lucide-react';

interface SidebarProps {
  className?: string;
  activeTab: string;
  onTabChange: (tab: string) => void;
  hasCircles?: boolean;
}

const navigationItems = [
  { id: 'dashboard', label: 'Dashboard', icon: Home },
  { id: 'deposit', label: 'Earn', icon: PiggyBank },
  { id: 'borrow', label: 'Borrow', icon: CreditCard },
  { id: 'circle', label: 'Circle', icon: Users },
  { id: 'analytics', label: 'Analytics', icon: TrendingUp },
];

const bottomItems = [
  { id: 'activity', label: 'Activity', icon: Activity },
  { id: 'help', label: 'Help', icon: HelpCircle },
  { id: 'settings', label: 'Settings', icon: Settings },
];

export default function Sidebar({ className, activeTab, onTabChange, hasCircles = false }: SidebarProps) {
  // Filter navigation items based on circle availability
  const availableItems = navigationItems.filter(item => {
    // Always show dashboard and circle tabs
    if (item.id === 'dashboard' || item.id === 'circle') return true;
    // Show deposit/borrow only if user has circles
    if (item.id === 'deposit' || item.id === 'borrow') return hasCircles;
    // Show other items by default
    return true;
  });
  return (
    <div className={cn("flex flex-col h-full w-64 bg-white border-r border-gray-200", className)}>
      {/* Header */}
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
            <PiggyBank className="w-5 h-5 text-white" />
          </div>
          <h1 className="text-xl font-semibold text-gray-900">{APP_NAME}</h1>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4">
        <div className="space-y-2">
          {availableItems.map((item) => {
            const Icon = item.icon;
            return (
              <Button
                key={item.id}
                variant={activeTab === item.id ? "default" : "ghost"}
                className={cn(
                  "w-full justify-start gap-3 h-12 px-4",
                  activeTab === item.id && "bg-blue-600 text-white hover:bg-blue-700"
                )}
                onClick={() => onTabChange(item.id)}
              >
                <Icon className="w-5 h-5" />
                {item.label}
              </Button>
            );
          })}
        </div>
      </nav>

      {/* Bottom Section */}
      <div className="p-4 border-t border-gray-200">
        <div className="space-y-2">
          {bottomItems.map((item) => {
            const Icon = item.icon;
            return (
              <Button
                key={item.id}
                variant={activeTab === item.id ? "default" : "ghost"}
                className={cn(
                  "w-full justify-start gap-3 h-12 px-4",
                  activeTab === item.id && "bg-blue-600 text-white hover:bg-blue-700"
                )}
                onClick={() => onTabChange(item.id)}
              >
                <Icon className="w-5 h-5" />
                {item.label}
              </Button>
            );
          })}
        </div>
      </div>
    </div>
  );
}