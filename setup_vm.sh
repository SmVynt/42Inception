#!/bin/bash
set -eu

CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_R="\033[31m"
CLR_B="\033[34m"
CLR_RESET="\033[0m"

USER_NAME="$(id -un)"
DOMAIN_NAME="${USER_NAME}.42.fr"

if [ "$USER_NAME" = "root" ]; then
	echo -e "${CLR_R}Don't run this as root. Run as your normal user (with sudo access).${CLR_RESET}"
	exit 1
fi

echo -e "${CLR_B}=== Inception VM Setup for ${USER_NAME} ===${CLR_RESET}"

# Docker and dependencies
echo -e "${CLR_B}Checking dependencies...${CLR_RESET}"
sudo apt-get update -qq
sudo apt-get install -y -qq docker.io git make curl > /dev/null
if apt-cache show docker-compose-v2 > /dev/null 2>&1; then
	sudo apt-get install -y -qq docker-compose-v2 > /dev/null
fi
sudo usermod -aG docker "$USER_NAME"
echo -e "${CLR_G}Docker installed.${CLR_RESET}"
echo -e "${CLR_Y}Log out and back in (or reboot) so the docker group applies.${CLR_RESET}"
echo ""

# Setup ssh access
echo -e "${CLR_B}Setting up SSH access...${CLR_RESET}"
sudo apt-get install -y -qq openssh-server > /dev/null
sudo systemctl enable ssh
sudo systemctl start ssh
echo -e "${CLR_G}SSH access setup complete.${CLR_RESET}"
echo ""

# Setup Firewall access for FTP
echo -e "${CLR_B}Setting up Firewall access for FTP...${CLR_RESET}"
sudo ufw allow 21/tcp
sudo ufw allow 21100:21110/tcp
echo -e "${CLR_G}Firewall access for FTP setup complete.${CLR_RESET}"
echo ""

# Show instructions
echo -e "${CLR_B}What to do next?${CLR_RESET}"
echo -e "${CLR_Y}Setup the VM access:${CLR_RESET}"
echo -e "  ${CLR_Y}1.${CLR_RESET} Port forwarding:  Host 3022 → Guest 22 (SSH)"
echo -e "  ${CLR_Y}2.${CLR_RESET} Port forwarding:  Host 443 → Guest 443 (HTTPS)"
echo -e "${CLR_Y}Access the VM using your SSH key: ssh -p 3022 ${USER_NAME}@127.0.0.1$ if you want${CLR_RESET}"
echo -e "${CLR_Y}run ${CLR_B}make init-secrets${CLR_RESET} to initialize the secrets${CLR_RESET}"
echo -e "${CLR_Y}run ${CLR_B}make up${CLR_RESET} to start the project${CLR_RESET}"


# Show how to run the project
echo -e "${CLR_Y}How to run the project?${CLR_RESET}"
echo -e "${CLR_B}In the Inception repo:${CLR_RESET} ${CLR_Y}make${CLR_RESET} (creates dirs; runs ${CLR_Y}init-secrets${CLR_RESET} if no ${CLR_Y}srcs/.env${CLR_RESET}), fill secrets, then:"
echo -e "${CLR_B}make up${CLR_Y} to start the project${CLR_RESET}"
echo -e "${CLR_B}make down${CLR_Y} to stop the project${CLR_RESET}"
echo -e "${CLR_B}make clean${CLR_Y} to clean the project${CLR_RESET}"
echo -e "${CLR_B}make fclean${CLR_Y} to clean the project and remove the secrets${CLR_RESET}"
echo -e "${CLR_B}make rebuild${CLR_Y} to rebuild the project from scratch${CLR_RESET}"
echo -e "${CLR_B}make ps${CLR_Y} to list containers (this project + any others on the host)${CLR_RESET}"
