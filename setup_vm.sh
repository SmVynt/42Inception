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
sudo apt-get install -y -qq docker.io git make curl ufw > /dev/null
if apt-cache show docker-compose-plugin > /dev/null 2>&1; then
	sudo apt-get install -y -qq docker-compose-plugin > /dev/null
elif apt-cache show docker-compose-v2 > /dev/null 2>&1; then
	sudo apt-get install -y -qq docker-compose-v2 > /dev/null
elif apt-cache show docker-compose > /dev/null 2>&1; then
	sudo apt-get install -y -qq docker-compose > /dev/null
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
if command -v ufw > /dev/null 2>&1; then
	sudo ufw allow 21/tcp
	sudo ufw allow 21100/tcp
	echo -e "${CLR_G}Firewall access for FTP setup complete.${CLR_RESET}"
else
	echo -e "${CLR_Y}ufw is not available; skipping firewall rule setup.${CLR_RESET}"
fi
echo ""

# Setup /etc/hosts for local GUI browser access from inside VM
echo -e "${CLR_B}Setting up /etc/hosts entries...${CLR_RESET}"
VM_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [ -n "${VM_IP}" ]; then
	HOSTS_TMP="$(mktemp)"
	awk '!/# inception-auto-hosts$/' /etc/hosts > "${HOSTS_TMP}"
	{
		echo "${VM_IP} ${DOMAIN_NAME} www.${DOMAIN_NAME} # inception-auto-hosts"
		echo "${VM_IP} adminer.${DOMAIN_NAME} # inception-auto-hosts"
		echo "${VM_IP} web.${DOMAIN_NAME} # inception-auto-hosts"
		echo "${VM_IP} portainer.${DOMAIN_NAME} # inception-auto-hosts"
	} >> "${HOSTS_TMP}"
	sudo cp "${HOSTS_TMP}" /etc/hosts
	rm -f "${HOSTS_TMP}"
	echo -e "${CLR_G}/etc/hosts updated for ${DOMAIN_NAME} subdomains (IP: ${VM_IP}).${CLR_RESET}"
else
	echo -e "${CLR_Y}Could not detect VM IP; skipping /etc/hosts update.${CLR_RESET}"
fi
echo ""


# Show how to run the project
echo -e "${CLR_Y}How to run the project?${CLR_RESET}"
echo -e "${CLR_B}In the Inception repo:${CLR_RESET} ${CLR_Y}make${CLR_RESET} (creates dirs; runs ${CLR_Y}init-secrets${CLR_RESET} if no ${CLR_Y}srcs/.env${CLR_RESET}), fill secrets, then:"
echo -e "${CLR_B}make up${CLR_Y} to start the project${CLR_RESET}"
echo -e "${CLR_B}make down${CLR_Y} to stop the project${CLR_RESET}"
echo -e "${CLR_B}make clean${CLR_Y} to clean the project${CLR_RESET}"
echo -e "${CLR_B}make fclean${CLR_Y} to clean the project and remove the secrets${CLR_RESET}"
echo -e "${CLR_B}make rebuild${CLR_Y} to rebuild the project from scratch${CLR_RESET}"
echo -e "${CLR_B}make ps${CLR_Y} to list containers (this project + any others on the host)${CLR_RESET}"
