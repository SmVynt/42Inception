#!/bin/sh
set -eu

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

: "${ADMINER_PORT:=8080}"
DOCROOT="/var/www/adminer"

if [ ! -f "${DOCROOT}/index.php" ]; then
	echo "${CLR_R}Adminer not found at ${DOCROOT}/index.php${CLR_RESET}" >&2
	exit 1
fi

echo "${CLR_Y}Starting Adminer (PHP built-in server) on 0.0.0.0:${ADMINER_PORT}...${CLR_RESET}"

exec php -S "0.0.0.0:${ADMINER_PORT}" -t "$DOCROOT"
