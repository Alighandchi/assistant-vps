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

set_dns_cloudflare() {
    cp /etc/resolv.conf /etc/resolv-backup.conf
    rm -rf /etc/resolv.conf && touch /etc/resolv.conf
    echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
    echo 'nameserver 1.0.0.1' >> /etc/resolv.conf
    echo 'nameserver 2606:4700:4700::1111' >> /etc/resolv.conf
    echo 'nameserver 2606:4700:4700::1001' >> /etc/resolv.conf
    echo "Cloudflare DNS has been set."
}

set_dns_google() {
    cp /etc/resolv.conf /etc/resolv-backup.conf
    rm -rf /etc/resolv.conf && touch /etc/resolv.conf
    echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
    echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
    echo 'nameserver 2001:4860:4860::8888' >> /etc/resolv.conf
    echo 'nameserver 2001:4860:4860::8844' >> /etc/resolv.conf
    echo "Google DNS has been set."
}

update_upgrade_server() {
    echo "Updating and upgrading the server..."
    sudo apt-get update
    sudo apt-get upgrade -y
    echo "Server updated and upgraded successfully."
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

install_bbr() {
    echo "Installing BBR..."
    curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
    echo "BBR installed successfully."
}

install_3x_ui() {
    echo "Installing 3X-UI Panel..."
    rm x-ui_installer.sh
    wget https://gist.githubusercontent.com/dev-ir/aef266871ca3945a662bd92bbf49b3ae/raw/d7b9ba940ac338c0e5816a84062de343c3eab742/x-ui_installer.sh
    bash x-ui_installer.sh
    echo "3X-UI Panel installed successfully."
}

install_certbot_ssl() {
    echo "Installing Certbot SSL..."
    read -p "Please enter your domain name (e.g., dns.fastspeed.cfd): " DOMAIN_NAME
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:certbot/certbot -y
    sudo apt-get install certbot -y
    sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email imobotech.bot@gmail.com -d "$DOMAIN_NAME"
    echo "Certbot SSL installed successfully for domain: $DOMAIN_NAME"
}

menu() {
    clear
    echo "+--------------------------------------------------------------------------------------------------------------+"
    echo "|   ##     ####    ####    ####   ####   ######    ##     ##  ##   ######        ##  ##   #####    ####        |"
    echo "|  ####   ##  ##  ##  ##    ##   ##   ##    ##     ####    ### ##     ##          ##  ##   ##  ##  ##  ##       |"
    echo "| ##  ##  ##      ##        ##   ##        ##    ##  ##   ######     ##          ##  ##   # #  ##  ##           |"
    echo "| ######   ####    ####     ##    ####     ##    ######   ######     ##   #####  ##  ##   #####    ####        |"
    echo "| ##  ##      ##      # #    ##       ##    ##    ##  ##   ## ###     ##          ##  ##   ##          ##       |"
    echo "| ##  ##  ##  ##  ##  ##    ##   ##  ##    ##    ##  ##   ##  ##     ##            ####    ##      ##  ## (1.0) |"
    echo "| ##  ##   ####    ####    ####   ####     ##    ##  ##   ##  ##     ##            ##     ##       ####        |"
    echo "+--------------------------------------------------------------------------------------------------------------+"
    echo -e "|  GitHub : ${YELLOW}github.com/Alighandchi ${NC} |   Version : ${GREEN} 1.0${NC} "
    echo "+--------------------------------------------------------------------------------------------------------------+"
    echo -e "${GREEN}|Server Location:${NC} $SERVER_COUNTRY"
    echo -e "${GREEN}|Server IP:${NC} $SERVER_IP"
    echo -e "${GREEN}|Server ISP:${NC} $SERVER_ISP"
    echo "+---------------------------------------------------------------------------------------------------------------+"
    echo -e "${YELLOW}"
    echo -e "  ------- ${GREEN}DNS Management${YELLOW} ------- "
    echo "|"
    echo -e "|  1  - Set DNS Cloudflare"
    echo -e "|  2  - Set DNS Google"
    echo "|"
    echo -e "  ------- ${GREEN}System Management${YELLOW} ------- "
    echo "|"
    echo -e "|  3  - Update & Upgrade Server"
    echo -e "|  4  - Change SSH Port"
    echo -e "|  5  - Install BBR"
    echo "|"
    echo -e "  ------- ${GREEN}VPN Panels${YELLOW} ------- "
    echo "|"
    echo -e "|  6  - Install 3X-UI Panels"
    echo "|"
    echo -e "  ------- ${GREEN}SSL Management${YELLOW} ------- "
    echo "|"
    echo -e "|  7  - Install Certbot SSL"
    echo "|"
    echo -e "  ------- ${GREEN}Exit${YELLOW} ------- "
    echo "|"
    echo -e "|  0  - Exit"
    echo ""
    echo -e "${NC}+-------------------------------------------------------------------------------------------------------------+${NC}"

    read -p "Please choose an option: " choice

    case $choice in
        1) set_dns_cloudflare ;;
        2) set_dns_google ;;
        3) update_upgrade_server ;;
        4) change_ssh_port ;;
        5) install_bbr ;;
        6) install_3x_ui ;;
        7) install_certbot_ssl ;;
        0)
            echo -e "${GREEN}Exiting program...${NC}"
            exit 0
        ;;
        *)
            echo "Invalid option. Please try again."
            sleep 2
            menu
        ;;
    esac
}

loader
menu
