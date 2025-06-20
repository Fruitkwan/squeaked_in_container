# Dockerfile for Squeak Smalltalk with SSH X11 forwarding and VNC support
# Multi-platform support: ARM64 (Apple Silicon) and AMD64 (Intel/AMD)
FROM ubuntu:22.04

# Build arguments
ARG SSH_KEY
ARG SSH_USER=squeak

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies with retry logic
RUN apt-get clean && apt-get update --fix-missing && apt-get install -y --fix-missing --no-install-recommends \
    # Core system packages
    uuid-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgl1-mesa-dev \
    libgl1-mesa-dri \
    libssl-dev \
    libevdev-dev \
    libpulse-dev \
    git \
    gcc \
    make \
    wget \
    unzip \
    # SSH and X11 forwarding
    openssh-server \
    x11-apps \
    x11-xserver-utils \
    x11-utils \
    xauth \
    # X11 and OpenGL dependencies
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    libfontconfig1 \
    libasound2 \
    libglu1-mesa \
    mesa-utils \
    # VNC and virtual display
    xorg \
    openbox \
    x11vnc \
    tigervnc-standalone-server \
    xvfb \
    supervisor \
    # System utilities
    acl \
    curl \
    iputils-ping \
    file \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Download and install the latest OpenSmalltalk VM (platform-aware)
RUN mkdir -p /opt/opensmalltalk-vm && \
    cd /opt/opensmalltalk-vm && \
    # Detect platform and download appropriate VM
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        echo "Downloading ARM64 VM for Apple Silicon/ARM64" && \
        wget -q -O vm.tar.gz "https://github.com/OpenSmalltalk/opensmalltalk-vm/releases/download/202312181441/squeak.cog.spur_linux64ARMv8.tar.gz" && \
        tar -xzf vm.tar.gz && \
        chmod +x sqcogspur64ARMv8linuxht/squeak && \
        chmod +x sqcogspur64ARMv8linuxht/bin/spur64 && \
        ln -sf /opt/opensmalltalk-vm/sqcogspur64ARMv8linuxht/squeak /usr/local/bin/opensmalltalk-squeak; \
    elif [ "$ARCH" = "x86_64" ]; then \
        echo "Downloading x86_64 VM for Intel/AMD64" && \
        wget -q -O vm.tar.gz "https://github.com/OpenSmalltalk/opensmalltalk-vm/releases/download/202312181441/squeak.cog.spur_linux64x64.tar.gz" && \
        tar -xzf vm.tar.gz && \
        chmod +x sqcogspur64linuxht/squeak && \
        chmod +x sqcogspur64linuxht/bin/spur64 && \
        ln -sf /opt/opensmalltalk-vm/sqcogspur64linuxht/squeak /usr/local/bin/opensmalltalk-squeak; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    rm -f vm.tar.gz

# Note: We only use the bundled VM in sqcogspur64linuxht directory

# Set up non-root user for SSH and VNC
RUN adduser --disabled-password --gecos '' "${SSH_USER}"

# Set up VNC directory (password will be set at runtime)
RUN mkdir -p /home/${SSH_USER}/.vnc && \
    chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.vnc

# Configure SSH for X11 forwarding
RUN echo 'X11UseLocalhost no' >> /etc/ssh/sshd_config && \
    echo 'X11Forwarding yes' >> /etc/ssh/sshd_config && \
    echo 'X11DisplayOffset 10' >> /etc/ssh/sshd_config && \
    mkdir -p /etc/ssh/authorized_keys

# Add SSH key if provided
RUN if [ -n "${SSH_KEY}" ]; then \
        echo "${SSH_KEY}" >> "/etc/ssh/authorized_keys/${SSH_USER}"; \
        echo "AuthorizedKeysFile /etc/ssh/authorized_keys/%u" >> /etc/ssh/sshd_config; \
    fi

# Set up working directory
WORKDIR /app

# Copy your Squeak files
COPY . .

# Set proper permissions for all users
RUN chmod +x sqcogspur64linuxht/squeak 2>/dev/null || true && \
    chmod +x squeak.cog.spur_linux64ARMv8_202409260320/bin/squeak 2>/dev/null || true && \
    chmod 644 ./*.image ./*.changes ./*.dlcx SqueakV50.sources 2>/dev/null || true

# Give SSH user access to app directory
RUN chown -R ${SSH_USER}:${SSH_USER} /app && \
    setfacl -Rm u:"${SSH_USER}":rwx /app

# Enable shared memory for COG JIT
RUN chmod 777 /dev/shm && \
    echo "none /dev/shm tmpfs rw,nosuid,nodev 0 0" >> /etc/fstab

# Configure heartbeat thread priority for better VM performance
RUN echo "*      hard    rtprio  2" >> /etc/security/limits.d/squeak.conf && \
    echo "*      soft    rtprio  2" >> /etc/security/limits.d/squeak.conf

# Set display environment variable (for direct execution)
ENV DISPLAY=:0

# Expose SSH, VNC and application ports
EXPOSE 22 5900 8088

# Copy startup scripts
COPY scripts/start-squeak.sh /app/start-squeak.sh
COPY scripts/start-ssh.sh /app/start-ssh.sh
COPY scripts/start-vnc.sh /app/start-vnc.sh

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /app/start-squeak.sh /app/start-ssh.sh /app/start-vnc.sh

# Create aliases for compatibility
RUN ln -s /app/start-squeak.sh /app/start-gui.sh

# Default command (can be overridden)
CMD ["/app/start-squeak.sh"]
