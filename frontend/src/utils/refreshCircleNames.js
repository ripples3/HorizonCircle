// Clear cache and refresh page to get updated circle names
console.log('🔄 Clearing circle cache to refresh names...');

// Clear IndexedDB cache
const deleteReq = indexedDB.deleteDatabase('HorizonCircleCache');
deleteReq.onsuccess = () => {
  console.log('✅ Cache cleared successfully');
  console.log('🔄 Refreshing page to reload circle names...');
  window.location.reload();
};

deleteReq.onerror = (error) => {
  console.log('❌ Cache clear failed:', error);
  console.log('🔄 Refreshing anyway...');
  window.location.reload();
};

console.log('ℹ️ This will refresh the page and reload circle names from factory events');