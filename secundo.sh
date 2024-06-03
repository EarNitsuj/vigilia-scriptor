#!/bin/bash

Yellow="\033[0;33m"
Color_Off="\033[0m"

clear; \

read -p "$(tput bold)Set DVPN and VPN Protocol ports within range (Y/N)? $(tput sgr0)" set_ports

if [[ "$set_ports" == "y" ]]; then
  read -p "$(tput bold)Enter the start of the port range: $(tput sgr0)" port_start
  
  while true; do
    read -p "$(tput bold)Enter the end of the port range: $(tput sgr0)" port_end
    if [[ "$port_end" -gt "$port_start" ]]; then
      break
    else
      echo "$(tput bold)Invalid end port. The end port must be greater than the start port. Please try again.$(tput sgr0)"
    fi
  done
  
  simple_dvpn_port=$(shuf -i "$port_start"-"$port_end" -n 1)
  while true; do
    simple_protocol_port=$(shuf -i "$port_start"-"$port_end" -n 1)
    if [[ "$simple_protocol_port" -ne "$simple_dvpn_port" ]]; then
      break
    fi
  done

else
  echo "No ports set."
fi

# Ask for the moniker (node name)
read -p "$(tput bold)Please enter your name of the node: $(tput sgr0)" node_name

# Check if the node name is not empty
if [[ -n "$node_name" ]]; then

    # Pull Sentinel latest image
    docker pull ghcr.io/sentinel-official/dvpn-node:latest && \
    
    # Tag the image
    docker tag ghcr.io/sentinel-official/dvpn-node:latest sentinel-dvpn-node && \
    
    # Get public IP
    public_ip=$(curl -s ipv4.icanhazip.com) && \
    
    # Get country code base on the IP
    country_code=$(curl -s http://ip-api.com/json/$(curl -s ipv4.icanhazip.com) | python3 -c "import sys, json; print(json.load(sys.stdin)['countryCode'])") && \
    
    # Get region name base on the IP
    region_name=$(curl -s http://ip-api.com/json/$(curl -s ipv4.icanhazip.com) | python3 -c "import sys, json; print(json.load(sys.stdin)['regionName'])") && \
    
    # Get city base on the IP
    city=$(curl -s http://ip-api.com/json/$(curl -s ipv4.icanhazip.com) | python3 -c "import sys, json; print(json.load(sys.stdin)['city'])") && \
    
    # Get continent code base on the IP
    vps_location=$(curl -s http://ip-api.com/json/$(curl -s ipv4.icanhazip.com)?fields=continentCode | python3 -c "import sys, json; print(json.load(sys.stdin)['continentCode'])") && \
    
    # Convert to uppercase to handle case insensitivity
    vps_location=${vps_location^^} && \
    
    # Create a self-signed TLS certificate
    openssl req -new \
        -newkey ec \
        -pkeyopt ec_paramgen_curve:prime256v1 \
        -x509 \
        -sha256 \
        -days 365 \
        -nodes \
        -out ${HOME}/tls.crt \
        -keyout ${HOME}/tls.key \
        -subj "/C=$country_code/ST=$region_name/L=$city/O=NA/OU=./CN=." && \
    
    # Initialize the application configuration (the below command creates and populate config.toml file)
    sudo docker run --rm \
        --volume ${HOME}/.sentinelnode:/root/.sentinelnode \
        sentinel-dvpn-node process config init && \
    
    if [[ "$set_ports" == "y" ]]; then
        # Set simple_dvpn_port as the dvpn_port
        dvpn_port=$simple_dvpn_port
    else
        # Get DVPN default port
        dvpn_port=$(python3 -c 'import toml; config = toml.load(open("'"$HOME"'/.sentinelnode/config.toml")); listen_on = config["node"]["listen_on"]; print(listen_on.split(":")[1])')
    fi
    
    # Delete config.toml
    sudo rm ~/.sentinelnode/config.toml && \
    
    # Download pre-filled config.toml from GitHub
    if [ "$vps_location" = "NA" ]; then
        curl -o ~/.sentinelnode/config.toml https://raw.githubusercontent.com/EarNitsuj/sentinel-us-config/main/config.toml && \
        echo "US configuration downloaded successfully."
    elif [ "$vps_location" = "EU" ]; then
        curl -o ~/.sentinelnode/config.toml https://raw.githubusercontent.com/EarNitsuj/sentinel-eu-config/main/config.toml && \
        echo "EU configuration downloaded successfully."
    else
        curl -o ~/.sentinelnode/config.toml https://raw.githubusercontent.com/EarNitsuj/sentinel-eu-config/main/config.toml && \
        echo "Invalid location. EU configuration downloaded instead."
    fi
    
    # Update config.toml values
    sed -i "s/\${listen_on}/\"0.0.0.0:$dvpn_port\"/; s/\${public_ip_with_port}/\"https:\/\/$public_ip:$dvpn_port\"/; s/\${node}/\"$node_name\"/" ~/.sentinelnode/config.toml && \
    
    # Initialize the V2Ray configuration
    sudo docker run --rm \
        --volume ${HOME}/.sentinelnode:/root/.sentinelnode \
        sentinel-dvpn-node process v2ray config init && \

    if [[ "$set_ports" == "y" ]]; then
        sed -i "s/\(listen_port\s*=\s*\).*/\1$simple_protocol_port/" ~/.sentinelnode/v2ray.toml && \
        sleep 3
    else
        # Do nothing
    fi
    
    # Get Protocol's (V2Ray) port
    protocol_port=$(python3 -c 'import toml; config = toml.load(open("'"$HOME"'/.sentinelnode/v2ray.toml")); print(config["vmess"]["listen_port"])') && \
    
    # Add an account key (the one in config.toml file)
    echo -e "welcometomynode\nwelcometomynode" | docker run --rm \
        --interactive \
        --volume ${HOME}/.sentinelnode:/root/.sentinelnode \
        sentinel-dvpn-node process keys add && \
    
    # Display all saved information
    echo -e "\n\n"
    echo -e "$(tput bold)Node name (moniker):$(tput sgr0) $node_name"
    echo -e "$(tput bold)Public IP address:$(tput sgr0) $public_ip"
    echo -e "$(tput bold)Node location:$(tput sgr0) $vps_location"
    echo -e "$(tput bold)Country code:$(tput sgr0) $country_code"
    echo -e "$(tput bold)Region/State:$(tput sgr0) $region_name"
    echo -e "$(tput bold)Locality/City:$(tput sgr0) $city"
    echo -e "$(tput bold)DVPN port (TCP):$(tput sgr0) ${Yellow}$dvpn_port${Color_Off}"
    echo -e "$(tput bold)V2Ray port (TCP):$(tput sgr0) ${Yellow}$protocol_port${Color_Off}"  && \
    
    # Prompt the user
    read -p "\n\n$(tput bold)Proceed with next step (Y/N)? $(tput sgr0)" answer
    
    # Check the user's response
    if [[ $answer = [Yy] ]]; then
        # Execute the script if the user answers 'Y' or 'y'
        ./tertius.sh
    else
        # Do nothing if the user answers anything else
        echo "Exiting without action."
    fi
    
else
    echo "No node name provided, exiting."
fi
