$saved_protocol=$(python3 -c 'import toml; config = toml.load(open("'"$HOME"'/.sentinelnode/config.toml")); protocol_type = config["node"]["type"]; print(protocol_type)')

if [ "$saved_protocol" = "wireguard" ]; then
    echo "is wireguard"
else
    echo "No node name provided, exiting."
fi
