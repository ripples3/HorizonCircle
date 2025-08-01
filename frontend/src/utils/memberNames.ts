// Member name utilities for better identification
import { useState, useEffect } from 'react';

export interface MemberInfo {
  address: string;
  displayName: string;
  isCustomName: boolean;
}

// Generate a friendly name from wallet address
export function generateMemberName(address: string): string {
  if (!address) return 'Unknown';
  
  // Use the last 4 characters to generate friendly names
  const suffix = address.slice(-4).toLowerCase();
  const nameMap: Record<string, string> = {
    // Existing mappings
    '172e': 'Alice',
    '3f4d': 'Bob', 
    '8a9c': 'Charlie',
    'b2e1': 'Diana',
    'c5f7': 'Eve',
    'd8a3': 'Frank',
    'e1b6': 'Grace',
    'f4c9': 'Henry',
    '2d5a': 'Ivy',
    '6e8b': 'Jack',
    '9c1f': 'Kate',
    'a4d7': 'Liam',
    'b7e2': 'Maya',
    'c8f5': 'Noah',
    'd3a8': 'Olivia',
    'e6b1': 'Peter',
    'f9c4': 'Quinn',
    '1a7d': 'Ruby',
    '4b8e': 'Sam',
    '7c9f': 'Tara',
    
    // Add your specific addresses
    '8129': 'Emma',
    '9e1c': 'James',
    '1aba': 'Sofia',
    
    // Additional common names
    '2b5c': 'Lucas',
    '3d6e': 'Mia',
    '4f7g': 'Oliver',
    '5h8i': 'Ava',
    '6j9k': 'William',
    '7l0m': 'Isabella',
    '8n1o': 'Benjamin',
    '9p2q': 'Charlotte',
    'a3r4': 'Elijah',
    'b5s6': 'Amelia',
    'c7t8': 'Alexander',
    'd9u0': 'Harper',
    'e1v2': 'Michael',
    'f3w4': 'Evelyn',
  };
  
  // If not in map, generate a more friendly fallback
  if (nameMap[suffix]) {
    return nameMap[suffix];
  }
  
  // Generate names based on patterns for unknown addresses
  const firstChar = suffix.charAt(0);
  const nameByFirstChar: Record<string, string[]> = {
    '0': ['Owen', 'Olivia', 'Oscar'],
    '1': ['Ian', 'Iris', 'Isaac'],
    '2': ['Zoe', 'Zach', 'Zara'],
    '3': ['Leo', 'Luna', 'Lila'],
    '4': ['Max', 'Maya', 'Milo'],
    '5': ['Sam', 'Sara', 'Seth'],
    '6': ['Rio', 'Ruby', 'Ryan'],
    '7': ['Kai', 'Kira', 'Kyle'],
    '8': ['Eli', 'Eva', 'Ezra'],
    '9': ['Noa', 'Nia', 'Neo'],
    'a': ['Ari', 'Ana', 'Alex'],
    'b': ['Ben', 'Bea', 'Blake'],
    'c': ['Cam', 'Cleo', 'Cruz'],
    'd': ['Dan', 'Dara', 'Drew'],
    'e': ['Eli', 'Ella', 'Evan'],
    'f': ['Finn', 'Faye', 'Felix'],
  };
  
  const nameOptions = nameByFirstChar[firstChar] || ['Friend'];
  const nameIndex = parseInt(suffix.slice(1, 3), 16) % nameOptions.length;
  return nameOptions[nameIndex];
}

// Get member info with name
export function getMemberInfo(address: string): MemberInfo {
  if (typeof window === 'undefined') {
    // Server-side rendering fallback
    return {
      address,
      displayName: generateMemberName(address),
      isCustomName: false
    };
  }
  
  // Check localStorage for custom names first
  const customNames = JSON.parse(localStorage.getItem('circle-member-names') || '{}');
  const customName = customNames[address.toLowerCase()];
  
  return {
    address,
    displayName: customName || generateMemberName(address),
    isCustomName: !!customName
  };
}

// Save custom name for an address
export function setMemberName(address: string, name: string): void {
  if (typeof window === 'undefined') return;
  
  const customNames = JSON.parse(localStorage.getItem('circle-member-names') || '{}');
  customNames[address.toLowerCase()] = name;
  localStorage.setItem('circle-member-names', JSON.stringify(customNames));
  
  // Dispatch custom event to trigger re-renders
  window.dispatchEvent(new CustomEvent('memberNameUpdated', { detail: { address, name } }));
}

// Hook to get member names with updates
export function useMemberNames(addresses: readonly string[] | string[]): MemberInfo[] {
  const [memberInfos, setMemberInfos] = useState<MemberInfo[]>([]);
  const [forceUpdate, setForceUpdate] = useState(0);
  
  useEffect(() => {
    if (!addresses || addresses.length === 0) {
      setMemberInfos([]);
      return;
    }
    
    const infos = addresses.map(getMemberInfo);
    setMemberInfos(infos);
  }, [addresses.join(','), forceUpdate]); // Re-run when addresses change or forced update
  
  // Listen for localStorage changes
  useEffect(() => {
    const handleStorageChange = () => {
      setForceUpdate(prev => prev + 1);
    };
    
    // Listen for custom storage events
    window.addEventListener('memberNameUpdated', handleStorageChange);
    
    return () => {
      window.removeEventListener('memberNameUpdated', handleStorageChange);
    };
  }, []);
  
  return memberInfos;
}