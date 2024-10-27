#!/bin/bash

#add color for text
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
plain='\033[0m'
NC='\033[0m' # No Color

cur_dir=$(pwd)
# check root
[[ $EUID -ne 0 ]] && echo -e "${RED}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

install_jq() {
    if ! command -v jq &> /dev/null; then
        # Check if the system is using apt package manager
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

loader(){
    install_jq
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    # Fetch server country using ip-api.com
    SERVER_COUNTRY=$(curl -sS "http://ip-api.com/json/$SERVER_IP" | jq -r '.country')
    # Fetch server isp using ip-api.com 
    SERVER_ISP=$(curl -sS "http://ip-api.com/json/$SERVER_IP" | jq -r '.isp')
    wellcome
}

install_speedtest(){
    sudo apt-get update && sudo apt-get install
    wget "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz"
    tar -zxvf ookla-speedtest-1.2.0-linux-x86_64.tgz
    cp speedtest /usr/bin
    sleep .5 
    speedtest
}

change_ssh_port(){
    echo ""
    echo -n "Please enter the port you would like SSH to run on > "
    while read SSHPORT; do
        if [[ "$SSHPORT" =~ ^[0-9]{2,5}$ || "$SSHPORT" = 22 ]]; then
            if [[ "$SSHPORT" -ge 1024 && "$SSHPORT" -le 65535 || "$SSHPORT" = 22 ]]; then
                # Create backup of current SSH config
                NOW=$(date +"%m_%d_%Y-%H_%M_%S")
                cp /etc/ssh/sshd_config /etc/ssh/sshd_config.inst.bckup.$NOW
                # Apply changes to sshd_config
                sed -i -e "/Port /c\Port $SSHPORT" /etc/ssh/sshd_config
                echo -e "Restarting SSH in 5 seconds. Please wait.\n"
                sleep 5
                # Restart SSH service
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

    echo ""    
}
setupFakeWebSite(){
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


wellcome(){

    clear
    echo "+------------------------------------+"
    echo "|         منوی ابزارهای سرور          |"
    echo "+------------------------------------+"
    echo -e "${GREEN}|Server Location:${NC} $SERVER_COUNTRY"
    echo -e "${GREEN}|Server IP:${NC} $SERVER_IP"
    echo -e "${GREEN}|Server ISP:${NC} $SERVER_ISP"
    echo "+---------------------------------------------------------------------------------------------------------------+"
    echo -e "${GREEN}|Please choose an option:${NC}"
    echo "+---------------------------------------------------------------------------------------------------------------+"
    echo -e "$YELLOW|"
    echo -e "${BLUE}| 1  - Install Speedtest.net"
    echo -e "${BLUE}| 2  - Install Monitoring"
    echo -e "${BLUE}| 3  - Install 3X-UI Panel"
    echo -e "${BLUE}| 4  - Set DNS Google"
    echo -e "${BLUE}| 5  - Set DNS Shecan "
    echo -e "${BLUE}| 6  - Fix WhatsApp datetime"
    echo -e "${BLUE}| 7  - Disable IPv6"
    echo -e "${BLUE}| 8  - Install BBR"
    echo -e "${BLUE}| 9  - Install Certbot"
    echo -e "${BLUE}| 10 - Install Namiun"
    echo -e "${BLUE}| 11 - Install WARP+"
    echo -e "${BLUE}| 12 - Speedtest ArvanCloud"
    echo -e "${BLUE}| 13 - Change SSH port"
    echo -e "${BLUE}| 14 - Auto SSL Marzban/X-UI (by @ErfJab)"
    echo -e "${BLUE}| 15 - Auto Backup Marzban/X-UI (by @AC_Lover)"
    echo -e "${BLUE}| 16 - Change Password SSH"
    echo -e "${BLUE}| 17 - Make Telegram Proxy (MTProto)"
    echo -e "${BLUE}| 18 - Update server and install dependences"
    echo -e "${BLUE}| 19 - Change source list IRAN"
    echo -e "${BLUE}| 20 - Install Marzban Panel"
    echo -e "${BLUE}| 21 - Disable/Enable Ping Response"
    echo -e "${BLUE}| 22 - List Port Usage"
    echo -e "${BLUE}| 23 - Block All SPEEDTEST Sites in X-UI"
    echo -e "${BLUE}| 24 - Install Nginx + Fake-WebSite Template [HTML]"
    echo -e "${BLUE}| 0  - Exit"
    echo -e "${BLUE}|"
    echo -e "${NC}+-------------------------------------------------------------------------------------------------------------+${NC}"

    read -p "Enter option number: " choice

    case $choice in
    1)
        install_speedtest
        ;;
    2)
        # htop
        # sudo apt install btop -y
        # btop
        # install from snap
        sudo apt-get install snapd
        sudo snap install btop
        ;;
    3)
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
        ;;
    4)
        cp /etc/resolv.conf /etc/resolv-backup.conf 
        rm -rf /etc/resolv.conf && touch /etc/resolv.conf && echo 'nameserver 8.8.8.8' >> /etc/resolv.conf && echo 'nameserver 8.8.4.4' >> /etc/resolv.conf

        echo "Google DNS Set."

        ;;
    5)
        cp /etc/resolv.conf /etc/resolv-backup.conf 
        rm -rf /etc/resolv.conf && touch /etc/resolv.conf && echo 'nameserver 178.22.122.100' >> /etc/resolv.conf && echo 'nameserver 185.51.200.2' >> /etc/resolv.conf

        echo "Shecan DNS Set."

        ;;
    6)
        sudo timedatectl set-timezone Asia/Tehran
        # sudo timedatectl set-timezone UTC
        echo "Time & Date Updated."

        ;;
    7)
        sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
        
        echo "IPv6 has been disabled"
        ;;
    8)
        wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && bash bbr.sh
        ;;
    9)
        apt install software-properties-common
        add-apt-repository ppa:certbot/certbot
        apt-get install certbot

        echo "Certbot Instaled."
        ;;
    10)
        curl https://raw.githubusercontent.com/malkemit/namizun/master/else/setup.sh | sudo bash
        ;;

    11)
        wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
        ;;

    12)
        bash <(curl -s https://raw.githubusercontent.com/arvancloud/support/main/bench.sh)
        ;;

    13)
        change_ssh_port
        ;;

    14)
        sudo bash -c "$(curl -sL https://github.com/erfjab/ESSL/raw/main/essl.sh)"
        ;;
    15)
        bash <(curl -Ls https://github.com/AC-Lover/backup/raw/main/backup.sh)
        ;;
    16)
        sudo passwd
        ;;
    17)
            echo "Please enter the following information:"
            read -p "Port number (default is 443): " port
            echo "for secret you you can use http://seriyps.ru/mtpgen.html "
            read -p "Secret key (should be a string of 32 hexadecimal characters): " secret_key
            echo "to get the server tag you should use telegram bot https://t.me/MTProxybot "
            read -p "Server tag (should be a string of 32 hexadecimal characters): " server_tag
            read -p "List of authentication methods - place empty for default - (should be a comma-separated list): " auth_methods
            read -p "MTProto domain (should be a valid domain name): " mtproto_domain
            port=${port:-443}
            auth_methods=${auth_methods:-"dd,-a tls"}
            curl -L -o mtp_install.sh https://git.io/fj5ru && \
            bash mtp_install.sh -p $port -s $secret_key -t $server_tag -a $auth_methods -d $mtproto_domain
            echo -e "Press ${RED}ENTER${NC} to continue"
            read -s -n 1
        ;;
    18)
            tput setaf 4
            echo "🟦 Updating the server..."
            apt update 
            while [ $(pgrep apt-get) -gt 0 ]; do
                sleep 1
            done

            echo "🟦 Upgrading all packages..."
            apt upgrade -y

            apt install zenity tput
            clear

            packages=$(dpkg -l | grep "^i ." | awk '{print $2}')

            tput setaf 2

            echo "🟦 Packages to install:"
            echo
            for package in $packages; do
                echo "   $package"
            done

            tput setaf 4

            echo "🟦 Installing packages..."

            for package in $packages; do
                apt install -y $package
            done

            tput setaf 2

            echo "🟩 Server update completed."

            echo "🟦 Returning to main menu..."

            clear
        ;;

    19)
            if ! command -v python3 &> /dev/null
            then
                echo "Python 3 not installed."
                sudo apt update
                sudo apt install -y python3
            fi
            wget https://raw.githubusercontent.com/dev-ir/assistant-vps/master/core/change-name-server.py
            python3 change-name-server.py

        ;;

    20)
        sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install
        marzban cli admin create --sudo
        ;;
    21)
        wget https://gist.githubusercontent.com/dev-ir/4ec5873cbff302d3b1e0d9e85a6e95c5/raw/282f8c89fcd259b3adb88f089c3a833c32e66932/icmp-manager.sh
        bash icmp-manager.sh
        ;;
    22)
        bash <(curl -Ls https://gist.githubusercontent.com/dev-ir/9e0d30603a7f9c50700c1d48a206af4d/raw/786d93cbdd79315c9acbc13cd47aa1523f33e944/list-port-usages)
        ;;
    23)
        bash <(curl -Ls https://raw.githubusercontent.com/dev-ir/speedtest-ban/master/main.sh)
        ;;
    24)
        setupFakeWebSite
        ;;
    0)
        echo -e "${GREEN}Exiting program...${NC}"
        exit 0
        ;;
    *)
        echo "Not valid"
        ;;
    esac

}

loader
