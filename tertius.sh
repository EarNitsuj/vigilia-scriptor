# Move created TLS keys
sudo mv ${HOME}/tls.crt ${HOME}/.sentinelnode/tls.crt && \
sudo mv ${HOME}/tls.key ${HOME}/.sentinelnode/tls.key

sudo chown root:root ${HOME}/.sentinelnode/tls.crt && \
sudo chown root:root ${HOME}/.sentinelnode/tls.key

# Install screen
sudo apt-get install screen -y && \

screen -S dvpn -dm bash -c '
dvpn_port=$(python3 -c '\''import toml; config = toml.load(open("'"'"${HOME}/.sentinelnode/config.toml"'"'")); listen_on = config["node"]["listen_on"]; print(listen_on.split(":")[1])'\'') &&
protocol_port=$(python3 -c '\''import toml; config = toml.load(open("'"'"${HOME}/.sentinelnode/v2ray.toml"'"'")); print(config["vmess"]["listen_port"])'\'') &&
echo -e "\n\n\n\nV2Ray port is ($protocol_port) | DVPN port is ($dvpn_port)\n\n\n\n" &&
echo -e "welcometomynode" | docker run --sig-proxy=false \
--detach-keys="ctrl-q" \
--interactive \
--volume "${HOME}/.sentinelnode:/root/.sentinelnode" \
--publish $dvpn_port:$dvpn_port/tcp \
--publish $protocol_port:$protocol_port/tcp \
sentinel-dvpn-node process start; exec bash'

sleep 2 && \

screen -x dvpn
