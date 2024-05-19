#!/bin/bash

# Install curl, git, and openssl
sudo apt-get install --yes curl git openssl && \

# Download Docker installation script
curl -fsSL get.docker.com -o ${HOME}/get-docker.sh && \

# Execute Docker installation script
sudo sh ${HOME}/get-docker.sh && \

# Enable and start Docker service
sudo systemctl enable --now docker && \

# Add current user to the Docker group
sudo usermod -aG docker $(whoami) && \

# Switch to current user
sudo -i -u $(whoami) && \

# Sleep for 2 minutes to allow any background processes to complete
sleep 120 && \

# Run secundo.sh script as the current user
./secundo.sh

