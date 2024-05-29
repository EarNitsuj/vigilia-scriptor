#!/bin/bash

# Install curl, git, and openssl
sudo apt-get install --yes curl git openssl && \
echo -e "Install curl, git, and openss \n\n"  && \

# Download Docker installation script
curl -fsSL get.docker.com -o ${HOME}/get-docker.sh && \
echo -e "Download Docker installation script \n\n"  && \

# Execute Docker installation script
sudo sh ${HOME}/get-docker.sh && \
echo -e "Execute Docker installation script \n\n"  && \

# Set 2 minute sleep
sleep 100 && \
echo -e "Set 2 minute sleep \n\n"  && \

# Enable and start Docker service
sudo systemctl enable --now docker && \
echo -e "Enable and start Docker service \n\n"  && \

# Set 5 seconds sleep
sleep 5 && \
echo -e "Set 5 seconds sleep \n\n"  && \

# Add current user to the Docker group
sudo usermod -aG docker $(whoami) && \
echo -e "Add current user to the Docker group \n\n"  && \

# Set 10 seconds sleep
sleep 10 && \

# Switch to current user
sudo -i -u $(whoami) && \
echo -e "Switch to current user \n\n"  && \

# Set 5 seconds sleep
sleep 5 && \

clear
echo -e "Execute next script \n\n"  && \

# Set 5 seconds sleep
sleep 5 && \

./secundo.sh

