#!/bin/bash

# Kill all screen sessions
pkill screen

# Stop and remove existing DVPN container
docker stop sentinel-dvpn-node
docker rm sentinel-dvpn-node

# Prompt the user
read -p "$(tput bold)With usual passphrase (Y/N)? $(tput sgr0)" answer

# Check the user's response
if [[ $answer = [Yy] ]]; then
    pass="welcometomynode"
else
    read -s -p "$(tput bold)Please enter passphrase: $(tput sgr0)" user_pass
    pass="$user_pass"
    echo # Add a newline for clean output after hidden input
fi

# Get config.toml protocol
saved_protocol=$(python3 -c 'import toml; config = toml.load(open("'"$HOME"'/.sentinelnode/config.toml")); protocol_type = config["node"]["type"]; print(protocol_type)')
echo -e "\n\n Protocol: $(tput bold)$saved_protocol$(tput sgr0) \n\n"

if [ "$saved_protocol" = "wireguard" ]; then
    screen -S dvpn -dm bash -c "
    dvpn_port=\$(python3 -c 'import toml; config = toml.load(open(\""${HOME}/.sentinelnode/config.toml"\")); listen_on = config[\"node\"][\"listen_on\"]; print(listen_on.split(\":\")[1])') &&
    protocol_port=\$(python3 -c 'import toml; config = toml.load(open(\""${HOME}/.sentinelnode/wireguard.toml"\")); print(config[\"listen_port\"])') &&
    echo -e \"\n\n\n\WireGuard port is (\$protocol_port) | DVPN port is (\$dvpn_port)\n\n\n\n\" &&
    echo -e \$pass | docker run --sig-proxy=false \
    --detach-keys='ctrl-q' \
    --interactive \
    --volume \"${HOME}/.sentinelnode:/root/.sentinelnode\" \
    --volume /lib/modules:/lib/modules \
    --cap-drop ALL \
    --cap-add NET_ADMIN \
    --cap-add NET_BIND_SERVICE \
    --cap-add NET_RAW \
    --cap-add SYS_MODULE \
    --sysctl net.ipv4.ip_forward=1 \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --sysctl net.ipv6.conf.all.forwarding=1 \
    --sysctl net.ipv6.conf.default.forwarding=1 \
    --publish \$dvpn_port:\$dvpn_port/tcp \
    --publish \$protocol_port:\$protocol_port/udp \
    sentinel-dvpn-node process start; exec bash"
else
    screen -S dvpn -dm bash -c "
    dvpn_port=\$(python3 -c 'import toml; config = toml.load(open(\""${HOME}/.sentinelnode/config.toml"\")); listen_on = config[\"node\"][\"listen_on\"]; print(listen_on.split(\":\")[1])') &&
    protocol_port=\$(python3 -c 'import toml; config = toml.load(open(\""${HOME}/.sentinelnode/v2ray.toml"\")); print(config[\"vmess\"][\"listen_port\"])') &&
    echo -e \"\n\n\n\nV2Ray port is (\$protocol_port) | DVPN port is (\$dvpn_port)\n\n\n\n\" &&
    echo -e \$pass | docker run --sig-proxy=false \
    --detach-keys='ctrl-q' \
    --interactive \
    --volume \"${HOME}/.sentinelnode:/root/.sentinelnode\" \
    --publish \$dvpn_port:\$dvpn_port/tcp \
    --publish \$protocol_port:\$protocol_port/tcp \
    sentinel-dvpn-node process start; exec bash"
fi

# Reattach to the screen session
sleep 2
screen -x dvpn
