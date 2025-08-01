// Utility script to clear circle cache
// Run this in the browser console to clear the IndexedDB cache

async function clearCircleCache() {
  try {
    // Clear IndexedDB cache
    const dbName = 'HorizonCircleCache';
    
    // Delete the entire database to force a fresh start
    const deleteReq = indexedDB.deleteDatabase(dbName);
    
    deleteReq.onsuccess = () => {
      console.log('✅ Circle cache database deleted successfully');
      
      // Also clear localStorage items related to circles
      const keysToRemove = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && (key.includes('circle') || key.includes('Circle'))) {
          keysToRemove.push(key);
        }
      }
      
      keysToRemove.forEach(key => localStorage.removeItem(key));
      console.log('✅ Cleared', keysToRemove.length, 'localStorage entries');
      
      // Clear sessionStorage items related to circles
      const sessionKeysToRemove = [];
      for (let i = 0; i < sessionStorage.length; i++) {
        const key = sessionStorage.key(i);
        if (key && (key.includes('circle') || key.includes('Circle'))) {
          sessionKeysToRemove.push(key);
        }
      }
      
      sessionKeysToRemove.forEach(key => sessionStorage.removeItem(key));
      console.log('✅ Cleared', sessionKeysToRemove.length, 'sessionStorage entries');
      
      console.log('🔄 Reloading page to apply changes...');
      window.location.reload();
    };
    
    deleteReq.onerror = (error) => {
      console.error('❌ Failed to delete cache database:', error);
    };
    
  } catch (error) {
    console.error('❌ Error clearing cache:', error);
  }
}

// Run the cache clearing
clearCircleCache();