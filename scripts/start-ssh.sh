#!/bin/bash
echo "Starting SSH server for X11 forwarding..."

# Mount shared memory (needs SYS_ADMIN capability)
mount /dev/shm 2>/dev/null || echo "Could not mount /dev/shm (may need --cap-add=SYS_ADMIN)"

# Fix ownership after potential volume mounts
if [ -d "/app/image-data" ]; then
    chown -R squeak:squeak /app/image-data 2>/dev/null || true
fi

# Create SSH host keys if they don't exist
ssh-keygen -A

# Start SSH service
service ssh start

echo "SSH server started. Connect with:"
echo "ssh -X -p 2222 squeak@localhost"
echo ""

# Keep container running and show logs
tail -f /var/log/auth.log
