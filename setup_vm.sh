#!/bin/bash
set -eu

CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_R="\033[31m"
CLR_RESET="\033[0m"

USER_NAME="$(id -un)"
DOMAIN_NAME="${USER_NAME}.42.fr"
REPO_URL="${1:-}"

if [ "$USER_NAME" = "root" ]; then
	echo -e "${CLR_R}Don't run this as root. Run as your normal user (with sudo access).${CLR_RESET}"
	exit 1
fi

echo -e "${CLR_Y}=== Inception VM Setup for ${USER_NAME} ===${CLR_RESET}"

# ── 1. System packages ──────────────────────────────────────────────
echo -e "${CLR_Y}[1/5] Installing Docker and dependencies...${CLR_RESET}"
sudo apt-get update -qq
sudo apt-get install -y -qq docker.io git make curl > /dev/null
if apt-cache show docker-compose-v2 > /dev/null 2>&1; then
	sudo apt-get install -y -qq docker-compose-v2 > /dev/null
fi
sudo usermod -aG docker "$USER_NAME"
echo -e "${CLR_G}Docker installed.${CLR_RESET}"

# ── 2. Host-only network (enp0s8) ───────────────────────────────────
echo -e "${CLR_Y}[2/5] Configuring host-only network...${CLR_RESET}"
if ip link show enp0s8 > /dev/null 2>&1; then
	if ! grep -q 'enp0s8' /etc/network/interfaces 2>/dev/null; then
		sudo tee -a /etc/network/interfaces > /dev/null <<-'EOF'

		auto enp0s8
		iface enp0s8 inet dhcp
		EOF
	fi
	sudo ip link set enp0s8 up
	sudo ip addr add 192.168.56.101/24 dev enp0s8 2>/dev/null || true
	HOSTONLY_IP="$(ip -4 addr show enp0s8 | grep -oP 'inet \K[\d.]+')"
	echo -e "${CLR_G}Host-only adapter up at ${HOSTONLY_IP}${CLR_RESET}"
else
	echo -e "${CLR_Y}No host-only adapter (enp0s8) found — skipping.${CLR_RESET}"
	echo -e "${CLR_Y}Add one in VirtualBox (Adapter 2 → Host-only) and rerun.${CLR_RESET}"
fi

# ── 3. /etc/hosts entry ─────────────────────────────────────────────
echo -e "${CLR_Y}[3/5] Adding ${DOMAIN_NAME} to /etc/hosts...${CLR_RESET}"
if ! grep -q "$DOMAIN_NAME" /etc/hosts; then
	echo "127.0.0.1 ${DOMAIN_NAME}" | sudo tee -a /etc/hosts > /dev/null
fi
echo -e "${CLR_G}${DOMAIN_NAME} → 127.0.0.1${CLR_RESET}"

# ── 4. Clone project ────────────────────────────────────────────────
PROJECT_DIR="/home/${USER_NAME}/inception"
echo -e "${CLR_Y}[4/5] Setting up project at ${PROJECT_DIR}...${CLR_RESET}"
if [ ! -d "$PROJECT_DIR" ]; then
	if [ -z "$REPO_URL" ]; then
		echo -e "${CLR_R}Project not found. Pass your git repo URL as an argument:${CLR_RESET}"
		echo -e "  ./setup_vm.sh git@github.com:user/inception.git"
		exit 1
	fi
	git clone "$REPO_URL" "$PROJECT_DIR"
else
	echo -e "${CLR_G}Project already exists, pulling latest...${CLR_RESET}"
	git -C "$PROJECT_DIR" pull
fi

# ── 5. Initialize project ───────────────────────────────────────────
echo -e "${CLR_Y}[5/5] Initializing project...${CLR_RESET}"
cd "$PROJECT_DIR"
make

# ── Done ─────────────────────────────────────────────────────────────
echo ""
echo -e "${CLR_G}========================================${CLR_RESET}"
echo -e "${CLR_G}  Setup complete!${CLR_RESET}"
echo -e "${CLR_G}========================================${CLR_RESET}"
echo ""
echo -e "  ${CLR_Y}1.${CLR_RESET} Edit secrets:    nano secrets/*.txt"
echo -e "  ${CLR_Y}2.${CLR_RESET} Edit env:        nano srcs/.env"
echo -e "  ${CLR_Y}3.${CLR_RESET} Log out & back in (for docker group), then:"
echo -e "     cd ${PROJECT_DIR} && make up"
echo ""
if [ -n "${HOSTONLY_IP:-}" ]; then
	echo -e "  ${CLR_Y}Windows hosts file:${CLR_RESET} ${HOSTONLY_IP}  ${DOMAIN_NAME}"
fi
