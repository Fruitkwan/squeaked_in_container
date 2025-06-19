#!/bin/bash
echo "Starting KestrelView Squeak Application..."

# Set environment variables
export DISPLAY=${DISPLAY:-:1}
export USER=${USER:-root}
export HOME=${HOME:-/root}

echo "Environment: DISPLAY=$DISPLAY, USER=$USER, HOME=$HOME"

# Wait for X server to be ready
echo "Waiting for X server..."
for i in {1..30}; do
    if xdpyinfo -display $DISPLAY >/dev/null 2>&1; then
        echo "X server is ready"
        break
    fi
    echo "Waiting for X server... ($i/30)"
    sleep 1
done

# Mount shared memory for COG JIT (if running as root)
if [ "$(id -u)" -eq 0 ]; then
    mount /dev/shm 2>/dev/null || echo "Shared memory already mounted or not available"
fi

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Change to the correct directory
cd /app || cd .

# Find the specific image file or any .image file
IMAGE_FILE=""
if [ -f "TPR-KestrelView-DemoVersion-2023-07-15-64bit.image" ]; then
    IMAGE_FILE="TPR-KestrelView-DemoVersion-2023-07-15-64bit.image"
else
    IMAGE_FILE=$(find . -name "*.image" | head -n 1)
fi

if [ -z "$IMAGE_FILE" ]; then
    echo "ERROR: No .image file found"
    echo "Available files:"
    ls -la
    exit 1
fi

echo "Using image file: $IMAGE_FILE"

# Set Squeak VM options for GUI operation
SQUEAK_OPTS="-vm-display-X11 -vm-sound-null"

# Set library path for ARM64 Ubuntu compatibility
export PLATFORMLIBDIR="/usr/lib/aarch64-linux-gnu"
export LD_LIBRARY_PATH="/usr/lib/aarch64-linux-gnu:/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH"

# Try OpenSmalltalk VM first (ARM64 compatible)
if [ -f "/opt/opensmalltalk-vm/sqcogspur64ARMv8linuxht/lib/squeak/5.0-202312181441-64bit/squeak" ]; then
    echo "Using OpenSmalltalk VM binary directly (ARM64)"
    # Set the plugin path and library path for the OpenSmalltalk VM
    export SQUEAK_PLUGINS="/opt/opensmalltalk-vm/sqcogspur64ARMv8linuxht/lib/squeak/5.0-202312181441-64bit"
    export LD_LIBRARY_PATH="/opt/opensmalltalk-vm/sqcogspur64ARMv8linuxht/lib/squeak/5.0-202312181441-64bit:$LD_LIBRARY_PATH"
    exec /opt/opensmalltalk-vm/sqcogspur64ARMv8linuxht/lib/squeak/5.0-202312181441-64bit/squeak $SQUEAK_OPTS "$IMAGE_FILE"
elif [ -f "/opt/opensmalltalk-vm/sqcogspur64ARMv8linuxht/squeak" ]; then
    echo "Using OpenSmalltalk VM wrapper (ARM64)"
    # Set environment for the wrapper script
    export PLATFORMLIBDIR="/usr/lib/aarch64-linux-gnu"
    exec /opt/opensmalltalk-vm/sqcogspur64ARMv8linuxht/squeak $SQUEAK_OPTS "$IMAGE_FILE"
elif command -v opensmalltalk-squeak >/dev/null 2>&1; then
    echo "Using OpenSmalltalk VM symlink (ARM64)"
    exec opensmalltalk-squeak $SQUEAK_OPTS "$IMAGE_FILE"
else
    echo "ERROR: OpenSmalltalk VM not found"
    echo "The bundled VM (sqcogspur64linuxht) is x86-64 only and won't work on ARM64/Apple Silicon"
    echo "Available files:"
    ls -la /opt/opensmalltalk-vm/ 2>/dev/null || echo "OpenSmalltalk VM directory not found"
    ls -la /app/sqcogspur64linuxht/ 2>/dev/null || echo "Bundled VM directory not found"
    exit 1
fi
