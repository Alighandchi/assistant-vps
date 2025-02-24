#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
plain='\033[0m'
NC='\033[0m'

# Check if the script is run as root
[[ $EUID -ne 0 ]] && echo -e "${RED}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

install_jq() {
    if ! command -v jq &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            echo -e "${RED}jq is not installed. Installing...${NC}"
            sleep 1
            sudo apt-get update
            sudo apt-get install -y jq
        else
            echo -e "${RED}Error: Unsupported package manager. Please install jq manually.${NC}\n"
            read -p "Press any key to continue..."
            exit 1
        fi
    fi
}

loader() {
    install_jq
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    # Fetch server country using ip-api.com
    SERVER_COUNTRY=$(curl -sS "http://ip-api.com/json/$SERVER_IP" | jq -r '.country')
    # Fetch server ISP using ip-api.com
    SERVER_ISP=$(curl -sS "http://ip-api.com/json/$SERVER_IP" | jq -r '.isp')
}

install_speedtest() {
    sudo apt-get update && sudo apt-get install -y wget
    wget "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz"
    tar -zxvf ookla-speedtest-1.2.0-linux-x86_64.tgz
    cp speedtest /usr/bin
    sleep .5
    speedtest
}

change_ssh_port() {
    echo ""
    echo -n "Please enter the port you would like SSH to run on > "
    while read SSHPORT; do
        if [[ "$SSHPORT" =~ ^[0-9]{2,5}$ || "$SSHPORT" = 22 ]]; then
            if [[ "$SSHPORT" -ge 1024 && "$SSHPORT" -le 65535 || "$SSHPORT" = 22 ]]; then
                NOW=$(date +"%m_%d_%Y-%H_%M_%S")
                cp /etc/ssh/sshd_config /etc/ssh/sshd_config.inst.bckup.$NOW
                sed -i -e "/Port /c\Port $SSHPORT" /etc/ssh/sshd_config
                echo -e "Restarting SSH in 5 seconds. Please wait.\n"
                sleep 5
                service sshd restart
                echo ""
                echo -e "The SSH port has been changed to $SSHPORT. Please login using that port to test BEFORE ending this session.\n"
                exit 0
            else
                echo -e "Invalid port: must be 22, or between 1024 and 65535."
                echo -n "Please enter the port you would like SSH to run on > "
            fi
        else
            echo -e "Invalid port: must be numeric!"
            echo -n "Please enter the port you would like SSH to run on > "
        fi
    done
}

setupFakeWebSite() {
    sudo apt-get update
    sudo apt-get install unzip -y

    if ! command -v nginx &> /dev/null; then
        echo "The Nginx software is not installed; the installation process has started."
        if sudo apt-get install -y nginx; then
            echo "Nginx was successfully installed."
        else
            echo "An error occurred during the Nginx installation process." >&2
            exit 1
        fi
    else
        echo "The Nginx software was already installed."
    fi

    cd /root || { echo "Failed to change directory to /root"; exit 1; }

    if [[ -d "website-templates-master" ]]; then
        echo "Removing existing 'website-templates-master' directory..."
        rm -rf website-templates-master
    fi

    wget https://github.com/learning-zone/website-templates/archive/refs/heads/master.zip
    unzip master.zip
    rm master.zip
    cd website-templates-master || { echo "Failed to change directory to randomfakehtml-master"; exit 1; }
    rm -rf assets
    rm ".gitattributes" "README.md" "_config.yml"

    randomTemplate=$(a=(*); echo ${a[$((RANDOM % ${#a[@]}))]} 2>&1)
    if [[ -n "$randomTemplate" ]]; then
        echo "Random template name: ${randomTemplate}"
    else
        echo "No directories found to choose from."
        exit 1
    fi

    if [[ -d "${randomTemplate}" && -d "/var/www/html/" ]]; then
        sudo rm -rf /var/www/html/*
        sudo cp -a "${randomTemplate}/." /var/www/html/
        echo "Template extracted successfully!"
    else
        echo "Extraction error!"
    fi
}

# Load initial data
loader

# Execute functions based on your requirements
# Uncomment the function you want to run
# install_speedtest
# change_ssh_port
# setupFakeWebSite
