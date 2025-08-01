/**
 * IndexedDB-based circle discovery cache
 * Provides persistent caching for discovered circles to eliminate repeated blockchain scanning
 */

interface CircleCacheData {
  userAddress: string;
  circles: string[];
  lastScannedBlock: bigint;
  timestamp: number;
  blockNumber: bigint; // Latest block when cache was created
}

interface CircleMetadata {
  address: string;
  name: string;
  creator: string;
  registrationBlock: bigint;
}

class CircleCacheManager {
  private dbName = 'HorizonCircleCache';
  private version = 1;
  private db: IDBDatabase | null = null;

  // Initialize IndexedDB database
  async initDB(): Promise<IDBDatabase> {
    if (this.db) return this.db;

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;

        // Store for user circle discovery cache
        if (!db.objectStoreNames.contains('userCircles')) {
          db.createObjectStore('userCircles', { keyPath: 'userAddress' });
        }

        // Store for circle metadata (name, creator, etc)
        if (!db.objectStoreNames.contains('circleMetadata')) {
          const metadataStore = db.createObjectStore('circleMetadata', { keyPath: 'address' });
          metadataStore.createIndex('creator', 'creator', { unique: false });
          metadataStore.createIndex('registrationBlock', 'registrationBlock', { unique: false });
        }
      };
    });
  }

  // Get cached circles for a user
  async getCachedCircles(userAddress: string): Promise<CircleCacheData | null> {
    const db = await this.initDB();
    
    return new Promise((resolve, reject) => {
      const transaction = db.transaction(['userCircles'], 'readonly');
      const store = transaction.objectStore('userCircles');
      const request = store.get(userAddress.toLowerCase());

      request.onsuccess = () => {
        const result = request.result;
        if (result) {
          // Convert bigint strings back to bigint
          result.lastScannedBlock = BigInt(result.lastScannedBlock);
          result.blockNumber = BigInt(result.blockNumber);
        }
        resolve(result || null);
      };
      request.onerror = () => reject(request.error);
    });
  }

  // Store discovered circles for a user
  async storeCachedCircles(data: CircleCacheData): Promise<void> {
    const db = await this.initDB();

    return new Promise((resolve, reject) => {
      const transaction = db.transaction(['userCircles'], 'readwrite');
      const store = transaction.objectStore('userCircles');
      
      // Convert bigints to strings for storage
      const storageData = {
        ...data,
        userAddress: data.userAddress.toLowerCase(),
        lastScannedBlock: data.lastScannedBlock.toString(),
        blockNumber: data.blockNumber.toString(),
      };

      const request = store.put(storageData);
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  // Store circle metadata
  async storeCircleMetadata(metadata: CircleMetadata): Promise<void> {
    const db = await this.initDB();

    return new Promise((resolve, reject) => {
      const transaction = db.transaction(['circleMetadata'], 'readwrite');
      const store = transaction.objectStore('circleMetadata');
      
      const storageData = {
        ...metadata,
        address: metadata.address.toLowerCase(),
        registrationBlock: metadata.registrationBlock.toString(),
      };

      const request = store.put(storageData);
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  // Get circle metadata
  async getCircleMetadata(address: string): Promise<CircleMetadata | null> {
    const db = await this.initDB();

    return new Promise((resolve, reject) => {
      const transaction = db.transaction(['circleMetadata'], 'readonly');
      const store = transaction.objectStore('circleMetadata');
      const request = store.get(address.toLowerCase());

      request.onsuccess = () => {
        const result = request.result;
        if (result) {
          result.registrationBlock = BigInt(result.registrationBlock);
        }
        resolve(result || null);
      };
      request.onerror = () => reject(request.error);
    });
  }

  // Check if cache is still valid (not older than 5 minutes for active development)
  isCacheValid(cacheData: CircleCacheData, currentBlock: bigint): boolean {
    const cacheAge = Date.now() - cacheData.timestamp;
    const maxAge = 5 * 60 * 1000; // 5 minutes during development
    
    // Cache is valid if:
    // 1. Not too old
    // 2. Current block is not significantly newer (indicates we might have missed events)
    const blockDiff = currentBlock - cacheData.blockNumber;
    const maxBlockDiff = BigInt(100); // Allow up to 100 blocks difference (~5 minutes)

    return cacheAge < maxAge && blockDiff < maxBlockDiff;
  }

  // Clear all cache (useful for development/testing)
  async clearCache(): Promise<void> {
    const db = await this.initDB();

    return new Promise((resolve, reject) => {
      const transaction = db.transaction(['userCircles', 'circleMetadata'], 'readwrite');
      
      const clearUserCircles = transaction.objectStore('userCircles').clear();
      const clearMetadata = transaction.objectStore('circleMetadata').clear();

      let completed = 0;
      const checkComplete = () => {
        completed++;
        if (completed === 2) resolve();
      };

      clearUserCircles.onsuccess = checkComplete;
      clearMetadata.onsuccess = checkComplete;
      
      transaction.onerror = () => reject(transaction.error);
    });
  }

  // Get cache statistics for debugging
  async getCacheStats(): Promise<{ userCircleCount: number; metadataCount: number }> {
    const db = await this.initDB();

    return new Promise((resolve, reject) => {
      const transaction = db.transaction(['userCircles', 'circleMetadata'], 'readonly');
      
      const userCirclesRequest = transaction.objectStore('userCircles').count();
      const metadataRequest = transaction.objectStore('circleMetadata').count();

      let userCircleCount = 0;
      let metadataCount = 0;
      let completed = 0;

      const checkComplete = () => {
        completed++;
        if (completed === 2) {
          resolve({ userCircleCount, metadataCount });
        }
      };

      userCirclesRequest.onsuccess = () => {
        userCircleCount = userCirclesRequest.result;
        checkComplete();
      };

      metadataRequest.onsuccess = () => {
        metadataCount = metadataRequest.result;
        checkComplete();
      };

      transaction.onerror = () => reject(transaction.error);
    });
  }
}

// Export singleton instance
export const circleCacheManager = new CircleCacheManager();

// Utility functions for easy use
export const getCachedCircles = (userAddress: string) => 
  circleCacheManager.getCachedCircles(userAddress);

export const storeCachedCircles = (data: CircleCacheData) => 
  circleCacheManager.storeCachedCircles(data);

export const storeCircleMetadata = (metadata: CircleMetadata) => 
  circleCacheManager.storeCircleMetadata(metadata);

export const getCircleMetadata = (address: string) => 
  circleCacheManager.getCircleMetadata(address);

export const clearCircleCache = () => 
  circleCacheManager.clearCache();

export const getCircleCacheStats = () => 
  circleCacheManager.getCacheStats();

// Export types for use in other files
export type { CircleCacheData, CircleMetadata };