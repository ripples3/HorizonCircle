import { createClient } from '@supabase/supabase-js';
import { Database } from '@/types/supabase';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey);

// Database helper functions
export const db = {
  // Users
  async getUser(walletAddress: string) {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('wallet_address', walletAddress)
      .single();
    
    if (error && error.code !== 'PGRST116') throw error;
    return data;
  },

  async upsertUser(user: {
    wallet_address: string;
    email?: string;
    balance?: number;
    available_to_borrow?: number;
    current_loan?: number;
    yield_earned?: number;
    circle_id?: string;
  }) {
    const { data, error } = await supabase
      .from('users')
      .upsert(user)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  },

  // Circles
  async getCircle(circleId: string) {
    const { data, error } = await supabase
      .from('circles')
      .select(`
        *,
        users(*)
      `)
      .eq('id', circleId)
      .single();
    
    if (error) throw error;
    return data;
  },

  async createCircle(circle: {
    name: string;
    created_by: string;
  }) {
    const { data, error } = await supabase
      .from('circles')
      .insert(circle)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  },

  // Loans
  async getLoans(userId: string) {
    const { data, error } = await supabase
      .from('loans')
      .select('*')
      .eq('borrower_id', userId)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data;
  },

  async createLoan(loan: {
    borrower_id: string;
    amount: number;
    interest_rate: number;
    term: number;
    collateral_amount: number;
    status: 'active' | 'completed' | 'defaulted';
    due_date: string;
  }) {
    const { data, error } = await supabase
      .from('loans')
      .insert(loan)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  },

  // Loan Requests
  async getLoanRequests(circleId: string) {
    const { data, error } = await supabase
      .from('loan_requests')
      .select('*')
      .eq('circle_id', circleId)
      .eq('status', 'pending')
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data;
  },

  async createLoanRequest(loanRequest: {
    borrower_id: string;
    circle_id: string;
    requested_amount: number;
    personal_collateral: number;
    needed_collateral: number;
    purpose: string;
    status: 'pending' | 'approved' | 'rejected';
  }) {
    const { data, error } = await supabase
      .from('loan_requests')
      .insert(loanRequest)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  },

  // Transactions
  async getTransactions(userId: string) {
    const { data, error } = await supabase
      .from('transactions')
      .select('*')
      .eq('user_id', userId)
      .order('timestamp', { ascending: false })
      .limit(10);
    
    if (error) throw error;
    return data;
  },

  async createTransaction(transaction: {
    user_id: string;
    type: 'deposit' | 'borrow' | 'repay' | 'contribution';
    amount: number;
    description: string;
    status: 'pending' | 'completed' | 'failed';
    tx_hash?: string;
  }) {
    const { data, error } = await supabase
      .from('transactions')
      .insert(transaction)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  },
};