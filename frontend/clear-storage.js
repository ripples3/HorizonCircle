// Script to clear all storage for a fresh start
// Run this in the browser console

console.log('Clearing all storage for fresh start...');

// Clear localStorage
localStorage.clear();
console.log('✓ localStorage cleared');

// Clear sessionStorage  
sessionStorage.clear();
console.log('✓ sessionStorage cleared');

// Clear specific keys if needed
const keysToRemove = [
  'circles-',
  'userActiveLoans',
  'contributed-requests',
  'declined-requests',
  'executed-requests'
];

// Additional cleanup for any prefixed keys
for (let i = localStorage.length - 1; i >= 0; i--) {
  const key = localStorage.key(i);
  if (keysToRemove.some(prefix => key && key.startsWith(prefix))) {
    localStorage.removeItem(key);
    console.log(`✓ Removed ${key}`);
  }
}

console.log('✅ All storage cleared! Please refresh the page.');