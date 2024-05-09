sudo apt-get install --yes curl git openssl && \
curl -fsSL get.docker.com -o ${HOME}/get-docker.sh
sudo sh ${HOME}/get-docker.sh && \
sudo systemctl enable --now docker
sudo usermod -aG docker $(whoami)
sudo -i -u $(whoami) -- /path/to/post_login_commands.sh
