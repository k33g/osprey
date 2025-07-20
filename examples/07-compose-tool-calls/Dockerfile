FROM debian:stable-slim

ARG OSPREY_VERSION=${OSPREY_VERSION}

# Install dependencies and gum
RUN <<EOF
apt-get update
apt-get install -y curl gpg jq

mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" > /etc/apt/sources.list.d/charm.list
apt-get update
apt-get install -y gum
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Set working directory
WORKDIR /app

# Copy the main script
COPY main.sh /app/main.sh

# Download and install osprey.sh
RUN <<EOF
curl -fsSL https://github.com/k33g/osprey/releases/download/${OSPREY_VERSION}/osprey.sh -o ./osprey.sh
chmod +x ./osprey.sh
chmod +x /app/main.sh
EOF

# Start the main script
CMD ["bash", "/app/main.sh"]