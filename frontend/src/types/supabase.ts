export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          wallet_address: string;
          email: string | null;
          balance: number;
          available_to_borrow: number;
          current_loan: number;
          yield_earned: number;
          circle_id: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          wallet_address: string;
          email?: string | null;
          balance?: number;
          available_to_borrow?: number;
          current_loan?: number;
          yield_earned?: number;
          circle_id?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          wallet_address?: string;
          email?: string | null;
          balance?: number;
          available_to_borrow?: number;
          current_loan?: number;
          yield_earned?: number;
          circle_id?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      circles: {
        Row: {
          id: string;
          name: string;
          created_by: string;
          total_value: number;
          member_count: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          created_by: string;
          total_value?: number;
          member_count?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          created_by?: string;
          total_value?: number;
          member_count?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      loans: {
        Row: {
          id: string;
          borrower_id: string;
          amount: number;
          interest_rate: number;
          term: number;
          status: 'active' | 'completed' | 'defaulted';
          collateral_amount: number;
          created_at: string;
          due_date: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          borrower_id: string;
          amount: number;
          interest_rate: number;
          term: number;
          status: 'active' | 'completed' | 'defaulted';
          collateral_amount: number;
          created_at?: string;
          due_date: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          borrower_id?: string;
          amount?: number;
          interest_rate?: number;
          term?: number;
          status?: 'active' | 'completed' | 'defaulted';
          collateral_amount?: number;
          created_at?: string;
          due_date?: string;
          updated_at?: string;
        };
      };
      loan_requests: {
        Row: {
          id: string;
          borrower_id: string;
          circle_id: string;
          requested_amount: number;
          personal_collateral: number;
          needed_collateral: number;
          purpose: string;
          status: 'pending' | 'approved' | 'rejected';
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          borrower_id: string;
          circle_id: string;
          requested_amount: number;
          personal_collateral: number;
          needed_collateral: number;
          purpose: string;
          status: 'pending' | 'approved' | 'rejected';
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          borrower_id?: string;
          circle_id?: string;
          requested_amount?: number;
          personal_collateral?: number;
          needed_collateral?: number;
          purpose?: string;
          status?: 'pending' | 'approved' | 'rejected';
          created_at?: string;
          updated_at?: string;
        };
      };
      contributions: {
        Row: {
          id: string;
          contributor_id: string;
          loan_request_id: string;
          amount: number;
          interest_rate: number;
          status: 'pending' | 'confirmed' | 'withdrawn';
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          contributor_id: string;
          loan_request_id: string;
          amount: number;
          interest_rate: number;
          status: 'pending' | 'confirmed' | 'withdrawn';
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          contributor_id?: string;
          loan_request_id?: string;
          amount?: number;
          interest_rate?: number;
          status?: 'pending' | 'confirmed' | 'withdrawn';
          created_at?: string;
          updated_at?: string;
        };
      };
      transactions: {
        Row: {
          id: string;
          user_id: string;
          type: 'deposit' | 'borrow' | 'repay' | 'contribution';
          amount: number;
          description: string;
          status: 'pending' | 'completed' | 'failed';
          tx_hash: string | null;
          timestamp: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          type: 'deposit' | 'borrow' | 'repay' | 'contribution';
          amount: number;
          description: string;
          status: 'pending' | 'completed' | 'failed';
          tx_hash?: string | null;
          timestamp?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          type?: 'deposit' | 'borrow' | 'repay' | 'contribution';
          amount?: number;
          description?: string;
          status?: 'pending' | 'completed' | 'failed';
          tx_hash?: string | null;
          timestamp?: string;
        };
      };
    };
  };
}