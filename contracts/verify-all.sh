#!/bin/bash

# HorizonCircle Contract Verification Script for Blockscout
# Run this from the contracts directory

echo "🔍 Starting contract verification on Lisk Blockscout..."
echo ""

# Check if we're in the right directory
if [ ! -f "foundry.toml" ]; then
    echo "❌ Error: Please run this script from the contracts directory"
    exit 1
fi

echo "1️⃣ Verifying Factory Contract..."
forge verify-contract \
  --chain-id 1135 \
  --num-of-optimizations 200 \
  --compiler-version v0.8.20+commit.a1b79de6 \
  --verifier blockscout \
  --verifier-url https://blockscout.lisk.com/api \
  0x95e4c63Ee7e82b94D75dDbF858F0D2D0600fcCdD \
  src/HorizonCircleModularFactory.sol:HorizonCircleModularFactory

echo ""
echo "2️⃣ Verifying Registry Contract..."
forge verify-contract \
  --chain-id 1135 \
  --num-of-optimizations 200 \
  --compiler-version v0.8.20+commit.a1b79de6 \
  --verifier blockscout \
  --verifier-url https://blockscout.lisk.com/api \
  0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE \
  src/CircleRegistry.sol:CircleRegistry

echo ""
echo "3️⃣ Verifying Implementation Contract..."
forge verify-contract \
  --chain-id 1135 \
  --num-of-optimizations 200 \
  --compiler-version v0.8.20+commit.a1b79de6 \
  --verifier blockscout \
  --verifier-url https://blockscout.lisk.com/api \
  0x763004aE80080C36ec99eC5f2dc3F2C260638A83 \
  src/HorizonCircleWithMorphoAuth.sol:HorizonCircleWithMorphoAuth

echo ""
echo "4️⃣ Verifying Lending Module Contract..."
forge verify-contract \
  --chain-id 1135 \
  --num-of-optimizations 200 \
  --compiler-version v0.8.20+commit.a1b79de6 \
  --verifier blockscout \
  --verifier-url https://blockscout.lisk.com/api \
  0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801 \
  src/LendingModuleSimplified.sol:LendingModuleSimplified

echo ""
echo "✅ Verification complete! Check the results above."
echo "📋 You can also verify manually at: https://blockscout.lisk.com"
echo ""
echo "💡 If any verification failed, try:"
echo "   - Check that the source code matches exactly"
echo "   - Verify you're using the correct contract name"
echo "   - Try using --etherscan instead of --verifier blockscout"