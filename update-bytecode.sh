#!/bin/bash

echo "Updating HorizonCircle bytecode in frontend..."

# Extract the latest bytecode from the compiled contract
BYTECODE=$(cat contracts/out/HorizonCircle.sol/HorizonCircle.json | jq -r '.bytecode.object' | sed 's/^0x//')

# Create a backup
cp frontend/src/utils/contractDeployment.ts frontend/src/utils/contractDeployment.ts.backup

# Update the bytecode in the frontend file
# This will replace the old bytecode with the new one
sed -i '' "s/export const HORIZON_CIRCLE_BYTECODE = '0x' + \`0x[0-9a-fA-F]*\`/export const HORIZON_CIRCLE_BYTECODE = '0x' + \`0x${BYTECODE}\`/" frontend/src/utils/contractDeployment.ts

echo "Bytecode updated successfully!"
echo "New bytecode starts with: 0x${BYTECODE:0:50}..."