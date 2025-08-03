// Clear IndexedDB cache for updated contract addresses
const deleteReq = indexedDB.deleteDatabase('HorizonCircleCache');
deleteReq.onsuccess = () => {
  console.log('✅ Cache cleared - new contracts will be used');
  window.location.reload();
};
deleteReq.onerror = () => {
  console.log('Cache clear failed, but continuing...');
  window.location.reload();
};