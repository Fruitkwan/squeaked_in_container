#!/bin/bash

# KestrelView Setup Script
set -e

echo "🚀 KestrelView Squeak Setup"
echo "=========================="

# Check if SSH key exists
SSH_KEY_PATH="$HOME/.ssh/kestrel_rsa"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "📝 Generating SSH key for KestrelView..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "kestrelview@docker"
    echo "✅ SSH key generated: $SSH_KEY_PATH"
else
    echo "✅ SSH key already exists: $SSH_KEY_PATH"
fi

# Export public key for docker-compose
export SSH_PUBLIC_KEY=$(cat "${SSH_KEY_PATH}.pub")
echo "📋 Using SSH public key: ${SSH_PUBLIC_KEY:0:50}..."

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Detected macOS"
    PLATFORM="macos"
    
    # Check for XQuartz
    if ! command -v xquartz &> /dev/null && ! ls /Applications/Utilities/XQuartz.app &> /dev/null 2>&1; then
        echo "⚠️  XQuartz not found. Install from: https://www.xquartz.org/"
        echo "   (Required for X11 forwarding)"
    else
        echo "✅ XQuartz detected"
    fi
else
    echo "🐧 Detected Linux"
    PLATFORM="linux"
fi

# Build the image
echo "🔨 Building KestrelView Docker image..."

# Create scripts directory
mkdir -p scripts

# Create start-squeak.sh script
cat > scripts/start-squeak.sh << 'EOF'
#!/bin/bash
echo "Starting KestrelView Squeak Application..."

# Mount shared memory for COG JIT
mount /dev/shm 2>/dev/null || echo "Shared memory already mounted"

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Find the first .image file
IMAGE_FILE=$(ls *.image | head -n 1)
if [ -z "$IMAGE_FILE" ]; then
    echo "ERROR: No .image file found"
    ls -la
    exit 1
fi

echo "Using image file: $IMAGE_FILE"

# Choose appropriate VM based on architecture
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo "Using ARM64 Squeak VM"
    
    # Use system VM (should work on ARM64)
    if command -v squeak >/dev/null 2>&1; then
        echo "Using system Squeak VM"
        exec squeak "$IMAGE_FILE"
    else
        echo "ERROR: No Squeak VM found. Install squeak-vm package."
        exit 1
    fi
else
    echo "Using x86_64 Squeak VM"
    if [ -f "./sqcogspur64linuxht/squeak" ]; then
        exec ./sqcogspur64linuxht/squeak "$IMAGE_FILE"
    elif command -v squeak >/dev/null 2>&1; then
        echo "Falling back to system Squeak VM"
        exec squeak "$IMAGE_FILE"
    else
        echo "ERROR: No x86_64 Squeak VM found"
        exit 1
    fi
fi
EOF

# Create start-ssh.sh script
cat > scripts/start-ssh.sh << 'EOF'
#!/bin/bash
# Mount shared memory (needs SYS_ADMIN capability)
mount /dev/shm 2>/dev/null || echo "Could not mount /dev/shm (may need --cap-add=SYS_ADMIN)"

# Fix ownership after potential volume mounts
if [ -d "/image" ]; then
    chown -R squeak /image 2>/dev/null || true
fi

# Start SSH service
service ssh start

# Keep container running
exec /bin/bash
EOF

chmod +x scripts/start-squeak.sh scripts/start-ssh.sh

docker build \
    --build-arg SSH_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_USER=squeak \
    -t kestrelview-ssh .

echo "✅ Build complete!"

# Provide usage instructions
echo ""
echo "🎯 Choose your connection method:"
echo ""

echo "1️⃣  SSH X11 Forwarding (Recommended):"
echo "   docker run -d --name kestrel-ssh --cap-add=SYS_ADMIN -p 2222:22 -p 8088:8088 kestrelview-ssh /app/start-ssh.sh"
echo "   ssh -X -i $SSH_KEY_PATH -p 2222 squeak@localhost"
echo "   ./start-squeak.sh"
echo ""

echo "2️⃣  Docker Compose (Easy):"
echo "   export SSH_PUBLIC_KEY=\"$SSH_PUBLIC_KEY\""
echo "   docker-compose -f docker-compose.ssh.yml up -d kestrel-ssh"
echo "   ssh -X -i $SSH_KEY_PATH -p 2222 squeak@localhost"
echo ""

if [[ "$PLATFORM" == "macos" ]]; then
    echo "3️⃣  Direct X11 (macOS with XQuartz):"
    echo "   # Start XQuartz and allow network connections"
    echo "   export IP=\$(ifconfig en0 | grep inet | awk '\$1==\"inet\" {print \$2}')"
    echo "   xhost + \$IP"
    echo "   docker run --rm --cap-add=SYS_ADMIN -e DISPLAY=\$IP:0 -p 8088:8088 kestrelview-ssh"
    echo ""
fi

echo "4️⃣  VNC (Alternative - build Dockerfile.vnc separately):"
echo "   docker build -f Dockerfile.vnc -t kestrelview-vnc ."
echo "   docker run -p 5901:5901 kestrelview-vnc"
echo "   # Connect to vnc://localhost:5901"
echo ""

echo "🔍 Troubleshooting:"
echo "   # Check container status"
echo "   docker ps"
echo "   docker logs kestrel-ssh"
echo ""
echo "   # Test X11 forwarding"
echo "   ssh -X -i $SSH_KEY_PATH -p 2222 squeak@localhost 'xeyes'"
echo ""

echo "🎉 Setup complete! Choose a connection method above to start KestrelView."