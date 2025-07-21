'use client';

import { useState } from 'react';
import { db } from '@/config/supabase';

export default function DatabaseTest() {
  const [result, setResult] = useState<string>('');
  const [loading, setLoading] = useState(false);

  const testConnection = async () => {
    setLoading(true);
    try {
      // Test basic connection
      const testUser = await db.upsertUser({
        wallet_address: 'test-wallet-' + Date.now(),
        email: 'test@example.com',
        balance: 100,
        available_to_borrow: 85,
        current_loan: 0,
        yield_earned: 5,
      });
      
      setResult(`✅ Success! Created user: ${JSON.stringify(testUser, null, 2)}`);
    } catch (error) {
      console.error('Database error:', error);
      setResult(`❌ Error: ${JSON.stringify(error, null, 2)}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-4 border rounded-lg bg-gray-50">
      <h3 className="font-bold mb-2">Database Connection Test</h3>
      
      <button
        onClick={testConnection}
        disabled={loading}
        className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
      >
        {loading ? 'Testing...' : 'Test Database Connection'}
      </button>
      
      {result && (
        <pre className="mt-4 p-2 bg-white border rounded text-sm overflow-auto">
          {result}
        </pre>
      )}
    </div>
  );
}