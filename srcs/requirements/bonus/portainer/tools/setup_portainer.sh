#!/bin/sh
set -eu

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

: "${PORTAINER_PORT:=9443}"

echo "${CLR_G}Portainer configured. Starting...${CLR_RESET}"
exec /portainer/portainer \
	--data /data \
	--assets /portainer \
	--bind :9000 \
	--bind-https :${PORTAINER_PORT} \
	--no-analytics
