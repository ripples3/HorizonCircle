// User Types
export interface User {
  id: string;
  email: string;
  walletAddress: string;
  balance: number;
  availableToBorrow: number;
  currentLoan: number;
  yieldEarned: number;
  circleId?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Circle Types
export interface Circle {
  id: string;
  name: string;
  members: User[];
  totalValue: number;
  activeLoanRequests: LoanRequest[];
  createdAt: Date;
  updatedAt: Date;
}

// Loan Types
export interface Loan {
  id: string;
  borrowerId: string;
  amount: number;
  interestRate: number;
  term: number; // in months
  status: 'active' | 'completed' | 'defaulted';
  collateralAmount: number;
  contributedCollateral: ContributedCollateral[];
  createdAt: Date;
  dueDate: Date;
}

export interface LoanRequest {
  id: string;
  borrowerId: string;
  requestedAmount: number;
  personalCollateral: number;
  neededCollateral: number;
  purpose: string;
  status: 'pending' | 'approved' | 'rejected';
  contributions: ContributedCollateral[];
  createdAt: Date;
}

export interface ContributedCollateral {
  contributorId: string;
  amount: number;
  interestRate: number;
  status: 'pending' | 'confirmed' | 'withdrawn';
  createdAt: Date;
}

// Dashboard Types
export interface DashboardData {
  user: User;
  totalDeposits: number;
  totalBorrowed: number;
  availableToEarn: number;
  yieldRate: number;
  borrowingRate: number;
  recentTransactions: Transaction[];
}

export interface Transaction {
  id: string;
  type: 'deposit' | 'borrow' | 'repay' | 'contribution';
  amount: number;
  timestamp: Date;
  description: string;
  status: 'pending' | 'completed' | 'failed';
}