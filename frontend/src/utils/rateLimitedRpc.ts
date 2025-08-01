import { PublicClient } from 'viem';
import { readContract } from 'viem/actions';

// Rate limiting configuration
const RATE_LIMIT_DELAY = 100; // 100ms between requests
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // Start with 1 second delay

// Queue for rate-limited requests
const requestQueue: (() => Promise<any>)[] = [];
let isProcessing = false;

// Process queue with rate limiting
async function processQueue() {
  if (isProcessing || requestQueue.length === 0) return;
  
  isProcessing = true;
  
  while (requestQueue.length > 0) {
    const request = requestQueue.shift();
    if (request) {
      try {
        await request();
      } catch (error) {
        console.error('Request failed:', error);
      }
      // Rate limit delay between requests
      await new Promise(resolve => setTimeout(resolve, RATE_LIMIT_DELAY));
    }
  }
  
  isProcessing = false;
}

// Retry with exponential backoff
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  retries = MAX_RETRIES,
  delay = RETRY_DELAY
): Promise<T> {
  try {
    return await fn();
  } catch (error: any) {
    if (retries === 0 || !error?.message?.includes('429')) {
      throw error;
    }
    
    console.log(`Rate limited, retrying in ${delay}ms...`);
    await new Promise(resolve => setTimeout(resolve, delay));
    return retryWithBackoff(fn, retries - 1, delay * 2);
  }
}

// Rate-limited readContract
export async function rateLimitedReadContract<T>(
  publicClient: PublicClient,
  params: Parameters<typeof readContract>[1]
): Promise<T> {
  return new Promise((resolve, reject) => {
    requestQueue.push(async () => {
      try {
        const result = await retryWithBackoff(() =>
          readContract(publicClient, params)
        );
        resolve(result as T);
      } catch (error) {
        reject(error);
      }
    });
    
    processQueue();
  });
}

// Rate-limited getLogs
export async function rateLimitedGetLogs<T>(
  publicClient: PublicClient,
  params: Parameters<PublicClient['getLogs']>[0]
): Promise<T> {
  return new Promise((resolve, reject) => {
    requestQueue.push(async () => {
      try {
        const result = await retryWithBackoff(() =>
          publicClient.getLogs(params)
        );
        resolve(result as T);
      } catch (error) {
        reject(error);
      }
    });
    
    processQueue();
  });
}

// Batch multiple read operations
export async function batchReadContracts<T extends any[]>(
  publicClient: PublicClient,
  calls: Parameters<typeof readContract>[1][]
): Promise<T> {
  const results = await Promise.all(
    calls.map((call) => rateLimitedReadContract(publicClient, call))
  );
  return results as T;
}