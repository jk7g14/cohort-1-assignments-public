#!/bin/sh

set -e

echo "🚀 Starting smart contract deployment..."

# Change to writable directory
cd /tmp

# Wait for geth-init to complete prefunding
echo "⏳ Waiting for geth-init to complete prefunding..."
until [ -f "/shared/geth-init-complete" ]; do
  echo "Waiting for geth-init-complete file..."
  sleep 1
done
echo "✅ Prefunding completed, proceeding with deployment..."

# Clone the repository
echo "📥 Cloning repository..."
REPO_NAME=$(basename "$ASSIGNMENT_1A_REPO" .git)
if [ -d "$REPO_NAME" ]; then
    echo "Repository already exists, pulling latest changes..."
    cd "$REPO_NAME"
    git pull origin main
else
    git clone "$ASSIGNMENT_1A_REPO.git"
    cd "$REPO_NAME"
fi

# Navigate to the 1a directory
cd "$ASSIGNMENT_1A_SUBDIR"

# Install dependencies
echo "📦 Installing dependencies..."
forge install

# Build the project
echo "🔨 Building project..."
forge build

# Deploy the contracts
echo "🚀 Deploying MiniAMM contracts..."
forge script "$FOUNDRY_SCRIPT" \
    --rpc-url "$ETH_RPC_URL" \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    --broadcast

# Extract contract addresses from broadcast logs
echo "📊 Extracting contract addresses..."
BROADCAST_DIR="broadcast/MiniAMM.s.sol/1337"
LATEST_RUN=$(find "$BROADCAST_DIR" -name "run-latest.json" | head -1)

if [ -f "$LATEST_RUN" ]; then
    echo "✅ Found deployment results: $LATEST_RUN"
    
    # Create deployment JSON (use /tmp first, then copy)
    mkdir -p /tmp/deployment
    mkdir -p /deployment_output
    
    # Extract contract addresses and names from transactions array
    echo "Debug: Parsing broadcast file..."
    echo "Debug: First few lines of broadcast file:"
    head -50 "$LATEST_RUN"
    
    # Use simpler extraction method
    cat "$LATEST_RUN" | tr ',' '\n' | grep '"contractAddress"' | cut -d'"' -f4 > /tmp/addresses.txt
    cat "$LATEST_RUN" | tr ',' '\n' | grep '"contractName"' | cut -d'"' -f4 > /tmp/names.txt
    
    echo "Debug: Found addresses:"
    cat /tmp/addresses.txt
    echo "Debug: Found names:"
    cat /tmp/names.txt
    
    # Create JSON output
    cat > /tmp/deployment/deployment.json << EOF
{
EOF

    # Add contract addresses
    ADDR1=$(sed -n '1p' /tmp/addresses.txt)
    ADDR2=$(sed -n '2p' /tmp/addresses.txt) 
    ADDR3=$(sed -n '3p' /tmp/addresses.txt)
    NAME1=$(sed -n '1p' /tmp/names.txt)
    NAME2=$(sed -n '2p' /tmp/names.txt)
    NAME3=$(sed -n '3p' /tmp/names.txt)

    cat >> /tmp/deployment/deployment.json << EOF
    "mock_erc_0": "$ADDR1",
    "mock_erc_1": "$ADDR2", 
    "mini_amm": "$ADDR3"
}
EOF

    # Copy to both locations
    cp /tmp/deployment/deployment.json /deployment_output/deployment.json
    # Try to copy to shared volume (may fail due to permissions)
    cp /tmp/deployment/deployment.json /shared/deployment/deployment.json 2>/dev/null || echo "Warning: Could not copy to /shared/deployment"
    
    echo "✅ Deployment JSON created at:"
    echo "   - /tmp/deployment/deployment.json (temporary)"
    echo "   - /deployment_output/deployment.json (for host access)"
    cat /tmp/deployment/deployment.json
else
    echo "❌ Could not find deployment results"
    exit 1
fi

echo "✅ Deployment completed successfully!"
