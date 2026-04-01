#!/bin/sh

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

if [ -z "$DOMAIN_NAME" ]; then
    echo "DOMAIN_NAME is required" >&2
    exit 1
fi

# Let's check if the certificate and key files exist / have been created previously
CERT="/etc/ssl/certs/nginx-selfsigned.crt"
KEY="/etc/ssl/private/nginx-selfsigned.key"

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
	echo "${CLR_Y}Generating self-signed certificate...${CLR_RESET}"
	openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
		-keyout "$KEY" -out "$CERT" \
		-subj "/CN=${DOMAIN_NAME}"
	echo "${CLR_G}Self-signed certificate generated successfully...${CLR_RESET}"
fi

# Now we substitute the DOMAIN_NAME in the default_with_env file and save it as default
envsubst '$DOMAIN_NAME' < /etc/nginx/sites-available/default_with_env > /etc/nginx/sites-available/default

echo "${CLR_G}Nginx is ready, starting...${CLR_RESET}"
exec nginx -g "daemon off;"